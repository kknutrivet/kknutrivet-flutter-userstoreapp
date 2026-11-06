import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../models/cart_item.dart';
import '../../../providers/app_providers.dart';
import '../../prescriptions/widgets/rx_checkout_gate.dart';

/// Free delivery progress bar in the cart screen.
class CartFreeDeliveryBar extends StatelessWidget {
  const CartFreeDeliveryBar({
    super.key,
    required this.subtotal,
    required this.threshold,
  });

  final double subtotal;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final remaining = threshold - subtotal;
    final progress = threshold > 0
        ? (subtotal / threshold).clamp(0.0, 1.0)
        : 1.0;
    final qualifies = remaining <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: qualifies
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qualifies
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                qualifies
                    ? Icons.local_shipping
                    : Icons.local_shipping_outlined,
                size: 16,
                color: qualifies ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  qualifies
                      ? "You've unlocked FREE delivery"
                      : '₹${formatInr(remaining)} away from FREE delivery',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: qualifies
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                qualifies ? AppColors.primary : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Order Summary breakdown card in the cart screen (`src/app/cart/page.tsx`).
class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({
    super.key,
    required this.subtotal,
    required this.couponCode,
    required this.couponDiscount,
    required this.points,
    required this.total,
    this.deliveryFee = 0,
    this.baseDeliveryCharge = 49,
    this.freeDeliveryThreshold = 500,
    this.showInlinePincodeChecker = false,
  });

  final double subtotal;
  final String? couponCode;
  final double couponDiscount;
  final int points;
  final double total;
  final double deliveryFee;
  final double baseDeliveryCharge;
  final double freeDeliveryThreshold;
  final bool showInlinePincodeChecker;

  @override
  Widget build(BuildContext context) {
    final earnedCoins = (subtotal * 0.05).round();
    final qualifiesForFreeDelivery = deliveryFee <= 0;
    final merchandiseAfterDiscount = (subtotal - couponDiscount - points).clamp(
      0.0,
      double.infinity,
    );
    final neededForFreeDelivery =
        (freeDeliveryThreshold - merchandiseAfterDiscount).clamp(
          0.0,
          double.infinity,
        );
    final totalSavings =
        couponDiscount +
        points +
        (qualifiesForFreeDelivery && baseDeliveryCharge > 0
            ? baseDeliveryCharge
            : 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryWashDeep),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.primaryWashDeep),
          const SizedBox(height: 10),
          _row('Subtotal', '₹${formatInr(subtotal)}', null),
          if (couponCode != null) ...[
            const SizedBox(height: 6),
            _row(
              'Coupon ($couponCode)',
              '− ₹${formatInr(couponDiscount)}',
              AppColors.success,
            ),
          ],
          const SizedBox(height: 6),
          _row(
            points > 0 ? 'KK Coins ($points)' : 'KK Coins redeemed',
            points > 0 ? '− ₹${formatInr(points.toDouble())}' : '− ₹0',
            points > 0 ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(height: 6),
          _deliveryRow(qualifiesForFreeDelivery),
          if (!qualifiesForFreeDelivery && neededForFreeDelivery > 0) ...[
            const SizedBox(height: 3),
            Text(
              'Add ₹${formatInr(neededForFreeDelivery)} more for FREE delivery',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDeep,
              ),
            ),
          ],
          if (showInlinePincodeChecker) ...[
            const SizedBox(height: 8),
            const CartDeliveryCheckerCard(),
          ],
          const SizedBox(height: 8),
          const SizedBox(height: 4),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Inclusive of all taxes',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${formatInr(total)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (totalSavings > 0) ...[
            const SizedBox(height: 8),
            Text(
              'You will save ₹${formatInr(totalSavings)} on this order',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDeep,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'All taxes included. No additional platform or packaging fees.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (earnedCoins > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.coinsBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.coinsBorder),
              ),
              child: Text(
                '🪙 Earn $earnedCoins KK Coins after delivery',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coinsIcon,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _deliveryRow(bool qualifiesForFreeDelivery) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Delivery',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (qualifiesForFreeDelivery) ...[
          if (baseDeliveryCharge > 0) ...[
            Text(
              '₹${formatInr(baseDeliveryCharge)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Text(
            'FREE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
        ] else
          Text(
            '₹${formatInr(deliveryFee)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
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

/// Standalone delivery pincode checker card placed above the Order Summary.
class CartDeliveryCheckerCard extends ConsumerStatefulWidget {
  const CartDeliveryCheckerCard({super.key});

  @override
  ConsumerState<CartDeliveryCheckerCard> createState() =>
      _CartDeliveryCheckerCardState();
}

class _CartDeliveryCheckerCardState
    extends ConsumerState<CartDeliveryCheckerCard> {
  final _controller = TextEditingController();
  bool _syncedInitial = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length == 6) {
      ref.read(deliveryPincodeProvider.notifier).setPincode(pin);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedPin = ref.watch(deliveryPincodeProvider).valueOrNull;
    if (!_syncedInitial && savedPin != null && savedPin.isNotEmpty) {
      _syncedInitial = true;
      _controller.text = savedPin;
    }
    final etaAsync = ref.watch(deliveryEtaProvider);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Check Delivery Pincode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (savedPin != null && savedPin.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    savedPin,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit pincode',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.primaryDeep,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 38,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        filled: true,
                        fillColor: AppColors.primaryWashFaint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: AppColors.primaryWashDeep,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: AppColors.primaryWashDeep,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: AppColors.primaryDeep,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Check',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            etaAsync.maybeWhen(
              data: (info) {
                if (info == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        info.serviceable
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        size: 15,
                        color: info.serviceable
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          info.serviceable
                              ? 'Delivering to ${info.city?.isNotEmpty == true ? "${info.city} (${info.pincode})" : info.pincode} · ${info.etaLabel}'
                              : 'Delivery unavailable for PIN ${info.pincode}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: info.serviceable
                                ? AppColors.primaryDeep
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Checking pincode serviceability…',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky checkout bottom bar in the cart screen.
class CartStickyCheckoutBar extends ConsumerWidget {
  const CartStickyCheckoutBar({
    super.key,
    required this.total,
    required this.blocked,
    required this.items,
  });

  final double total;
  final bool blocked;
  final List<CartItem> items;

  Future<void> _handleCheckout(BuildContext context, WidgetRef ref) async {
    final allowed = await ensurePrescriptionForCheckout(
      context,
      ref,
      items: items,
    );
    if (!allowed || !context.mounted) return;
    context.push('/checkout');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${formatInr(total)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: blocked
                      ? null
                      : () => _handleCheckout(context, ref),
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty cart view with quick links to products and referrals, matching web mobile.
class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBF7F2),
      alignment: Alignment.center,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8ECE9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F8F5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDCEEE3)),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 28,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'SHOP, SAVE & EARN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your cart is empty',
                      style: AppTheme.serif(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add the care essentials you need, then combine eligible offers and KK Coins at checkout.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          AppHaptics.light();
                          context.go('/products');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeep,
                          foregroundColor: Colors.white,
                          iconColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start shopping',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          AppHaptics.light();
                          context.go('/referral');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: Color(0xFFDDE3E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'View referral rewards',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.only(top: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFEEF2F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.primaryDeep,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Genuine products',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '│',
                              style: TextStyle(color: Color(0xFFDDE3E0)),
                            ),
                          ),
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.primaryDeep,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Secure checkout',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
