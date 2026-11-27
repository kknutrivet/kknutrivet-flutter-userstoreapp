import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/compact_product_card.dart' show formatInr;
import '../../../models/address.dart';
import '../../../models/order.dart';
import '../../../models/store_settings.dart';
import '../../../providers/app_providers.dart';
import '../../checkout/screens/cashfree_checkout_screen.dart';
import '../../checkout/widgets/checkout_address_section.dart';
import '../../checkout/widgets/checkout_payment_and_review.dart'
    show PaymentAvailabilityStatus, paymentAvailabilityStatusProvider;
import '../screens/orders_screen.dart' show ordersProvider;

/// Opens the 1-tap Express Reorder bottom sheet for a past [order].
/// Lets the customer confirm items/quantities, address, and payment method
/// and proceed straight to Cashfree payment or Order Confirmation without
/// going through Cart → Checkout, while still offering "Add to Cart instead".
Future<void> showExpressReorderSheet(BuildContext context, Order order) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExpressReorderSheet(order: order),
  );
}

class _ReorderDraftItem {
  _ReorderDraftItem({
    required this.orderItem,
    required this.quantity,
  });

  final OrderItem orderItem;
  int quantity;

  String get productId => orderItem.product?.id ?? orderItem.id;
  String? get variantId => orderItem.variant?.id;
  String get name => orderItem.product?.name ?? 'Product';
  String? get image => orderItem.product?.image;
  String? get variantName => orderItem.variant?.name;
  double get unitPrice =>
      orderItem.variant?.price ?? orderItem.product?.price ?? orderItem.price;
  double get lineTotal => unitPrice * quantity;
}

class _ExpressReorderSheet extends ConsumerStatefulWidget {
  const _ExpressReorderSheet({required this.order});
  final Order order;

  @override
  ConsumerState<_ExpressReorderSheet> createState() =>
      _ExpressReorderSheetState();
}

class _ExpressReorderSheetState extends ConsumerState<_ExpressReorderSheet> {
  late final List<_ReorderDraftItem> _items;
  final ScrollController _itemsScroll = ScrollController();

  String? _selectedAddressId;
  String _paymentMethod = 'CASHFREE';
  bool _submitting = false;
  bool _addingToCart = false;
  String? _pendingOnlineOrderId;

  @override
  void initState() {
    super.initState();
    _items = [
      for (final item in widget.order.items)
        if (item.product != null)
          _ReorderDraftItem(
            orderItem: item,
            quantity: item.quantity > 0 ? item.quantity : 1,
          ),
    ];
    final prevMethod = widget.order.paymentMethod?.toUpperCase();
    if (widget.order.partialCod || prevMethod == 'PARTIAL_COD') {
      _paymentMethod = 'PARTIAL_COD';
    } else if (prevMethod == 'COD') {
      _paymentMethod = 'COD';
    } else {
      _paymentMethod = 'CASHFREE';
    }
  }

  @override
  void dispose() {
    _itemsScroll.dispose();
    super.dispose();
  }

  String? _extractPincode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'\b(\d{6})\b').firstMatch(raw);
    return match?.group(1);
  }

  Address? _resolveAddress(List<Address> addresses) {
    if (addresses.isEmpty) return null;
    if (_selectedAddressId != null) {
      final hit = addresses.where((a) => a.id == _selectedAddressId).firstOrNull;
      if (hit != null) return hit;
    }
    final globalSelected = ref.read(selectedDeliveryAddressIdProvider);
    if (globalSelected != null) {
      final hit = addresses.where((a) => a.id == globalSelected).firstOrNull;
      if (hit != null) return hit;
    }
    final orderPin = _extractPincode(widget.order.shippingAddress);
    if (orderPin != null) {
      final hit = addresses.where((a) => a.zipCode.trim() == orderPin).firstOrNull;
      if (hit != null) return hit;
    }
    return addresses.where((a) => a.isDefault).firstOrNull ?? addresses.first;
  }

  Future<void> _abandonPendingOrderIfAny() async {
    final pendingId = _pendingOnlineOrderId;
    if (pendingId == null) return;
    _pendingOnlineOrderId = null;
    try {
      await ref.read(orderServiceProvider).abandonPendingOrder(pendingId);
    } catch (_) {}
  }

  Future<void> _addToCartInstead() async {
    if (_addingToCart || _submitting || _items.isEmpty) return;
    AppHaptics.tap();
    setState(() => _addingToCart = true);
    try {
      final batch = [
        for (final item in _items)
          (
            productId: item.productId,
            variantId: item.variantId,
            quantity: item.quantity,
            product: item.orderItem.product,
            variant: item.orderItem.variant,
          ),
      ];
      final result = await ref.read(cartProvider.notifier).addItemsBatch(batch);
      if (!mounted) return;
      if (result.added > 0) {
        final msg = result.failed > 0
            ? 'Added ${result.added} of ${batch.length} items to cart'
            : 'Added ${result.added} ${result.added == 1 ? 'item' : 'items'} to cart';
        Navigator.of(context).pop();
        showToast(msg);
        context.push('/cart');
      } else {
        showToast(
          'Items from this order are currently unavailable',
          type: AppToastType.warning,
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(
          e.toString().replaceFirst(RegExp(r'^Exception: '), ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Future<void> _placeExpressOrder(
    Address? selectedAddress,
    String effectiveMethod,
  ) async {
    if (_submitting || _addingToCart || _items.isEmpty) return;

    final user = ref.read(authProvider).valueOrNull;
    final recipientName =
        selectedAddress?.fullName.trim().isNotEmpty == true
        ? selectedAddress!.fullName.trim()
        : (widget.order.recipientName?.trim().isNotEmpty == true
              ? widget.order.recipientName!.trim()
              : ((user?.name ?? '').trim().isNotEmpty
                    ? user!.name!.trim()
                    : 'Customer'));

    final shippingAddress = selectedAddress != null
        ? '${selectedAddress.formattedAddress}, ${selectedAddress.city}, ${selectedAddress.state} - ${selectedAddress.zipCode}'
        : (widget.order.shippingAddress?.trim() ?? '');

    final rawPhone = selectedAddress?.phone ?? widget.order.phone ?? user?.phone ?? '';
    final phone = normalizeIndianPhone(rawPhone);
    final pincode =
        selectedAddress?.zipCode.trim() ?? _extractPincode(shippingAddress);

    if (shippingAddress.isEmpty || pincode == null || pincode.length != 6) {
      showToast('Please select a valid delivery address', isError: true);
      return;
    }
    if (phone.length != 10) {
      showToast('Please select an address with a valid 10-digit mobile number', isError: true);
      return;
    }

    AppHaptics.tap();
    setState(() => _submitting = true);
    String? createdOrderId;
    try {
      final itemsPayload = _items
          .map(
            (item) => {
              'productId': item.productId,
              if (item.variantId != null) 'variantId': item.variantId,
              'quantity': item.quantity,
              if (item.orderItem.comboId != null)
                'comboId': item.orderItem.comboId,
              if (item.orderItem.comboPrice != null)
                'comboPrice': item.orderItem.comboPrice,
            },
          )
          .toList();

      await _abandonPendingOrderIfAny();
      final isOnline = effectiveMethod != 'COD';
      final apiPaymentMethod =
          (effectiveMethod == 'PAY_LATER' || effectiveMethod == 'EMI')
          ? 'CASHFREE'
          : effectiveMethod;
      final paymentPreference =
          (effectiveMethod == 'PAY_LATER' || effectiveMethod == 'EMI')
          ? effectiveMethod
          : null;

      final order = await ref
          .read(orderServiceProvider)
          .placeOrder(
            recipientName: recipientName,
            shippingAddress: shippingAddress,
            phone: phone,
            pincode: pincode,
            paymentMethod: apiPaymentMethod,
            items: itemsPayload,
          );
      createdOrderId = order.id;

      if (isOnline) {
        _pendingOnlineOrderId = order.id;
        await _payOnline(order, paymentPreference: paymentPreference);
      } else {
        AnalyticsService.instance.logPurchase(
          paymentMethod: 'COD',
          orderId: order.id,
          value: order.totalAmount,
          shipping: order.deliveryCharge,
        );
        ref.invalidate(ordersProvider);
        await ref.read(cartProvider.notifier).refresh();
        if (!mounted) return;
        Navigator.of(context).pop();
        showToast('Order placed successfully!');
        context.go('/orders/${order.id}/confirmation');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (createdOrderId != null) {
        Navigator.of(context).pop();
        showToast(
          'Your order is saved. Check payment status or retry from order details.',
        );
        context.go('/order/$createdOrderId');
      } else {
        showToast(e.message, isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      if (createdOrderId != null) {
        Navigator.of(context).pop();
        showToast(
          'Your order is saved. Check payment status or retry from order details.',
        );
        context.go('/order/$createdOrderId');
      } else {
        showToast('Could not place your order. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _payOnline(Order order, {String? paymentPreference}) async {
    final session = await ref
        .read(orderServiceProvider)
        .createCashfreeOrder(order.id, paymentPreference: paymentPreference);
    if (!mounted) return;

    final returnedFromPayment = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CashfreeCheckoutScreen(
          paymentSessionId: session['paymentSessionId'] as String,
          orderId: order.id,
          mode: session['mode'] as String? ?? 'production',
        ),
      ),
    );
    if (!mounted) return;

    if (returnedFromPayment != true) {
      await _abandonPendingOrderIfAny();
      if (!mounted) return;
      showToast('Payment cancelled. You can try again anytime.');
      return;
    }

    final merchantOrderId = (session['orderId'] as String?)?.isNotEmpty == true
        ? session['orderId'] as String
        : (order.cashfreeMerchantOrderId?.isNotEmpty == true
              ? order.cashfreeMerchantOrderId!
              : order.orderNumber);

    bool isPaymentConfirmed(Map<String, dynamic> res) =>
        res['paid'] == true ||
        res['confirmed'] == true ||
        res['status'] == 'PAID' ||
        res['status'] == 'ADVANCE_PAID' ||
        res['status'] == 'SUCCESS';

    var result = await ref
        .read(orderServiceProvider)
        .verifyCashfreePayment(merchantOrderId);

    if (!isPaymentConfirmed(result)) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      try {
        result = await ref
            .read(orderServiceProvider)
            .verifyCashfreePayment(merchantOrderId);
      } catch (_) {}
    }
    if (!mounted) return;

    _pendingOnlineOrderId = null;
    if (isPaymentConfirmed(result)) {
      AnalyticsService.instance.logPurchase(
        orderId: order.id,
        value: (order.paymentMethod == 'PARTIAL_COD')
            ? (order.advanceAmount ?? 0)
            : order.totalAmount,
        paymentMethod: (order.paymentMethod == 'PARTIAL_COD')
            ? 'advance'
            : 'prepaid',
      );
      ref.invalidate(ordersProvider);
      await ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast('Payment successful! Order confirmed.');
      context.go('/orders/${order.id}/confirmation');
    } else {
      Navigator.of(context).pop();
      showToast(
        'We could not confirm your payment yet. Check your order for the latest status.',
        isError: true,
      );
      context.go('/order/${order.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses =
        ref.watch(addressesProvider).valueOrNull ?? const <Address>[];
    final selectedAddress = _resolveAddress(addresses);
    final settings =
        ref.watch(storeSettingsProvider).valueOrNull ??
        StoreSettings.defaults();
    final availability =
        ref.watch(paymentAvailabilityStatusProvider).valueOrNull ??
        const PaymentAvailabilityStatus();

    final subtotal = _items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final freeThreshold = settings.freeDeliveryThreshold;
    final baseDelivery =
        settings.courierDeliveryCharge ?? settings.deliveryCharge;
    final deliveryFee = subtotal >= freeThreshold ? 0.0 : baseDelivery;
    final baseTotal = subtotal + deliveryFee;
    final codOverCap = settings.exceedsCodMaxOrderAmount(
      baseTotal,
      overrideMax: availability.codMaxOrderAmount,
    );

    final codAllowed =
        availability.codEnabled &&
        availability.userCodAllowed &&
        settings.codEnabled &&
        !codOverCap;
    final onlineAllowed =
        availability.onlineEnabled && settings.onlinePaymentsEnabled;
    final partialCodConfigured =
        settings.partialCodEnabled || availability.partialCodEnabled;
    final partialCodAvailable =
        partialCodConfigured &&
        onlineAllowed &&
        availability.userCodAllowed;
    final payLaterAvailable = settings.payLaterEnabled && onlineAllowed;

    String effectiveMethod = _paymentMethod;
    if (codOverCap && partialCodAvailable && effectiveMethod == 'COD') {
      effectiveMethod = 'PARTIAL_COD';
    } else if (effectiveMethod == 'PARTIAL_COD' && !partialCodAvailable) {
      effectiveMethod = onlineAllowed ? 'CASHFREE' : (codAllowed ? 'COD' : 'CASHFREE');
    } else if ((effectiveMethod == 'PAY_LATER' || effectiveMethod == 'EMI') &&
        !payLaterAvailable) {
      effectiveMethod = onlineAllowed ? 'CASHFREE' : (codAllowed ? 'COD' : 'CASHFREE');
    } else if (effectiveMethod == 'COD' && !codAllowed) {
      effectiveMethod = partialCodAvailable
          ? 'PARTIAL_COD'
          : (onlineAllowed ? 'CASHFREE' : 'COD');
    } else if (effectiveMethod == 'CASHFREE' && !onlineAllowed) {
      effectiveMethod = partialCodAvailable
          ? 'PARTIAL_COD'
          : (codAllowed ? 'COD' : 'CASHFREE');
    }

    final codFee = (effectiveMethod == 'COD')
        ? settings.courierCodFlatFee
        : 0.0;
    final estimatedTotal = baseTotal + codFee;
    final partialQuote = settings.partialCodQuote(baseTotal);

    final displayName = selectedAddress?.fullName ??
        widget.order.recipientName ??
        'Delivery address';
    final displayAddress = selectedAddress != null
        ? '${selectedAddress.formattedAddress}, ${selectedAddress.city} - ${selectedAddress.zipCode}'
        : (widget.order.shippingAddress ?? 'No saved address');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2DED8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF5EF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 22,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Express Reorder',
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: Color(0xFF102A23),
                            ),
                          ),
                          Text(
                            'From #${widget.order.orderNumber} · ${_items.length} ${_items.length == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5B7268),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: const Color(0xFFF3F8F5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF4A6359),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEDF3EF)),

          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'All items removed from this reorder.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Editable Items list
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 205),
                      child: Scrollbar(
                        controller: _itemsScroll,
                        thumbVisibility: _items.length > 2,
                        radius: const Radius.circular(4),
                        thickness: 4,
                        child: ListView.separated(
                          controller: _itemsScroll,
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(right: 4),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final item = _items[index];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FCFA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE3ECE7),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AppNetworkImage(
                                      imageUrl: item.image ?? '',
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF102A23),
                                          ),
                                        ),
                                        if (item.variantName != null &&
                                            item.variantName!.isNotEmpty)
                                          Text(
                                            item.variantName!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF5B7268),
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${formatInr(item.lineTotal)}',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryDeep,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Compact stepper
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFD2E2DA),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                left: Radius.circular(9),
                                              ),
                                          onTap: _submitting
                                              ? null
                                              : () {
                                                  AppHaptics.selection();
                                                  setState(() {
                                                    if (item.quantity <= 1) {
                                                      _items.removeAt(index);
                                                    } else {
                                                      item.quantity--;
                                                    }
                                                  });
                                                },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            child: Icon(
                                              item.quantity <= 1
                                                  ? Icons.delete_outline_rounded
                                                  : Icons.remove_rounded,
                                              size: 15,
                                              color: item.quantity <= 1
                                                  ? AppColors.error
                                                  : AppColors.primaryDeep,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF102A23),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius:
                                              const BorderRadius.horizontal(
                                                right: Radius.circular(9),
                                              ),
                                          onTap: _submitting
                                              ? null
                                              : () {
                                                  AppHaptics.selection();
                                                  setState(
                                                    () => item.quantity++,
                                                  );
                                                },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 15,
                                              color: AppColors.primaryDeep,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Delivery Address card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4FAF6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD6E8DE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 19,
                            color: AppColors.primaryDeep,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivering to $displayName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF102A23),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.3,
                                    color: Color(0xFF5B7268),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDeep,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _submitting
                                ? null
                                : () async {
                                    if (addresses.length > 1) {
                                      showCheckoutAddressPickerSheet(
                                        context: context,
                                        ref: ref,
                                        addresses: addresses,
                                        selectedAddressId: selectedAddress?.id,
                                        onSelectAddress: (addr) {
                                          setState(
                                            () => _selectedAddressId = addr.id,
                                          );
                                        },
                                      );
                                    } else {
                                      final added = await context
                                          .push<Address?>('/addresses/new');
                                      ref.invalidate(addressesProvider);
                                      if (added != null && mounted) {
                                        setState(
                                          () => _selectedAddressId = added.id,
                                        );
                                      }
                                    }
                                  },
                            child: Text(
                              addresses.length > 1 ? 'Change' : 'Add',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment selector (mirrors CheckoutPaymentSection from StoreSettings)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (onlineAllowed)
                          _PaymentChip(
                            label: 'Pay Online',
                            subtitle: 'UPI · Cards · NetBanking · ₹0 COD Fee',
                            icon: Icons.account_balance_wallet_outlined,
                            selected: effectiveMethod == 'CASHFREE',
                            onTap: _submitting
                                ? null
                                : () => setState(
                                      () => _paymentMethod = 'CASHFREE',
                                    ),
                          ),
                        if (partialCodAvailable) ...[
                          const SizedBox(height: 8),
                          _PaymentChip(
                            label:
                                'Pay ₹${formatInr(partialQuote.advance)} Advance (Partial COD)',
                            subtitle:
                                '₹${formatInr(partialQuote.balance)} on delivery · ₹0 COD Fee',
                            badge: '₹0 COD Fee',
                            icon: Icons.splitscreen_outlined,
                            selected: effectiveMethod == 'PARTIAL_COD',
                            onTap: _submitting
                                ? null
                                : () => setState(
                                      () => _paymentMethod = 'PARTIAL_COD',
                                    ),
                          ),
                        ],
                        if (payLaterAvailable) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _PaymentChip(
                                  label: 'Pay Later',
                                  subtitle: 'Simpl · LazyPay',
                                  icon: Icons.schedule_rounded,
                                  selected: effectiveMethod == 'PAY_LATER',
                                  onTap: _submitting
                                      ? null
                                      : () => setState(
                                            () => _paymentMethod = 'PAY_LATER',
                                          ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _PaymentChip(
                                  label: 'EMI',
                                  subtitle: 'Cardless · Card EMI',
                                  icon: Icons.credit_score_outlined,
                                  selected: effectiveMethod == 'EMI',
                                  onTap: _submitting
                                      ? null
                                      : () => setState(
                                            () => _paymentMethod = 'EMI',
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (codAllowed) ...[
                          const SizedBox(height: 8),
                          _PaymentChip(
                            label: 'Cash on Delivery',
                            subtitle: settings.courierCodFlatFee > 0
                                ? '+₹${formatInr(settings.courierCodFlatFee)} COD handling fee'
                                : 'Pay cash on delivery · No extra COD fee',
                            icon: Icons.payments_outlined,
                            selected: effectiveMethod == 'COD',
                            onTap: _submitting
                                ? null
                                : () => setState(() => _paymentMethod = 'COD'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Sticky CTA footer
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEDF3EF))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              effectiveMethod == 'PARTIAL_COD'
                                  ? '₹${formatInr(partialQuote.advance)} now · ₹${formatInr(partialQuote.balance)} COD'
                                  : deliveryFee <= 0
                                      ? 'Total · FREE delivery'
                                      : 'Total (incl. ₹${formatInr(deliveryFee)} delivery)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5B7268),
                              ),
                            ),
                            Text(
                              '₹${formatInr(estimatedTotal)}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF102A23),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: FilledButton(
                              onPressed: (_items.isEmpty ||
                                      _submitting ||
                                      _addingToCart)
                                  ? null
                                  : () => _placeExpressOrder(
                                        selectedAddress,
                                        effectiveMethod,
                                      ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryDeep,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      effectiveMethod == 'COD'
                                          ? 'Place Order · ₹${formatInr(estimatedTotal)}'
                                          : effectiveMethod == 'PARTIAL_COD'
                                              ? 'Pay ₹${formatInr(partialQuote.advance)} advance →'
                                              : effectiveMethod == 'PAY_LATER'
                                                  ? 'Pay Later · ₹${formatInr(estimatedTotal)} →'
                                                  : effectiveMethod == 'EMI'
                                                      ? 'Pay via EMI · ₹${formatInr(estimatedTotal)} →'
                                                      : 'Pay ₹${formatInr(estimatedTotal)} →',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: (_submitting || _addingToCart)
                            ? null
                            : _addToCartInstead,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: _addingToCart
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryDeep,
                                  ),
                                )
                              : const Text(
                                  'Have a coupon or KK Coins? Add to Cart instead',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDeep,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primaryDeep,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF1F8F4) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primaryDeep
                  : const Color(0xFFDCE6E0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.primaryDeep
                    : const Color(0xFF5B7268),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: const Color(0xFF102A23),
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F4EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5B7268),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
