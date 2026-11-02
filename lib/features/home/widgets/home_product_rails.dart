import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../models/content.dart';
import '../../../models/product.dart';
import 'home_animal_selector.dart';
import 'home_models_and_data.dart';

// ── 6. FeaturedProducts (matches src/components/home/FeaturedProducts.tsx) ──
class HomeFeaturedProductsRail extends ConsumerWidget {
  const HomeFeaturedProductsRail({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestAsync = ref.watch(bestSellersProductsProvider);
    final spotAsync = ref.watch(spotlightProductsProvider);
    final bestSellers = bestAsync.value ?? const <Product>[];
    final spotlight = spotAsync.value ?? const <Product>[];

    final seen = <String>{};
    final mixed = <Product>[];
    final maxLen = bestSellers.length > spotlight.length
        ? bestSellers.length
        : spotlight.length;
    for (var i = 0; i < maxLen; i++) {
      for (final p in [
        if (i < bestSellers.length) bestSellers[i],
        if (i < spotlight.length) spotlight[i],
      ]) {
        if (seen.contains(p.id)) continue;
        if (selectedAnimal != null &&
            selectedAnimal!.isNotEmpty &&
            !homeProductMatchesAnimal(p, selectedAnimal)) {
          continue;
        }
        seen.add(p.id);
        mixed.add(p);
      }
    }

    if (mixed.isEmpty) return const SizedBox.shrink();

    final route = selectedAnimal != null && selectedAnimal!.isNotEmpty
        ? '/products?animalType=${Uri.encodeComponent(selectedAnimal!)}'
        : '/products';

    return HomeScrollProductSection(
      title: 'Featured Products · Handpicked Essentials',
      description: 'Top picks & best-selling essentials',
      route: route,
      products: mixed,
      surface: const HomeRailSurface(
        AppColors.featuredRailBg,
        AppColors.featuredRailBorder,
        AppColors.featuredRailHeading,
        AppColors.featuredRailSubtitle,
        AppColors.featuredRailAccent,
      ),
      tone: AppColors.featuredRailBorder,
      fallbackIcon: Icons.workspace_premium_outlined,
    );
  }
}

/// Kept as an alias so any legacy references compile cleanly.
class HomeBestSellersRail extends HomeFeaturedProductsRail {
  const HomeBestSellersRail({super.key, super.selectedAnimal});
}

/// Kept as an alias so any legacy references compile cleanly.
class HomeSpotlightRail extends ConsumerWidget {
  const HomeSpotlightRail({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}

// ── 7. HomeCareProductRail (matches Home Care rail in MobileHomeExperience.tsx) ──
class HomeCareProductRail extends ConsumerWidget {
  const HomeCareProductRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(homeCareProductsProvider);
    final products = asyncProducts.value ?? const <Product>[];
    if (asyncProducts.hasError || products.isEmpty) {
      return const SizedBox.shrink();
    }

    return HomeScrollProductSection(
      title: 'Home Care · Clean & Safe for Pets',
      description: 'Pet-safe disinfectants & floor cleaners',
      route: '/products?category=Home+Care',
      products: products,
      surface: const HomeRailSurface(
        AppColors.homeCareRailBg,
        AppColors.homeCareRailBorder,
        AppColors.homeCareRailHeading,
        AppColors.homeCareRailSubtitle,
        AppColors.homeCareRailAccent,
      ),
      tone: AppColors.homeCareRailBorder,
      assetPath: 'assets/images/category/homecare-v1.png',
      fallbackIcon: Icons.home_outlined,
    );
  }
}

// ── 8. HomeShotsRail (matches src/components/home/HomeShotsRail.tsx) ────────
class HomeShotsRail extends ConsumerWidget {
  const HomeShotsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shotsAsync = ref.watch(homeShotsProvider);
    final shots = shotsAsync.value ?? const <ShotItem>[];
    if (shotsAsync.hasError || shots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.shotsRailBg,
        border: Border(
          top: BorderSide(color: AppColors.shotsRailBorder),
          bottom: BorderSide(color: AppColors.shotsRailBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.shotsTone,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x141C4637),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.movie_creation_outlined,
                    size: 24,
                    color: AppColors.shotsRailAccent,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Video Shots',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.28,
                          color: AppColors.shotsRailHeading,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quick video demos, usage guides and pet care essentials.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.shotsRailSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: AppColors.shotsRailAccent,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: const Color(0x291C4637),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Haptics.tap();
                      context.go('/shots');
                    },
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shots.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _HomeShotCard(shot: shots[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShotCard extends StatelessWidget {
  const _HomeShotCard({required this.shot});
  final ShotItem shot;

  @override
  Widget build(BuildContext context) {
    final discount = shot.discountPercent;
    return SizedBox(
      width: 152,
      child: AppBounce(
        pressedScale: 0.95,
        onTap: () {
          Haptics.tap();
          context.go('/shots?product=${Uri.encodeComponent(shot.id)}');
        },
        child: Material(
          color: const Color(0xFF0A2218),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (shot.image.isNotEmpty)
                AppNetworkImage(
                  imageUrl: shot.image,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              // Dark gradient overlay matching web `bg-[linear-gradient(180deg,rgba(4,16,12,.15)_0%,rgba(4,16,12,.1)_45%,rgba(4,16,12,.92)_100%)]`
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.45, 1.0],
                    colors: [
                      Color(0x2604100C),
                      Color(0x1A04100C),
                      Color(0xEB04100C),
                    ],
                  ),
                ),
              ),
              // Center Play Icon
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              // Top + Bottom badges & product info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.movie_creation_outlined,
                                size: 10,
                                color: Color(0xFF4FFFB0),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                shot.hasVideo ? 'SHOT' : 'PREVIEW',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 10,
                                color: Color(0xFF8BE2B9),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${shot.viewsCount}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shot.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.serif(
                            fontSize: 13,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (shot.price > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                formatPrice(shot.price),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFC9FF67),
                                ),
                              ),
                              if (shot.mrp != null &&
                                  shot.mrp! > shot.price) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    formatPrice(shot.mrp!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (discount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0583C),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '-$discount%',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
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

// ── 10. ConcernsGrid ("Care by Concern") ───────────────────────────────────
class HomeConcernsRail extends ConsumerWidget {
  const HomeConcernsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concernsAsync = ref.watch(homeConcernsProvider);
    return concernsAsync.maybeWhen(
      data: (concerns) {
        if (concerns.isEmpty) return const SizedBox.shrink();
        final shown = concerns.take(6).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: HomeSectionTitle(
                  title: 'Care by Concern',
                  route: '/diseases',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final concern = shown[i];
                    return AppBounce(
                      pressedScale: 0.92,
                      onTap: () {
                        Haptics.tap();
                        context.push('/diseases/${concern.slug}');
                      },
                      child: Container(
                        width: 94,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryWashFaint,
                          border: Border.all(
                            color: AppColors.primaryWashDeep,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: concern.imageUrl != null && concern.imageUrl!.isNotEmpty
                                  ? AppNetworkImage(
                                      imageUrl: concern.imageUrl!,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 100,
                                      errorWidget: (_, _, _) =>
                                          _concernFallback(concern),
                                    )
                                  : _concernFallback(concern),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              concern.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9.5,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
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
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _concernFallback(HealthConcern concern) {
    return Container(
      alignment: Alignment.center,
      color: AppColors.primaryWash,
      child: Text(
        concern.icon?.isNotEmpty == true
            ? concern.icon!
            : (concern.name.isNotEmpty ? concern.name.substring(0, 1) : 'C'),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDeep,
        ),
      ),
    );
  }
}
