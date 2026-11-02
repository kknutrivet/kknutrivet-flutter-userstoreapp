import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/common.dart';
import '../../../models/referral.dart';
import '../../../providers/app_providers.dart';

final referralSummaryProvider =
    FutureProvider.autoDispose<ReferralSummary>((ref) {
  ref.watch(authProvider);
  return ref.read(referralServiceProvider).fetchSummary();
});

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(referralSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Rewards & KK Coins',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: summaryAsync.when(
          data: (summary) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(referralSummaryProvider);
            await ref.read(referralSummaryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Gold balance card
              AppCard(
                variant: AppCardVariant.tinted,
                backgroundColor: AppColors.primaryDeep,
                borderColor: AppColors.primaryDeepest,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE68A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFB45309),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KK COINS BALANCE',
                              style: TextStyle(
                                color: Color(0xFFD1FAE5),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              '1 KK Coin = ₹1 at checkout',
                              style: TextStyle(
                                color: Color(0xFFA7F3D0),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${summary.rewardsPoints}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.referralRewardDescription ??
                          'Earn 5% KK Coins on every order and consultation.',
                      style: const TextStyle(
                        color: Color(0xFFD1FAE5),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Referral Code Card
              if (summary.referralCode.isNotEmpty)
                AppCard(
                  variant: AppCardVariant.elevated,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Referral Code',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary.referralCode,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDeep,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppButton(
                        label: 'Copy Code',
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.sm,
                        onPressed: () async {
                          AppHaptics.light();
                          await Clipboard.setData(
                              ClipboardData(text: summary.referralCode));
                          showToast('Referral code copied to clipboard!');
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      variant: AppCardVariant.elevated,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Friends Referred',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${summary.completedReferrals ?? summary.totalReferrals ?? 0}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      variant: AppCardVariant.elevated,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Earned',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${(summary.referralReward ?? summary.rewardsPoints.toDouble()).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // How It Works
              AppCard(
                variant: AppCardVariant.elevated,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How KK Referral Works',
                      style: AppTheme.serif(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _stepRow('1', 'Share your code or link with friends & pet parents'),
                    const SizedBox(height: 10),
                    _stepRow('2', 'They get ₹50 off their first veterinary order'),
                    const SizedBox(height: 10),
                    _stepRow('3', 'You earn 5% KK Coins after their order delivers'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AppButton(
                label: 'Copy & Share Referral Link',
                icon: const Icon(Icons.share_rounded, size: 16),
                variant: AppButtonVariant.primary,
                size: AppButtonSize.lg,
                fullWidth: true,
                onPressed: () async {
                  AppHaptics.light();
                  final text = summary.referralLink != null &&
                          summary.referralLink!.isNotEmpty
                      ? 'Shop authentic veterinary medicine, food & care bundles on KK Nutrivet! Use my referral code ${summary.referralCode}: ${summary.referralLink}'
                      : 'Shop authentic veterinary medicine, food & care bundles on KK Nutrivet! Use my referral code: ${summary.referralCode}';
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    await AppShare.shareText(
                      context,
                      text: text,
                      title: 'Share Referral Code',
                      subject: 'Join KK Nutrivet',
                      fallbackCopyText: text,
                    );
                  }
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
        loading: () => const Center(child: AppLoader.large()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load rewards',
              description: e.toString(),
              actionLabel: 'Try Again',
              onAction: () => ref.invalidate(referralSummaryProvider),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _stepRow(String num, String text) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primaryWash,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
