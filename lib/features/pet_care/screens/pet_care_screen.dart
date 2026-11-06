import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

final petCareProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) {
  return ref
      .read(catalogServiceProvider)
      .fetchProducts(sort: 'newest', limit: 4);
});

/// Matches `ResponsivePetCareLanding.tsx` (`/pet-care`).
class PetCareScreen extends ConsumerWidget {
  const PetCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(petCareProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'KK Pet Care',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(petCareProductsProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
            _heroCard(context),
            const SizedBox(height: 16),
            _benefitsSection(),
            const SizedBox(height: 16),
            _quickSetupCard(),
            const SizedBox(height: 16),
            _careSpaceBanner(context),
            const SizedBox(height: 24),
            Text(
              'Daily Care Essentials',
              style: AppTheme.serif(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            productsAsync.when(
              data: (products) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: productCardExtent(context),
                ),
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return CompactProductCard(
                    product: p,
                    variant: CompactCardVariant.catalogue,
                  );
                },
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: LoadingView(),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    ),
  );
  }

  Widget _heroCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets_rounded,
                        size: 13,
                        color: AppColors.primaryDeep,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PET CARE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    style: AppTheme.serif(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                      height: 1.12,
                    ),
                    children: const [
                      TextSpan(text: 'Remember their care, '),
                      TextSpan(
                        text: 'without remembering everything.',
                        style: TextStyle(color: AppColors.homePeachInk),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Open My Pets to add or manage animals, or ask Dr. Paw now — a profile is optional.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'My Pets',
                        trailingIcon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        fullWidth: true,
                        onPressed: () => context.push('/pets'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Dr. Paw (AI)',
                        variant: AppButtonVariant.outline,
                        fullWidth: true,
                        onPressed: () => context.push('/vet'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Name and animal type are enough to add a pet.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/pet-profile-care-v1.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: AppColors.primaryWash),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF062D24).withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primaryWash,
              border: Border(top: BorderSide(color: AppColors.borderWarmSoft)),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderWarm),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.homePeach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: AppColors.homePeachInk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXAMPLE CARE REMINDER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: AppColors.homePeachInk,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Vaccination due in 1 day',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.homePeach,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Tomorrow',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.homePeachInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderWarmSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHY IT IS USEFUL',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Three things, kept together.',
            style: AppTheme.serif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _benefitTile(
            icon: Icons.notifications_none_rounded,
            iconBg: AppColors.homePeach,
            iconColor: AppColors.homePeachInk,
            title: 'Never miss important care',
            copy:
                'Keep vaccination and deworming dates together and see what is coming next.',
          ),
          const SizedBox(height: 10),
          _benefitTile(
            icon: Icons.favorite_border_rounded,
            iconBg: AppColors.primaryWash,
            iconColor: AppColors.primaryDeep,
            title: 'One simple care history',
            copy:
                'Save growth, reminders and useful records against the correct animal.',
          ),
          const SizedBox(height: 10),
          _benefitTile(
            icon: Icons.auto_awesome_outlined,
            iconBg: AppColors.homeLavender,
            iconColor: AppColors.accentViolet,
            title: 'More relevant Dr. Paw help',
            copy:
                'Use the animal\'s profile as context instead of explaining the basics every time.',
          ),
        ],
      ),
    );
  }

  Widget _benefitTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String copy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderWarmSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  copy,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickSetupCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryWashFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK SETUP',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Only two details to begin.',
            style: AppTheme.serif(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Photo, breed, age and the rest can wait.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _stepPill('1', 'Choose the animal')),
              const SizedBox(width: 10),
              Expanded(child: _stepPill('2', 'Give them a name')),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.check_rounded, size: 16, color: AppColors.primaryDeep),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sign in only if you want the profile on other devices.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepPill(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primaryDeep,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _careSpaceBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR CARE SPACE',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: AppColors.homePeach,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'My Pets is where you add animals. Ask Dr. Paw anytime.',
            style: AppTheme.serif(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'My Pets',
            trailingIcon: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.homePeachInk,
            ),
            variant: AppButtonVariant.amber,
            fullWidth: true,
            onPressed: () => context.push('/pets'),
          ),
        ],
      ),
    );
  }
}
