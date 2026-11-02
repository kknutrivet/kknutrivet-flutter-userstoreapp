import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

final healthConcernsProvider =
    FutureProvider.autoDispose<List<HealthConcern>>((ref) {
  return ref.read(catalogServiceProvider).fetchHealthConcerns();
});

/// Curated UI copy mapping identical to web `src/lib/ui-text/diseases.ts`
const Map<String, ({String name, String description})> _concernCopy = {
  'tick-flea-infestations': (
    name: 'Ticks & Fleas',
    description: 'Ticks, fleas, itching and parasite protection.'
  ),
  'skin-infections': (
    name: 'Skin Problems',
    description: 'Itching, rashes and common skin infections.'
  ),
  'milk-fever': (
    name: 'Milk Fever (Low Calcium)',
    description: 'Low calcium around calving in dairy animals.'
  ),
  'digestive-issues': (
    name: 'Stomach & Digestion',
    description: 'Gas, indigestion and digestive discomfort.'
  ),
  'diarrhea': (
    name: 'Loose Motion / Diarrhea',
    description: 'Loose stools and digestive upset.'
  ),
  'fever': (
    name: 'Fever',
    description: 'High temperature and infection support.'
  ),
  'worm-infestations': (
    name: 'Worms & Deworming',
    description: 'Internal worms and routine deworming.'
  ),
  'respiratory-infections': (
    name: 'Cough & Breathing',
    description: 'Coughing, sneezing and breathing problems.'
  ),
  'ear-infections': (
    name: 'Ear Problems',
    description: 'Ear irritation, discharge and infection.'
  ),
  'eye-infections': (
    name: 'Eye Problems',
    description: 'Redness, discharge and eye irritation.'
  ),
  'wounds-injuries': (
    name: 'Wounds & Injuries',
    description: 'Cuts, wounds and recovery care.'
  ),
  'allergies': (
    name: 'Allergies & Itching',
    description: 'Food or environmental itching and reactions.'
  ),
  'vitamin-mineral-deficiencies': (
    name: 'Vitamin & Mineral Support',
    description: 'Everyday nutritional gaps and supplementation.'
  ),
  'arthritis': (
    name: 'Joint Pain & Arthritis',
    description: 'Joint stiffness, pain and mobility support.'
  ),
  'obesity': (
    name: 'Weight Management',
    description: 'Healthy weight and diet support.'
  ),
  'dehydration': (
    name: 'Dehydration & Fluid Loss',
    description: 'Fluid loss and rehydration support.'
  ),
  'heat-stress': (
    name: 'Heat Stress',
    description: 'Overheating and hot-weather recovery.'
  ),
};

class DiseasesScreen extends ConsumerStatefulWidget {
  const DiseasesScreen({super.key});

  @override
  ConsumerState<DiseasesScreen> createState() => _DiseasesScreenState();
}

class _DiseasesScreenState extends ConsumerState<DiseasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final concernsAsync = ref.watch(healthConcernsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Health Concerns',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.push('/search'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(cartCountProvider);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.push('/cart'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: concernsAsync.when(
          data: (concerns) {
          if (concerns.isEmpty) {
            return const AppEmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'Health library coming soon',
              description:
                  'We are curating veterinary care guidance for your animals.',
            );
          }

          final filteredConcerns = concerns.where((c) {
            final copy = _concernCopy[c.slug];
            final name = copy?.name ?? c.name;
            final desc = copy?.description ?? c.description ?? '';
            final combined = '${c.name} $name $desc'.toLowerCase();
            return _searchQuery.isEmpty || combined.contains(_searchQuery);
          }).toList();

          final vetAfter = filteredConcerns.length <= 4
              ? filteredConcerns.length
              : 4;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(healthConcernsProvider);
              await ref.read(healthConcernsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero Header
                SliverToBoxAdapter(
                  child: _HeroHeader(count: concerns.length),
                ),

                // Prescription Concierge Compact Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _PrescriptionConciergeCard(
                      onUpload: () {
                        AppHaptics.light();
                        context.push('/prescriptions');
                      },
                    ),
                  ),
                ),

                // Search Bar & Results Counter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Find the right care',
                              style: AppTheme.serif(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                            AppBadge(
                              label:
                                  '${filteredConcerns.length} ${filteredConcerns.length == 1 ? 'concern' : 'concerns'}',
                              tone: AppBadgeTone.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText:
                                'Search a concern, e.g. skin, digestion or joints',
                            hintStyle: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textTertiary,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.borderWarm),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.borderWarm),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Empty Search State
                if (filteredConcerns.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 24),
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching concerns',
                        description:
                            'Try another word, or ask our veterinary team for help.',
                        actionLabel: 'Clear search',
                        onAction: () => _searchController.clear(),
                      ),
                    ),
                  )
                else ...[
                  // Grid of Concerns with interleaved "Talk to a Vet" Card
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _buildConcernsWithVetCard(
                          context,
                          filteredConcerns,
                          vetAfter,
                        ),
                      ),
                    ),
                  ),
                ],

                // Bottom Need Help Card
                SliverToBoxAdapter(
                  child: _NeedHelpCard(
                    onUploadRx: () {
                      AppHaptics.light();
                      context.push('/prescriptions');
                    },
                    onAskDrPaw: () {
                      AppHaptics.light();
                      context.push('/vet');
                    },
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 36),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: AppLoader.large(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load health library',
              description: e.toString(),
              actionLabel: 'Try Again',
              onAction: () => ref.invalidate(healthConcernsProvider),
            ),
          ),
        ),
      ),
    ),
  );
}

  List<Widget> _buildConcernsWithVetCard(
    BuildContext context,
    List<HealthConcern> concerns,
    int vetAfter,
  ) {
    final widgets = <Widget>[];

    // Build items up to vetAfter in 2-column rows
    final beforeVet = concerns.take(vetAfter).toList();
    for (int i = 0; i < beforeVet.length; i += 2) {
      final c1 = beforeVet[i];
      final c2 = (i + 1 < beforeVet.length) ? beforeVet[i + 1] : null;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ConcernGridCard(
                  concern: c1,
                  onTap: () {
                    AppHaptics.selection();
                    context.push('/diseases/${c1.slug}');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: c2 != null
                    ? _ConcernGridCard(
                        concern: c2,
                        onTap: () {
                          AppHaptics.selection();
                          context.push('/diseases/${c2.slug}');
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    // Interleave "Talk to a vet" card
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 14),
        child: _TalkToVetCard(
          onStartChat: () {
            AppHaptics.light();
            context.push('/consultations');
          },
        ),
      ),
    );

    // Build items after vetAfter
    if (concerns.length > vetAfter) {
      final afterVet = concerns.skip(vetAfter).toList();
      for (int i = 0; i < afterVet.length; i += 2) {
        final c1 = afterVet[i];
        final c2 = (i + 1 < afterVet.length) ? afterVet[i + 1] : null;

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ConcernGridCard(
                    concern: c1,
                    onTap: () {
                      AppHaptics.selection();
                      context.push('/diseases/${c1.slug}');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: c2 != null
                      ? _ConcernGridCard(
                          concern: c2,
                          onTap: () {
                            AppHaptics.selection();
                            context.push('/diseases/${c2.slug}');
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDE4D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 13,
                    color: AppColors.primaryDeep,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'CARE FOR EVERY ANIMAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCDE4D8)),
                ),
                child: Text(
                  '$count topics',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Shop by health concern',
            style: AppTheme.serif(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A little care, in the right place. Find support for your animal’s everyday wellness and recovery needs.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionConciergeCard extends StatelessWidget {
  const _PrescriptionConciergeCard({required this.onUpload});
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.tinted,
      backgroundColor: const Color(0xFFF0F7F4),
      borderColor: const Color(0xFFCDE4D8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppBadge(
                label: 'PRESCRIPTION CONCIERGE',
                icon: Icon(Icons.receipt_long_rounded,
                    size: 11, color: AppColors.primaryDeep),
                tone: AppBadgeTone.emerald,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  '+5% KK Coins',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Have a vet prescription?',
            style: AppTheme.serif(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Upload a photo — our certified vet team matches every medicine & sends your ready cart.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF38594C),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Upload Prescription (Free Review)',
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            fullWidth: true,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

class _TalkToVetCard extends StatelessWidget {
  const _TalkToVetCard({required this.onStartChat});
  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.tinted,
      backgroundColor: const Color(0xFFEEF7F1),
      borderColor: const Color(0xFFCBE2D3),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Right illustration
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140,
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/images/online-vet-consultation-v1.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.medical_services_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            // Gradient scrim
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEEF7F1),
                      Color(0xFDEEF7F1),
                      Color(0xBBEEF7F1),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 0.72, 1.0],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VET GUIDANCE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Talk to a vet',
                      style: AppTheme.serif(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF173F34),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Send a message or photo. Get certified veterinary guidance.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF38594C),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Start chat',
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 15),
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.sm,
                      onPressed: onStartChat,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Urgent symptoms? Contact a nearby clinic.',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcernGridCard extends StatelessWidget {
  const _ConcernGridCard({required this.concern, required this.onTap});
  final HealthConcern concern;
  final VoidCallback onTap;

  ({IconData icon, Color surface, Color iconColor}) _getVisual(String slug) {
    if (slug.contains('tick') || slug.contains('flea') || slug.contains('worm')) {
      return (
        icon: Icons.pest_control_outlined,
        surface: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      );
    }
    if (slug.contains('skin')) {
      return (
        icon: Icons.auto_awesome_outlined,
        surface: const Color(0xFFFFEDD5),
        iconColor: const Color(0xFFEA580C),
      );
    }
    if (slug.contains('milk-fever')) {
      return (
        icon: Icons.local_drink_outlined,
        surface: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
      );
    }
    if (slug.contains('digest')) {
      return (
        icon: Icons.monitor_heart_outlined,
        surface: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF16A34A),
      );
    }
    if (slug.contains('diarrhea') || slug.contains('dehydrat')) {
      return (
        icon: Icons.water_drop_outlined,
        surface: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
      );
    }
    if (slug.contains('fever')) {
      return (
        icon: Icons.thermostat_outlined,
        surface: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFDC2626),
      );
    }
    if (slug.contains('respirat')) {
      return (
        icon: Icons.air_rounded,
        surface: const Color(0xFFCCFBF1),
        iconColor: const Color(0xFF0D9488),
      );
    }
    if (slug.contains('ear')) {
      return (
        icon: Icons.hearing_outlined,
        surface: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
      );
    }
    if (slug.contains('eye')) {
      return (
        icon: Icons.remove_red_eye_outlined,
        surface: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0284C7),
      );
    }
    if (slug.contains('wound') || slug.contains('injur')) {
      return (
        icon: Icons.healing_outlined,
        surface: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFDC2626),
      );
    }
    if (slug.contains('allerg')) {
      return (
        icon: Icons.spa_outlined,
        surface: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
      );
    }
    if (slug.contains('vitamin') || slug.contains('mineral')) {
      return (
        icon: Icons.local_pharmacy_outlined,
        surface: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      );
    }
    if (slug.contains('arthrit') || slug.contains('joint')) {
      return (
        icon: Icons.fitness_center_outlined,
        surface: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      );
    }
    if (slug.contains('obesity') || slug.contains('weight')) {
      return (
        icon: Icons.monitor_weight_outlined,
        surface: const Color(0xFFFFEDD5),
        iconColor: const Color(0xFFEA580C),
      );
    }
    if (slug.contains('heat')) {
      return (
        icon: Icons.wb_sunny_outlined,
        surface: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
      );
    }
    return (
      icon: Icons.shield_outlined,
      surface: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF16A34A),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = _concernCopy[concern.slug];
    final title = copy?.name ?? concern.name;
    final description = copy?.description ??
        concern.description ??
        'Veterinary care guidance and products.';
    final visual = _getVisual(concern.slug);

    return AppBounce(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2ECE6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: visual.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    visual.icon,
                    size: 24,
                    color: visual.iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 30,
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'Explore care',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 11,
                    color: AppColors.primaryDeep,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard({
    required this.onUploadRx,
    required this.onAskDrPaw,
  });

  final VoidCallback onUploadRx;
  final VoidCallback onAskDrPaw;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: AppCard(
        variant: AppCardVariant.tinted,
        backgroundColor: AppColors.primaryWash,
        borderColor: AppColors.primaryWashDeep,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBadge(
              label: 'NEED A HAND?',
              icon: Icon(Icons.support_agent_rounded,
                  size: 11, color: AppColors.primaryDeep),
              tone: AppBadgeTone.emerald,
            ),
            const SizedBox(height: 8),
            Text(
              'Not sure what your animal needs?',
              style: AppTheme.serif(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Share a prescription or chat with Dr. Paw, our AI veterinary assistant, to find the right care.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Upload Rx',
                    icon: const Icon(Icons.upload_file_rounded, size: 15),
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.sm,
                    onPressed: onUploadRx,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Ask Dr. Paw',
                    icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.sm,
                    onPressed: onAskDrPaw,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
