import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/in_app_announcement_dialog.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../models/address.dart';
import '../../../models/delivery.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../models/store_settings.dart';
import '../../../providers/app_providers.dart';
import '../../prescriptions/screens/prescriptions_screen.dart'
    show prescriptionsProvider;
import '../widgets/checkout_address_section.dart';
import '../widgets/checkout_payment_and_review.dart';
import 'cashfree_checkout_screen.dart';

export '../widgets/checkout_address_section.dart';
export '../widgets/checkout_payment_and_review.dart';

/// Checkout replica of the website's mobile checkout
/// (`src/app/checkout/page.tsx`): PopScope guard, step breadcrumb
/// (`1 Cart › 2 Delivery › 3 Confirmation`), collapsed address + change list,
/// Order review accordion/sheet with combo bundle grouping, auto delivery/COD
/// check per pincode, CASHFREE-default payment gating with network pills,
/// COD SMS confirmation banner, pre-order confirmation dialog (`paymentConfirm`),
/// coupon validation, KK Coins redeem (30% cap), Rx hold, delivery-aware
/// summary, NOT_DELIVERABLE waitlist, INVALID_PHONE inline error.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  bool _addressExpanded = false;
  bool _orderReviewExpanded = false;
  String _paymentMethod = 'CASHFREE';
  bool _submitting = false;
  bool _checkingDelivery = false;
  DeliveryInfo? _delivery;
  Timer? _deliveryDebounce;

  final _couponController = TextEditingController();
  bool _validatingCoupon = false;
  String? _couponError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = ref.read(cartProvider).value;
      if (cart != null && cart.isNotEmpty) {
        final total = cart.fold<double>(0, (sum, i) => sum + i.lineTotal);
        AnalyticsService.instance.logBeginCheckout(
          value: total,
          itemCount: cart.length,
        );
      }
      InAppAnnouncementCoordinator.checkAndShow(
        context,
        ref,
        currentRoute: '/checkout',
      );
    });
  }

  @override
  void dispose() {
    _deliveryDebounce?.cancel();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final settingsAsync = ref.watch(storeSettingsProvider);
    final combosAsync = ref.watch(homeCombosProvider);
    final combos = combosAsync.value ?? const <ComboBundle>[];
    final draft = ref.watch(checkoutDraftProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final cartCount = ref.watch(cartCountProvider);
    final fallbackPincode = ref.watch(deliveryPincodeProvider).valueOrNull;
    final fallbackDeliveryInfo = ref.watch(deliveryEtaProvider).valueOrNull;
    final settings = settingsAsync.valueOrNull;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: AppColors.homeCanvas,
        appBar: AppBar(
          toolbarHeight: 54,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/cart');
              }
            },
          ),
          title: Image.asset(
            'assets/images/logo.png',
            height: 32,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, _, _) => const Text(
              'KK NUTRIVET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ),
        body: cartAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return EmptyView(
                message: 'Your cart is empty',
                icon: Icons.shopping_cart_outlined,
                action: ElevatedButton(
                  onPressed: () => context.go('/products'),
                  child: const Text('Browse products'),
                ),
              );
            }
            final couponDiscount = draft.couponDiscount;
            final pointsDiscount = draft.pointsToRedeem.toDouble();
            final merchandise = (subtotal - couponDiscount - pointsDiscount)
                .clamp(0.0, double.infinity);
            final effectivePincode =
                _selectedAddress?.zipCode ?? _delivery?.pincode ?? fallbackPincode;
            final effectiveSource =
                _delivery?.source ?? fallbackDeliveryInfo?.source;
            final activeSettings = settings ?? StoreSettings.defaults();
            final freeDeliveryThreshold =
                activeSettings.effectiveFreeDeliveryThreshold(
                  pincode: effectivePincode,
                  source: effectiveSource,
                );
            final deliveryFee = activeSettings.calculateDeliveryFee(
              merchandise,
              pincode: effectivePincode,
              source: effectiveSource,
            );
            final isNotServiceable =
                _delivery != null && !_delivery!.serviceable;
            final total =
                (merchandise + deliveryFee).clamp(0.0, double.infinity);
            final codConfirmationEnabled =
                activeSettings.codConfirmationEnabled;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                const CheckoutStepHeader(),
                const SizedBox(height: 16),
                CheckoutOrderReviewSection(
                  items: items,
                  combos: combos,
                  cartCount: cartCount,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  expanded: _orderReviewExpanded,
                  onToggleExpanded: () => setState(
                    () => _orderReviewExpanded = !_orderReviewExpanded,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Delivery address',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                CheckoutAddressSection(
                  addressesAsync: addressesAsync,
                  selectedAddressId: _selectedAddressId,
                  addressExpanded: _addressExpanded,
                  onSelectAddress: (addr) {
                    setState(() => _selectedAddressId = addr.id);
                    _scheduleDeliveryCheck(addr.zipCode);
                  },
                  onToggleExpanded: () => setState(
                    () => _addressExpanded = !_addressExpanded,
                  ),
                  onDefaultAddressResolved: (defaultAddr) {
                    if (!mounted) return;
                    if (_selectedAddressId == null) {
                      setState(() => _selectedAddressId = defaultAddr.id);
                    }
                    if (_delivery == null && !_checkingDelivery) {
                      _scheduleDeliveryCheck(defaultAddr.zipCode);
                    }
                  },
                ),
                const SizedBox(height: 8),
                CheckoutDeliveryStatusRow(
                  checkingDelivery: _checkingDelivery,
                  delivery: _delivery,
                  onOpenWaitlist: (pincode) =>
                      showCheckoutWaitlistSheet(context, pincode),
                ),
                const Divider(height: 32),
                CheckoutRxHoldCard(items: items),
                const Text(
                  'Coupon code',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                CheckoutCouponSection(
                  subtotal: subtotal,
                  controller: _couponController,
                  validating: _validatingCoupon,
                  error: _couponError,
                  onValidate: () => _validateCoupon(subtotal),
                ),
                const Divider(height: 32),
                CheckoutPointsEditor(subtotal: subtotal),
                const Divider(height: 32),
                const Text(
                  'Payment method',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 8),
                CheckoutPaymentSection(
                  paymentMethod: _paymentMethod,
                  delivery: _delivery,
                  codConfirmationEnabled: codConfirmationEnabled,
                  total: total.toDouble(),
                  onPaymentMethodChanged: (val) =>
                      setState(() => _paymentMethod = val),
                ),
                const Divider(height: 32),
                CheckoutSummaryCard(
                  subtotal: subtotal,
                  couponCode: draft.couponCode,
                  couponDiscount: couponDiscount,
                  points: draft.pointsToRedeem,
                  deliveryFee: deliveryFee,
                  freeDeliveryThreshold: freeDeliveryThreshold,
                  isNotServiceable: isNotServiceable,
                  total: total.toDouble(),
                ),
                if (_phoneError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _phoneError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            );
          },
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(cartProvider),
          ),
        ),
        bottomNavigationBar: cartAsync.maybeWhen(
          data: (items) {
            if (items.isEmpty) return null;
            final settings = ref.watch(storeSettingsProvider).valueOrNull ??
                StoreSettings.defaults();
            final couponDiscount = draft.couponDiscount;
            final pointsDiscount = draft.pointsToRedeem.toDouble();
            final merchandise = (subtotal - couponDiscount - pointsDiscount)
                .clamp(0.0, double.infinity);
            final effectivePincode =
                _selectedAddress?.zipCode ?? _delivery?.pincode ?? fallbackPincode;
            final effectiveSource =
                _delivery?.source ?? fallbackDeliveryInfo?.source;
            final deliveryFee = settings.calculateDeliveryFee(
              merchandise,
              pincode: effectivePincode,
              source: effectiveSource,
            );
            final total = (merchandise + deliveryFee).toDouble();
            final quote = settings.partialCodQuote(total);

            return CheckoutStickyPlaceOrderBar(
              canPlace: _canPlace(),
              submitting: _submitting,
              paymentMethod: _paymentMethod,
              total: total,
              advanceAmount: quote.advance,
              onPlaceOrder: () => _confirmAndPlaceOrder(
                cartCount: cartCount,
                total: total,
              ),
            );
          },
          orElse: () => null,
        ),
      ),
    );
  }

  Address? get _selectedAddress {
    final addresses = ref.read(addressesProvider).value;
    if (addresses == null || addresses.isEmpty) return null;
    return addresses
            .where((a) => a.id == _selectedAddressId)
            .firstOrNull ??
        addresses.where((a) => a.isDefault).firstOrNull ??
        addresses.first;
  }

  // ── Delivery check ───────────────────────────────────────────────────────
  void _scheduleDeliveryCheck(String zip) {
    _deliveryDebounce?.cancel();
    ref.read(deliveryPincodeProvider.notifier).setPincode(zip);
    if (!RegExp(r'^\d{6}$').hasMatch(zip)) {
      setState(() => _delivery = null);
      return;
    }
    setState(() {
      _checkingDelivery = true;
      _phoneError = null;
    });
    _deliveryDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final info =
            await ref.read(deliveryServiceProvider).checkPincode(zip);
        if (!mounted) return;
        final availability =
            ref.read(paymentAvailabilityStatusProvider).value ??
                const PaymentAvailabilityStatus();
        final settings = ref.read(storeSettingsProvider).valueOrNull;
        final codAllowed = availability.codEnabled &&
            availability.userCodAllowed &&
            (settings?.codEnabled ?? true);
        final onlineAllowed = availability.onlineEnabled &&
            (settings?.onlinePaymentsEnabled ?? true);
        final partialCodConfigured =
            (settings?.partialCodEnabled ?? false) ||
                availability.partialCodEnabled;
        final partialCodAvailable = partialCodConfigured &&
            onlineAllowed &&
            info.prepaid &&
            info.cod &&
            availability.userCodAllowed;

        setState(() {
          _delivery = info;
          if (info.serviceable) {
            if (_paymentMethod == 'PARTIAL_COD' && !partialCodAvailable) {
              _paymentMethod = onlineAllowed
                  ? 'CASHFREE'
                  : (codAllowed && info.cod ? 'COD' : 'CASHFREE');
            } else if (_paymentMethod == 'CASHFREE' &&
                !onlineAllowed &&
                partialCodAvailable) {
              _paymentMethod = 'PARTIAL_COD';
            } else if (_paymentMethod == 'CASHFREE' &&
                !onlineAllowed &&
                codAllowed &&
                info.cod) {
              _paymentMethod = 'COD';
            } else if (_paymentMethod == 'COD' &&
                (!codAllowed || !info.cod)) {
              _paymentMethod = partialCodAvailable
                  ? 'PARTIAL_COD'
                  : (onlineAllowed ? 'CASHFREE' : 'COD');
            } else if (!info.prepaid && info.cod && codAllowed) {
              _paymentMethod = 'COD';
            }
          }
        });
      } catch (_) {
        if (mounted) setState(() => _delivery = null);
      } finally {
        if (mounted) setState(() => _checkingDelivery = false);
      }
    });
  }

  // ── Coupon validation ────────────────────────────────────────────────────
  Future<void> _validateCoupon(double subtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _validatingCoupon = true;
      _couponError = null;
    });
    try {
      final result = await ref
          .read(orderServiceProvider)
          .validateCoupon(code, subtotal);
      final discount = (result['discount'] as num?)?.toDouble() ?? 0;
      final coupon = result['coupon'];
      final appliedCode =
          coupon is Map ? coupon['code']?.toString() ?? code : code;
      if (!mounted) return;
      ref.read(checkoutDraftProvider.notifier).state =
          ref.read(checkoutDraftProvider).copyWith(
                couponCode: appliedCode,
                couponDiscount: discount,
              );
      showToast('Coupon applied — you save ₹${formatInr(discount)}');
    } catch (e) {
      if (mounted) setState(() => _couponError = e.toString());
    } finally {
      if (mounted) setState(() => _validatingCoupon = false);
    }
  }

  // ── Pre-Order Confirmation & Place Order ─────────────────────────────────
  bool get _rxBlocked {
    final items = ref.read(cartProvider).value ?? [];
    final hasRx = items.any((i) => i.product?.requiresPrescription == true);
    if (!hasRx) return false;
    final rx = ref.read(prescriptionsProvider).value;
    if (rx == null || rx.isEmpty) return true;
    return rx.first.status.toUpperCase() != 'APPROVED';
  }

  bool _canPlace() {
    if (_submitting || _checkingDelivery) return false;
    if (_selectedAddress == null) return false;
    if (_rxBlocked) return false;
    final info = _delivery;
    if (info != null && !info.serviceable) return false;
    final availability = ref.read(paymentAvailabilityStatusProvider).value ??
        const PaymentAvailabilityStatus();
    final settings =
        ref.read(storeSettingsProvider).valueOrNull ?? StoreSettings.defaults();
    final onlineEnabled =
        availability.onlineEnabled && settings.onlinePaymentsEnabled;
    final codAllowed = availability.codEnabled &&
        availability.userCodAllowed &&
        settings.codEnabled;
    final partialCodConfigured =
        settings.partialCodEnabled || availability.partialCodEnabled;
    final partialCodAvailable = partialCodConfigured &&
        onlineEnabled &&
        (info == null || (info.prepaid && info.cod)) &&
        availability.userCodAllowed;

    if (_paymentMethod == 'CASHFREE' && !onlineEnabled) return false;
    if (_paymentMethod == 'PARTIAL_COD' && !partialCodAvailable) return false;
    if (_paymentMethod == 'COD' && (!codAllowed || (info != null && !info.cod))) {
      return false;
    }
    return true;
  }

  Future<void> _confirmAndPlaceOrder({
    required int cartCount,
    required double total,
  }) async {
    final address = _selectedAddress;
    if (address == null) return;
    final digits = address.phone.replaceAll(RegExp(r'\D'), '');
    final phone = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;
    if (phone.length != 10) {
      setState(
        () => _phoneError =
            'Enter a 10-digit Indian mobile number. Used for delivery updates and calls.',
      );
      showToast('Invalid delivery phone number', isError: true);
      return;
    }

    final settings =
        ref.read(storeSettingsProvider).valueOrNull ?? StoreSettings.defaults();
    final quote = settings.partialCodQuote(total);

    final confirmed = await showCheckoutConfirmOrderDialog(
      context: context,
      isCod: _paymentMethod == 'COD',
      isPartialCod: _paymentMethod == 'PARTIAL_COD',
      partialAdvance: quote.advance,
      partialBalance: quote.balance,
      cartCount: cartCount,
      total: total,
      address: address,
      onChangeAddress: () => setState(() => _addressExpanded = true),
    );

    if (confirmed == true && mounted) {
      await _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    final address = _selectedAddress;
    if (address == null) return;
    final digits = address.phone.replaceAll(RegExp(r'\D'), '');
    final phone = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;
    if (phone.length != 10) {
      setState(
        () => _phoneError =
            'Enter a 10-digit Indian mobile number. Used for delivery updates and calls.',
      );
      showToast('Invalid delivery phone number', isError: true);
      return;
    }
    final cartItems = ref.read(cartProvider).value ?? [];
    if (cartItems.isEmpty) {
      showToast('Your cart is empty', isError: true);
      return;
    }

    setState(() {
      _submitting = true;
      _phoneError = null;
    });
    try {
      final draft = ref.read(checkoutDraftProvider);
      String? prescriptionId;
      try {
        final rx = await ref.read(prescriptionsProvider.future);
        prescriptionId = rx
            .where((p) => p.status.toUpperCase() == 'APPROVED')
            .firstOrNull
            ?.id;
      } catch (_) {}
      final itemsPayload = cartItems
          .map((item) => {
                'productId': item.productId,
                'variantId': ?item.variantId,
                'quantity': item.quantity,
                'comboId': ?item.comboId,
                'comboPrice': ?item.comboPrice,
              })
          .toList();
      final order = await ref.read(orderServiceProvider).placeOrder(
            recipientName: address.fullName,
            shippingAddress:
                '${address.formattedAddress}, ${address.city}, ${address.state} - ${address.zipCode}',
            phone: phone,
            pincode: address.zipCode,
            couponCode: draft.couponCode,
            prescriptionId: prescriptionId,
            pointsToRedeem: draft.pointsToRedeem,
            paymentMethod: _paymentMethod,
            items: itemsPayload,
          );
      AnalyticsService.instance.logPurchase(
        orderId: order.id,
        value: order.totalAmount,
        shipping: order.deliveryCharge,
        coupon: draft.couponCode,
      );

      if (draft.pointsToRedeem > 0) {
        try {
          await ref
              .read(referralServiceProvider)
              .redeemPoints(draft.pointsToRedeem);
        } catch (_) {}
      }
      ref.read(checkoutDraftProvider.notifier).state = const CheckoutDraft();
      ref.read(cartProvider.notifier).clearGuestCart();
      await ref.read(cartProvider.notifier).refresh();

      if (_paymentMethod == 'CASHFREE' || _paymentMethod == 'PARTIAL_COD') {
        await _payOnline(order);
      } else if (mounted) {
        await showCheckoutOrderSuccessSheet(context, order);
        if (mounted) context.go('/orders');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'NOT_DELIVERABLE') {
        showCheckoutWaitlistSheet(context, address.zipCode);
      } else if (e.code == 'INVALID_PHONE') {
        setState(() => _phoneError = e.message);
      } else {
        showToast(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _payOnline(Order order) async {
    final session =
        await ref.read(orderServiceProvider).createCashfreeOrder(order.id);
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
      showToast('Payment not completed. You can retry from your order.');
      context.go('/order/${order.id}');
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
      // Short delay & retry in case gateway webhook / callback reconciliation is slightly delayed
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      try {
        result = await ref
            .read(orderServiceProvider)
            .verifyCashfreePayment(merchantOrderId);
      } catch (_) {}
    }
    if (!mounted) return;

    if (isPaymentConfirmed(result)) {
      await ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      await showCheckoutOrderSuccessSheet(context, order);
      if (mounted) context.go('/order/${order.id}');
    } else {
      showToast(
        'We could not confirm your payment yet. Check your order for the latest status.',
        isError: true,
      );
      context.go('/order/${order.id}');
    }
  }
}
