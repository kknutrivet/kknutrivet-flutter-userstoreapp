import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/combo_details_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../models/cart_item.dart';
import '../../../models/coupon.dart';
import '../../../models/prescription.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../prescriptions/screens/prescriptions_screen.dart'
    show prescriptionsProvider;
import '../../referral/screens/referral_screen.dart'
    show referralSummaryProvider;

final publicCouponsProvider =
    FutureProvider.autoDispose<List<CouponOffer>>((ref) {
  return ref.read(orderServiceProvider).fetchPublicCoupons();
});

/// Cross-sell Care Combos rail shown between Cart Items and Order Summary.
class CrossSellCombosRail extends ConsumerStatefulWidget {
  const CrossSellCombosRail({
    super.key,
    required this.combos,
    required this.cartItems,
  });

  final List<ComboBundle> combos;
  final List<CartItem> cartItems;

  @override
  ConsumerState<CrossSellCombosRail> createState() =>
      _CrossSellCombosRailState();
}

class _CrossSellCombosRailState extends ConsumerState<CrossSellCombosRail> {
  String? _busyComboId;

  Future<void> _addCombo(ComboBundle combo) async {
    if (_busyComboId != null) return;
    setState(() => _busyComboId = combo.id);
    try {
      await ref.read(cartProvider.notifier).addCombo(
            combo.id,
            comboName: combo.name,
            comboPrice: combo.comboPrice,
            comboImage: combo.image,
          );
      showToast('${combo.name} bundle added to cart!');
    } catch (e) {
      showToast('Could not add bundle: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busyComboId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inCartIds =
        widget.cartItems.map((e) => e.comboId).whereType<String>().toSet();
    final available =
        widget.combos.where((c) => !inCartIds.contains(c.id)).toList();
    final displayList = available.isNotEmpty ? available : widget.combos;
    if (displayList.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryWashDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Care Combos · Complete the routine',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final combo = displayList[index];
                return SizedBox(
                  width: 254,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWashFaint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryWashDeep),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: combo.image != null &&
                                        combo.image!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: combo.image!,
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (combo.savingAmount > 0)
                                    Text(
                                      'Save ₹${combo.savingAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDeep,
                                        height: 1.1,
                                      ),
                                    ),
                                  Text(
                                    combo.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${combo.comboPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDeepest,
                                    height: 1.1,
                                  ),
                                ),
                                if (combo.originalPrice > combo.comboPrice)
                                  Text(
                                    '₹${combo.originalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.mrp,
                                      decoration: TextDecoration.lineThrough,
                                      height: 1.1,
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  showComboDetailsSheet(context, combo),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 30),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            FilledButton(
                              onPressed: _busyComboId != null
                                  ? null
                                  : () => _addCombo(combo),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryDeep,
                                minimumSize: const Size(58, 30),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: _busyComboId == combo.id
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Prescription assistance card linking to `/prescriptions`.
class PrescriptionAssistanceBanner extends StatelessWidget {
  const PrescriptionAssistanceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.rxBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/prescriptions'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.rxBorder),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: AppColors.rxText,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Missing a medicine from your prescription? Upload Rx →',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rxText,
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

/// Rx review banner: approved / pending / none (upload), mirroring the
/// website's cart Rx states (`VetRxReviewSheet` + `cart-rx`).
class CartRxBanner extends ConsumerWidget {
  const CartRxBanner({super.key, required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRx = items.any((i) => i.product?.requiresPrescription == true);
    if (!hasRx) return const SizedBox.shrink();

    final rxAsync = ref.watch(prescriptionsProvider);
    return rxAsync.maybeWhen(
      data: (list) => _banner(context, _latestStatus(list)),
      loading: () => _banner(context, null),
      orElse: () => _banner(context, null),
    );
  }

  String? _latestStatus(List<Prescription> list) {
    if (list.isEmpty) return null;
    return list.first.status.toUpperCase();
  }

  Widget _banner(BuildContext context, String? status) {
    final approved = status == 'APPROVED';
    final pending = status == 'PENDING';
    final bg = approved
        ? AppColors.successBg
        : pending
            ? AppColors.orderPendingBg
            : AppColors.orderPendingBg;
    final fg = approved ? AppColors.success : AppColors.orderPending;
    final title = approved
        ? 'Prescription approved ✓'
        : pending
            ? 'Prescription under review'
            : 'Some items need a valid prescription';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: approved
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warningBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            approved
                ? Icons.check_circle_rounded
                : Icons.medical_information_outlined,
            color: fg,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          if (!approved)
            TextButton(
              onPressed: () => context.push('/prescriptions'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              child: Text(
                pending ? 'View' : 'Upload',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }
}

/// Coupon row + available-offers sheet with validation.
class CartCouponRow extends ConsumerWidget {
  const CartCouponRow({super.key, required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(checkoutDraftProvider);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openOffers(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: draft.couponCode != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.couponCode!,
                            style: const TextStyle(
                              fontSize: 13,
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
                      )
                    : const Text(
                        'Apply coupon',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              if (draft.couponCode != null)
                IconButton(
                  tooltip: 'Remove coupon',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () =>
                      ref.read(checkoutDraftProvider.notifier).state =
                          ref.read(checkoutDraftProvider).copyWith(
                                clearCoupon: true,
                                couponDiscount: 0,
                              ),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOffers(BuildContext context) {
    showCouponOffersSheet(context, subtotal: subtotal);
  }
}

/// Reusable uppercase input formatter for coupon codes.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

void showCouponOffersSheet(BuildContext context, {required double subtotal}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CouponSheet(subtotal: subtotal),
  );
}

class CouponSheet extends ConsumerStatefulWidget {
  const CouponSheet({super.key, required this.subtotal});
  final double subtotal;

  @override
  ConsumerState<CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends ConsumerState<CouponSheet> {
  final _codeController = TextEditingController();
  bool _validating = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _apply(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    setState(() {
      _validating = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(orderServiceProvider)
          .validateCoupon(trimmed, widget.subtotal);
      final discount = (result['discount'] as num?)?.toDouble() ?? 0;
      final coupon = result['coupon'];
      final appliedCode = coupon is Map
          ? coupon['code']?.toString() ?? trimmed
          : trimmed;
      if (!mounted) return;
      ref.read(checkoutDraftProvider.notifier).state =
          ref.read(checkoutDraftProvider).copyWith(
                couponCode: appliedCode,
                couponDiscount: discount,
              );
      Navigator.pop(context);
      showToast('Coupon applied — you save ₹${formatInr(discount)}');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(publicCouponsProvider);
    final bottomInset =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available offers',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              IconButton(
                tooltip: 'Refresh offers',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () => ref.invalidate(publicCouponsProvider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                    UpperCaseTextFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Enter coupon code',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                  ),
                  onSubmitted: _apply,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _validating
                      ? null
                      : () => _apply(_codeController.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _validating
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
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 12),
          Flexible(
            child: offersAsync.when(
              data: (offers) {
                if (offers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 32,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No public offers available right now',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter your coupon code above to apply a discount.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final offer = offers[i];
                    return _OfferTile(
                      offer: offer,
                      onApply: () => _apply(offer.code),
                      validating: _validating,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load offers: $e',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(publicCouponsProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.onApply,
    required this.validating,
  });
  final CouponOffer offer;
  final VoidCallback onApply;
  final bool validating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              offer.code,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.headline,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  offer.subline,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (offer.expiryBadge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      offer.expiryBadge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: validating ? null : onApply,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

/// KK Coins editor — balance, 30%-of-subtotal cap, Material 3 Slider,
/// "Apply" / "Remove" / "Use max" quick actions, and "1 KK Coin = ₹1".
/// Always visible on the Cart screen for signed-in users (with or without
/// coins) as well as guests (with a Sign in CTA to unlock coin redemption).
class CartPointsRow extends ConsumerWidget {
  const CartPointsRow({super.key, required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final isSignedIn = user != null && !user.isAnonymous;
    final summaryAsync = ref.watch(referralSummaryProvider);
    final summaryBalance = summaryAsync.valueOrNull?.rewardsPoints ?? 0;
    final balance =
        summaryBalance > 0 ? summaryBalance : (user?.loyaltyPoints ?? 0);
    final earnedCoins = (subtotal * 0.05).round();
    final maxCapForOrder = (subtotal * 0.30).floor();

    if (!isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.coinsBg,
          border: Border.all(color: AppColors.coinsBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.coinsBorder),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                size: 19,
                color: AppColors.coinsIcon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Redeem KK Coins',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    maxCapForOrder > 0
                        ? 'Sign in to redeem up to ₹$maxCapForOrder · 1 KK Coin = ₹1'
                        : 'Sign in to redeem KK Coins · 1 KK Coin = ₹1',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: () {
                  ref.read(pendingAuthRedirectProvider.notifier).state =
                      '/cart';
                  context.push('/login');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (balance <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.coinsBg,
          border: Border.all(color: AppColors.coinsBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.coinsBorder),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                size: 19,
                color: AppColors.coinsIcon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KK Coins · 0 available',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    earnedCoins > 0
                        ? 'Earn +$earnedCoins KK Coins after delivery · 1 KK Coin = ₹1'
                        : 'Earn 5% back in KK Coins on every order · 1 KK Coin = ₹1',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/referral'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDeep,
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Earn ›',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final draft = ref.watch(checkoutDraftProvider);
    final maxRedeemable = maxRedeemablePoints(balance, subtotal);
    final currentPoints = draft.pointsToRedeem.clamp(0, maxRedeemable);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.coinsBg,
        border: Border.all(color: AppColors.coinsBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.coinsBorder),
                ),
                child: const Icon(
                  Icons.monetization_on_rounded,
                  size: 19,
                  color: AppColors.coinsIcon,
                ),
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
                            currentPoints > 0
                                ? '$currentPoints Coins applied'
                                : 'KK Coins · $balance available',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (currentPoints > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-₹$currentPoints',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentPoints > 0
                          ? '${balance - currentPoints} coins remaining · 1 KK Coin = ₹1'
                          : maxRedeemable > 0
                              ? 'Use up to $maxRedeemable coins · 1 KK Coin = ₹1'
                              : 'Coins unlock on a higher order value · 1 KK Coin = ₹1',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentPoints > 0)
                TextButton(
                  onPressed: () =>
                      ref.read(checkoutDraftProvider.notifier).state =
                          draft.copyWith(pointsToRedeem: 0),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (maxRedeemable > 0 && currentPoints == 0)
                SizedBox(
                  height: 34,
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(checkoutDraftProvider.notifier).state =
                            draft.copyWith(pointsToRedeem: maxRedeemable),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Use max',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
              else if (maxRedeemable > 0 && currentPoints < maxRedeemable)
                TextButton(
                  onPressed: () =>
                      ref.read(checkoutDraftProvider.notifier).state =
                          draft.copyWith(pointsToRedeem: maxRedeemable),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    foregroundColor: AppColors.primaryDeep,
                  ),
                  child: const Text(
                    'Use max',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (maxRedeemable > 0) ...[
            Slider(
              value: currentPoints.toDouble(),
              min: 0,
              max: maxRedeemable.toDouble(),
              divisions: maxRedeemable > 0 ? maxRedeemable : 1,
              label: '$currentPoints coins (−₹$currentPoints)',
              onChanged: (val) {
                ref.read(checkoutDraftProvider.notifier).state =
                    draft.copyWith(pointsToRedeem: val.round());
              },
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentPoints > 0
                        ? 'Redeeming $currentPoints coins (−₹$currentPoints)'
                        : 'Slide to redeem KK Coins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Max: $maxRedeemable',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
