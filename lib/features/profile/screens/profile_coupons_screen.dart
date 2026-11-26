import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

final profileCouponsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
      return ref.read(orderServiceProvider).fetchProfileCoupons();
    });

/// GPay-style Scratch Cards + Perforated Split-Stub Coupon Tickets screen
/// mirroring `Profile → Coupons & Scratch Cards` on `kknutrivet-webapp`.
class ProfileCouponsScreen extends ConsumerStatefulWidget {
  const ProfileCouponsScreen({super.key});

  @override
  ConsumerState<ProfileCouponsScreen> createState() =>
      _ProfileCouponsScreenState();
}

class _ProfileCouponsScreenState extends ConsumerState<ProfileCouponsScreen> {
  String? _revealingOrderId;

  Future<void> _revealScratchCard(String orderId) async {
    if (_revealingOrderId != null) return;
    setState(() => _revealingOrderId = orderId);
    try {
      await ref.read(orderServiceProvider).claimScratchReward(orderId);
      Haptics.tap();
      showToast('Reward revealed! Check your unlocked perk.');
      ref.invalidate(profileCouponsProvider);
    } catch (e) {
      showToast('Could not reveal scratch card right now.', isError: true);
    } finally {
      if (mounted) setState(() => _revealingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(profileCouponsProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: const Color(0xFF07583F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Coupons & Scratch Cards',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: asyncData.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'Could not load your coupons and scratch cards.',
          onRetry: () => ref.invalidate(profileCouponsProvider),
        ),
        data: (raw) {
          final payload = raw['data'] is Map
              ? Map<String, dynamic>.from(raw['data'] as Map)
              : raw;
          final scratchCards = (payload['scratchCards'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final coupons = (payload['coupons'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          if (scratchCards.isEmpty && coupons.isEmpty) {
            return EmptyView(
              message:
                  'Place an order to unlock Scratch & Win rewards and exclusive coupons.',
              icon: Icons.card_giftcard_rounded,
              action: ElevatedButton(
                onPressed: () => context.go('/products'),
                child: const Text('Start shopping'),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryDeep,
            onRefresh: () async => ref.invalidate(profileCouponsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
              children: [
                if (scratchCards.isNotEmpty) ...[
                  const Text(
                    'Scratch & Win Cards',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.05,
                        ),
                    itemCount: scratchCards.length,
                    itemBuilder: (context, index) =>
                        _buildScratchTile(scratchCards[index]),
                  ),
                  const SizedBox(height: 20),
                ],
                if (coupons.isNotEmpty) ...[
                  const Text(
                    'Your Coupon Tickets',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final coupon in coupons) ...[
                    _buildCouponTicket(coupon),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScratchTile(Map<String, dynamic> card) {
    final state = card['state']?.toString() ?? 'UNSCRATCHED';
    final orderId = card['orderId']?.toString() ?? '';
    final orderNumber = card['orderNumber']?.toString() ?? '';
    final reward = card['reward'] is Map
        ? Map<String, dynamic>.from(card['reward'] as Map)
        : null;
    final isUnscratched = state == 'UNSCRATCHED';
    final isExpired = state == 'EXPIRED';
    final busy = _revealingOrderId == orderId;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isUnscratched && !busy
            ? () => _revealScratchCard(orderId)
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isUnscratched
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF07583F), Color(0xFF0E7C5B)],
                  )
                : null,
            color: isUnscratched
                ? null
                : (isExpired ? const Color(0xFFF1F5F9) : Colors.white),
            border: Border.all(
              color: isUnscratched
                  ? const Color(0xFFD4AF37)
                  : AppColors.border,
              width: isUnscratched ? 1.5 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    isUnscratched
                        ? Icons.auto_awesome_rounded
                        : (isExpired
                              ? Icons.timer_off_outlined
                              : Icons.emoji_events_rounded),
                    size: 22,
                    color: isUnscratched
                        ? const Color(0xFFFDE047)
                        : (isExpired
                              ? AppColors.textTertiary
                              : AppColors.primaryDeep),
                  ),
                  Text(
                    orderNumber.isNotEmpty ? '#$orderNumber' : '',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isUnscratched
                          ? Colors.white70
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUnscratched
                        ? (busy ? 'Revealing…' : 'Tap to Reveal')
                        : isExpired
                        ? 'Expired'
                        : (reward?['title']?.toString() ?? 'Reward Unlocked'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: isUnscratched
                          ? Colors.white
                          : (isExpired
                                ? AppColors.textSecondary
                                : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isUnscratched
                        ? '100% Guaranteed Win'
                        : (reward?['coupon']?.toString() ??
                              (isExpired ? 'Window closed' : 'Credited')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isUnscratched
                          ? const Color(0xFFC9FF67)
                          : AppColors.primaryDeep,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponTicket(Map<String, dynamic> coupon) {
    final code = coupon['code']?.toString() ?? '';
    final description = coupon['description']?.toString() ?? 'Special offer';
    final discountType = coupon['discountType']?.toString() ?? 'flat';
    final discountValue = (coupon['discountValue'] as num?)?.toDouble() ?? 0;
    final minOrder = (coupon['minOrderAmount'] as num?)?.toDouble() ?? 0;
    final status = coupon['status']?.toString() ?? 'ACTIVE';
    final active = status == 'ACTIVE';

    final stubHeadline = discountType.toLowerCase().contains('percent')
        ? '${discountValue.toStringAsFixed(0)}%\nOFF'
        : '₹${discountValue.toStringAsFixed(0)}\nOFF';

    return Opacity(
      opacity: active ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.primaryWashDeep : AppColors.border,
          ),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 78,
                color: active ? const Color(0xFF07583F) : const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  stubHeadline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWashFaint,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryWashDeep),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: active
                                    ? AppColors.primaryDeep
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (minOrder > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Min. order ₹${minOrder.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (active && code.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: code));
                                showToast('Copied $code');
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Copy code',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            InkWell(
                              onTap: () => context.push('/cart'),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Use in Cart →',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
