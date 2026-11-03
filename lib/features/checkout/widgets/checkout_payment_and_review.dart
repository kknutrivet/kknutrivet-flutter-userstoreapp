import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/checkout_breadcrumb.dart';
import '../../../core/widgets/combo_details_sheet.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../models/address.dart';
import '../../../models/cart_item.dart';
import '../../../models/coupon.dart';
import '../../../models/delivery.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../models/store_settings.dart';
import '../../../providers/app_providers.dart';
import '../../cart/widgets/cart_coupons_and_coins.dart'
    show UpperCaseTextFormatter, showCouponOffersSheet;
import '../../prescriptions/screens/prescriptions_screen.dart'
    show prescriptionsProvider;
import '../../referral/screens/referral_screen.dart'
    show referralSummaryProvider;

class PaymentAvailabilityStatus {
  const PaymentAvailabilityStatus({
    this.onlineEnabled = true,
    this.codEnabled = false,
    this.userCodAllowed = true,
    this.partialCodEnabled = false,
    this.codDisabledReason,
    this.userCodDisabledReason,
    this.isTrustedCustomer = false,
    this.deliveredOrdersCount = 0,
  });

  final bool onlineEnabled;
  final bool codEnabled;
  final bool userCodAllowed;
  final bool partialCodEnabled;
  final String? codDisabledReason;
  final String? userCodDisabledReason;
  final bool isTrustedCustomer;
  final int deliveredOrdersCount;
}

final paymentAvailabilityStatusProvider =
    FutureProvider.autoDispose<PaymentAvailabilityStatus>((ref) async {
      try {
        final result = await ref
            .read(orderServiceProvider)
            .cashfreeAvailability();
        final Map<String, dynamic> data = (result['data'] is Map)
            ? Map<String, dynamic>.from(result['data'] as Map)
            : result;
        return PaymentAvailabilityStatus(
          onlineEnabled: (data['enabled'] as bool?) ?? true,
          codEnabled: (data['codEnabled'] as bool?) ?? false,
          userCodAllowed: (data['userCodAllowed'] as bool?) ?? true,
          partialCodEnabled: (data['partialCodEnabled'] as bool?) ?? false,
          codDisabledReason: data['codDisabledReason'] as String?,
          userCodDisabledReason: data['userCodDisabledReason'] as String?,
          isTrustedCustomer: (data['isTrustedCustomer'] as bool?) ?? false,
          deliveredOrdersCount:
              (data['deliveredOrdersCount'] as num?)?.toInt() ?? 0,
        );
      } catch (_) {
        return const PaymentAvailabilityStatus();
      }
    });

final cashfreeAvailabilityProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final status = await ref.watch(paymentAvailabilityStatusProvider.future);
  return status.onlineEnabled;
});

/// Checkout step breadcrumb header (`1 Cart › 2 Delivery › 3 Confirmation`).
class CheckoutStepHeader extends StatelessWidget {
  const CheckoutStepHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [CheckoutBreadcrumb(currentStep: 1, lastLabel: 'Confirmation')],
    );
  }
}

/// Expandable Order Review section with combo bundle grouping.
class CheckoutOrderReviewSection extends StatelessWidget {
  const CheckoutOrderReviewSection({
    super.key,
    required this.items,
    required this.combos,
    required this.cartCount,
    required this.subtotal,
    this.deliveryFee = 0.0,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final List<CartItem> items;
  final List<ComboBundle> combos;
  final int cartCount;
  final double subtotal;
  final double deliveryFee;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  ComboBundle _resolveComboFromCart(
    String comboId,
    List<CartItem> bundleItems,
    List<ComboBundle> allCombos,
  ) {
    final matched = allCombos.where((c) => c.id == comboId).firstOrNull;
    if (matched != null) return matched;
    final first = bundleItems.first;
    final bundleQty = (first.comboQuantity ?? first.quantity).clamp(1, 999);
    final totalLine = bundleItems.fold<double>(0, (s, i) => s + i.lineTotal);
    final totalMrp = bundleItems.fold<double>(
      0,
      (s, i) =>
          s + ((i.variant?.mrp ?? i.product?.mrp ?? i.unitPrice) * i.quantity),
    );
    return ComboBundle(
      id: comboId,
      name: first.comboName ?? 'Care Combo Bundle',
      description: first.comboDescription,
      image: first.comboImage ?? first.product?.image,
      originalPrice: totalMrp > 0
          ? totalMrp / bundleQty
          : totalLine / bundleQty,
      comboPrice: totalLine / bundleQty,
      items: bundleItems
          .map(
            (i) => ComboItem(
              id: i.id,
              productId: i.productId,
              quantity: (i.quantity / bundleQty).round().clamp(1, 999),
              variantId: i.variantId,
              product: i.product,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seenCombos = <String>{};
    final groupedTiles = <Widget>[];

    for (final item in items) {
      final cid = item.comboId;
      if (cid != null && cid.isNotEmpty) {
        if (seenCombos.add(cid)) {
          final bundleRows = items.where((i) => i.comboId == cid).toList();
          final resolved = _resolveComboFromCart(cid, bundleRows, combos);
          final first = bundleRows.first;
          final cover =
              first.comboImage ?? resolved.image ?? first.product?.image;
          final name = first.comboName ?? resolved.name;
          final qty = (first.comboQuantity ?? first.quantity).clamp(1, 999);
          final totalLine = bundleRows.fold<double>(
            0,
            (sum, i) => sum + i.lineTotal,
          );

          groupedTiles.add(
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Material(
                color: AppColors.primaryWashFaint,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showComboDetailsSheet(context, resolved),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryWashDeep),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: cover != null && cover.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: cover,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppColors.primaryWash,
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Bundle · ${bundleRows.length} items · Qty $qty',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${formatInr(totalLine)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                            const Text(
                              'View items →',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        final image = item.product?.image;
        groupedTiles.add(
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: image != null && image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.background,
                              child: const Icon(Icons.pets, size: 20),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product?.name ?? 'Item',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.variant != null ? '${item.variant!.name} · ' : ''}Qty ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${formatInr(item.lineTotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryWashDeep),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggleExpanded,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryWash,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primaryDeep,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order review · $cartCount items · View items ›',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Subtotal ₹${formatInr(subtotal)} · Delivery ${deliveryFee <= 0 ? 'FREE' : '₹${formatInr(deliveryFee)}'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.primaryDeep,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(children: groupedTiles),
            ),
        ],
      ),
    );
  }
}

/// Rx hold card: blocks checkout until an approved prescription exists.
class CheckoutRxHoldCard extends ConsumerWidget {
  const CheckoutRxHoldCard({super.key, required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRx = items.any((i) => i.product?.requiresPrescription == true);
    if (!hasRx) return const SizedBox.shrink();
    final rxAsync = ref.watch(prescriptionsProvider);
    return rxAsync.maybeWhen(
      data: (list) {
        final approved = list.any((p) => p.isApproved);
        if (approved) return const SizedBox.shrink();
        final pending = list.any((p) => p.status.toUpperCase() == 'PENDING');
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orderPendingBg,
            border: Border.all(color: AppColors.warningBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Attach a veterinary prescription to complete this order.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orderPending,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/prescriptions'),
                child: Text(pending ? 'View' : 'Upload'),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Coupon input / applied coupon card in checkout.
class CheckoutCouponSection extends ConsumerWidget {
  const CheckoutCouponSection({
    super.key,
    required this.subtotal,
    required this.controller,
    required this.validating,
    required this.error,
    required this.onValidate,
  });

  final double subtotal;
  final TextEditingController controller;
  final bool validating;
  final String? error;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(checkoutDraftProvider);
    if (draft.couponCode != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryWashFaint,
          border: Border.all(color: AppColors.primaryWashDeep),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.couponCode!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  Text(
                    'You save ₹${formatInr(draft.couponDiscount)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove coupon',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => ref.read(checkoutDraftProvider.notifier).state =
                  draft.copyWith(clearCoupon: true, couponDiscount: 0),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter coupon code (optional)',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                onSubmitted: (_) => onValidate(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: validating ? null : onValidate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: validating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Apply'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => showCouponOffersSheet(context, subtotal: subtotal),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                SizedBox(width: 4),
                Text(
                  'View available offers →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

/// KK Coins redeem editor (balance + 30% cap + stepper).
class CheckoutPointsEditor extends ConsumerWidget {
  const CheckoutPointsEditor({super.key, required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(referralSummaryProvider);
    return summaryAsync.maybeWhen(
      data: (summary) {
        final balance = summary.rewardsPoints;
        if (balance <= 0) return const SizedBox.shrink();
        final draft = ref.watch(checkoutDraftProvider);
        final max = maxRedeemablePoints(balance, subtotal);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KK Coins',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coinsBg,
                border: Border.all(color: AppColors.coinsBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$balance coins available',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          max > 0
                              ? 'Use up to $max coins · ₹1 each'
                              : 'Coins unlock on a higher order value',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 14),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: draft.pointsToRedeem <= 0
                              ? null
                              : () =>
                                    ref
                                        .read(checkoutDraftProvider.notifier)
                                        .state = draft.copyWith(
                                      pointsToRedeem: draft.pointsToRedeem - 1,
                                    ),
                        ),
                        Text(
                          '${draft.pointsToRedeem}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 14),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: draft.pointsToRedeem >= max
                              ? null
                              : () =>
                                    ref
                                        .read(checkoutDraftProvider.notifier)
                                        .state = draft.copyWith(
                                      pointsToRedeem: draft.pointsToRedeem + 1,
                                    ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Payment method selection cards with network pills and COD SMS confirmation banner.
class CheckoutPaymentSection extends ConsumerWidget {
  const CheckoutPaymentSection({
    super.key,
    required this.paymentMethod,
    required this.delivery,
    required this.codConfirmationEnabled,
    this.total = 0.0,
    required this.onPaymentMethodChanged,
  });

  final String paymentMethod;
  final DeliveryInfo? delivery;
  final bool codConfirmationEnabled;
  final double total;
  final ValueChanged<String> onPaymentMethodChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(paymentAvailabilityStatusProvider);
    final availability =
        availabilityAsync.value ?? const PaymentAvailabilityStatus();
    final settings =
        ref.watch(storeSettingsProvider).valueOrNull ??
        StoreSettings.defaults();

    final onlineEnabled =
        availability.onlineEnabled && settings.onlinePaymentsEnabled;
    final pincodeCod = delivery == null || delivery!.cod;
    final pincodePrepaid = delivery == null || delivery!.prepaid;
    final backendCodAllowed =
        availability.codEnabled &&
        availability.userCodAllowed &&
        settings.codEnabled;
    final codAvailable = backendCodAllowed && pincodeCod;

    final partialCodConfigured =
        settings.partialCodEnabled || availability.partialCodEnabled;
    final partialCodAvailable =
        partialCodConfigured &&
        onlineEnabled &&
        pincodePrepaid &&
        pincodeCod &&
        availability.userCodAllowed;
    final quote = settings.partialCodQuote(total);

    String codNote;
    if (codAvailable) {
      if (settings.courierCodFlatFee > 0) {
        codNote =
            'Pay with cash upon delivery · ₹${formatInr(settings.courierCodFlatFee)} COD handling fee';
      } else {
        codNote = 'Pay with cash upon delivery · No extra COD fee';
      }
    } else if (!settings.codEnabled) {
      codNote = 'Cash on Delivery is currently disabled by store';
    } else if (!availability.codEnabled &&
        availability.codDisabledReason != null) {
      codNote = availability.codDisabledReason!;
    } else if (!availability.userCodAllowed &&
        availability.userCodDisabledReason != null) {
      codNote = availability.userCodDisabledReason!;
    } else if (!pincodeCod) {
      codNote = delivery?.pincode != null
          ? 'COD is not available for pincode ${delivery!.pincode}'
          : 'COD is not available for this pincode';
    } else {
      codNote = 'Cash on Delivery is currently unavailable';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _payOption(
          value: 'CASHFREE',
          title: 'Pay online (UPI / Card / Netbanking)',
          enabled: onlineEnabled,
          showNetworkPills: true,
          note: onlineEnabled
              ? null
              : 'Online payments are currently unavailable',
        ),
        if (partialCodConfigured || partialCodAvailable) ...[
          const SizedBox(height: 8),
          _payOption(
            value: 'PARTIAL_COD',
            title: 'Pay ₹${formatInr(quote.advance)} advance now',
            enabled: partialCodAvailable,
            badge: '₹0 COD Fee',
            subtitle: '₹${formatInr(quote.balance)} on delivery',
            note: partialCodAvailable
                ? 'A small advance confirms your order · No extra COD fee'
                : 'Partial payment is currently unavailable for this PIN or account',
          ),
        ],
        const SizedBox(height: 8),
        _payOption(
          value: 'COD',
          title: 'Cash on Delivery (COD)',
          enabled: codAvailable,
          note: codNote,
        ),
        if (paymentMethod == 'COD' &&
            codAvailable &&
            codConfirmationEnabled) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sms_outlined, size: 18, color: AppColors.warning),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm your COD order by SMS',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "We'll send a confirmation link by SMS to your delivery mobile number after you place the order. Tap it to confirm within 24 hours so we can prepare and ship your order.",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _payOption({
    required String value,
    required String title,
    required bool enabled,
    bool showNetworkPills = false,
    String? badge,
    String? subtitle,
    String? note,
  }) {
    final selected = paymentMethod == value;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTap: enabled ? () => onPaymentMethodChanged(value) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    if (note != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: TextStyle(
                          fontSize: 11,
                          color: enabled
                              ? AppColors.textSecondary
                              : AppColors.error,
                        ),
                      ),
                    ],
                    if (showNetworkPills) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final network in const [
                            'UPI',
                            'Visa',
                            'Mastercard',
                            'RuPay',
                          ])
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                network,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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

/// Pre-Order Confirmation Modal (`paymentConfirm`).
Future<bool?> showCheckoutConfirmOrderDialog({
  required BuildContext context,
  required bool isCod,
  bool isPartialCod = false,
  double partialAdvance = 0.0,
  double partialBalance = 0.0,
  required int cartCount,
  required double total,
  required Address address,
  required VoidCallback onChangeAddress,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isPartialCod
            ? 'Pay advance and the balance on delivery?'
            : isCod
            ? 'Place Cash on Delivery order?'
            : 'Proceed to online payment?',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPartialCod
                ? 'Pay ₹${formatInr(partialAdvance)} now and ₹${formatInr(partialBalance)} on delivery. No COD fee.'
                : isCod
                ? 'Pay ₹${formatInr(total)} when your order arrives — nothing is charged now.'
                : "You'll continue to the secure Cashfree payment page.",
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$cartCount ${cartCount == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '₹${formatInr(total)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                const Text(
                  'Delivering to',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${address.formattedAddress}, ${address.city}, ${address.state} - ${address.zipCode}\nMobile: ${address.phone}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(false);
                    onChangeAddress();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Change address',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDeep),
          child: const Text('Confirm & Place Order'),
        ),
      ],
    ),
  );
}

/// Checkout price summary breakdown card.
class CheckoutSummaryCard extends StatelessWidget {
  const CheckoutSummaryCard({
    super.key,
    required this.subtotal,
    required this.couponCode,
    required this.couponDiscount,
    required this.points,
    required this.deliveryFee,
    this.freeDeliveryThreshold = 500.0,
    this.isNotServiceable = false,
    required this.total,
  });

  final double subtotal;
  final String? couponCode;
  final double couponDiscount;
  final int points;
  final double? deliveryFee;
  final double freeDeliveryThreshold;
  final bool isNotServiceable;
  final double total;

  @override
  Widget build(BuildContext context) {
    final fee = deliveryFee ?? 0.0;
    final merchandise = (subtotal - couponDiscount - points).clamp(
      0.0,
      double.infinity,
    );
    final remainingForFreeDelivery = (freeDeliveryThreshold - merchandise)
        .clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Subtotal', '₹${formatInr(subtotal)}', null),
          if (couponCode != null) ...[
            const SizedBox(height: 6),
            _row(
              'Coupon ($couponCode)',
              '− ₹${formatInr(couponDiscount)}',
              AppColors.success,
            ),
          ],
          if (points > 0) ...[
            const SizedBox(height: 6),
            _row(
              'KK Coins ($points)',
              '− ₹${formatInr(points.toDouble())}',
              AppColors.success,
            ),
          ],
          const SizedBox(height: 6),
          _row(
            'Delivery Fee',
            isNotServiceable
                ? 'Unavailable for this PIN'
                : fee <= 0
                ? 'FREE'
                : '₹${formatInr(fee)}',
            isNotServiceable
                ? AppColors.textSecondary
                : fee <= 0
                ? AppColors.success
                : null,
          ),
          if (!isNotServiceable && fee > 0 && remainingForFreeDelivery > 0) ...[
            const SizedBox(height: 3),
            Text(
              'Add ₹${formatInr(remainingForFreeDelivery)} more for FREE delivery',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDeep,
              ),
            ),
          ],
          const SizedBox(height: 6),
          _feeJokeRow('Platform fees', "We're not those guys"),
          const SizedBox(height: 4),
          _feeJokeRow('Packaging fees', 'Seriously? Nope'),
          const Divider(height: 20),
          _row('Order total', '₹${formatInr(total)}', null, bold: true),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xB3FDF2F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCE7F3)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NO CONFUSING FEES · NO HIDDEN CHARGES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Somewhere, an app just invented a new fee. Not us.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFBCFE8)),
                  ),
                  child: const Text(
                    '🛡️ NO NONSENSE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeJokeRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF047857),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, Color? color, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: FontWeight.w800,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Sticky bottom Place Order / Pay button bar for CheckoutScreen.
class CheckoutStickyPlaceOrderBar extends StatelessWidget {
  const CheckoutStickyPlaceOrderBar({
    super.key,
    required this.canPlace,
    this.disabledReason,
    this.resolveLabel = 'Review and continue',
    this.onResolve,
    required this.submitting,
    required this.paymentMethod,
    required this.total,
    this.advanceAmount = 0.0,
    required this.onPlaceOrder,
  });

  final bool canPlace;
  final String? disabledReason;
  final String resolveLabel;
  final VoidCallback? onResolve;
  final bool submitting;
  final String paymentMethod;
  final double total;
  final double advanceAmount;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2ECE6), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0C173C32),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (disabledReason != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(disabledReason!, textAlign: TextAlign.center),
                ),
                if (onResolve != null)
                  TextButton(onPressed: onResolve, child: Text(resolveLabel)),
                const SizedBox(height: 8),
              ],
              if (paymentMethod == 'PARTIAL_COD')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '₹${formatInr(advanceAmount)} now · ₹${formatInr((total - advanceAmount).clamp(0.0, total).toDouble())} on delivery',
                    textAlign: TextAlign.center,
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: 48,
                ),
                child: ElevatedButton(
                  onPressed: (canPlace && !submitting) ? onPlaceOrder : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: submitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              paymentMethod == 'COD'
                                  ? 'Placing order…'
                                  : 'Opening payment gateway…',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          paymentMethod == 'COD'
                              ? 'Place Order · ₹${formatInr(total)}'
                              : paymentMethod == 'PARTIAL_COD'
                              ? 'Pay ₹${formatInr(advanceAmount > 0 ? advanceAmount : total)} advance →'
                              : 'Pay ₹${formatInr(total)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showCheckoutOrderSuccessSheet(BuildContext context, Order order) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => CheckoutOrderSuccessSheet(order: order),
  );
}

/// Order confirmed celebration sheet shown after placing an order.
class CheckoutOrderSuccessSheet extends StatelessWidget {
  const CheckoutOrderSuccessSheet({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        20 +
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 28, 24, bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          const Text(
            'ORDER CONFIRMED',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your order is in!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoTile('Order number', '#${order.orderNumber}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoTile('Total', formatPrice(order.totalAmount)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'What happens next',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          _step(1, 'We confirm & pack your order'),
          _step(2, "You'll get SMS updates as it ships"),
          _step(3, 'Delivered to your doorstep soon'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/order/${order.id}');
            },
            child: const Text('Track your order'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Continue shopping'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _step(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
