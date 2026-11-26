import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/compact_product_card.dart';
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
      title: 'Featured products',
      description: '',
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

// ── 6b. HomeActiveOrderBanner (matches HomeCustomerPulse.tsx active order) ──
class HomeActiveOrderBanner extends ConsumerWidget {
  const HomeActiveOrderBanner({super.key});

  static const Map<String, String> _statusCopy = {
    'PENDING': 'Order placed',
    'CONFIRMED': 'Confirmed',
    'PROCESSING': 'Packing your order',
    'SHIPPED': 'On the way',
    'OUT_FOR_DELIVERY': 'Out for delivery',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrder = ref.watch(homeActiveOrderProvider).valueOrNull;
    if (activeOrder == null) return const SizedBox.shrink();

    final statusLabel =
        _statusCopy[activeOrder.status.toUpperCase()] ?? 'Active order';
    final orderNo = activeOrder.orderNumber.isNotEmpty
        ? ' · #${activeOrder.orderNumber}'
        : '';
    final itemCount = activeOrder.items.isNotEmpty
        ? activeOrder.items.length
        : 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Haptics.tap();
            context.push('/order/${activeOrder.id}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDF8F2), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFE0CE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14073A29),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF07583F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$statusLabel$orderNo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF123D2F),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'} · Tap for live delivery updates',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A6B5D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07583F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Track',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 6c. HomeReorderRail ("Order again in 1 tap" — matches HomeCustomerPulse.tsx) ──
class HomeReorderRail extends ConsumerWidget {
  const HomeReorderRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reorderAsync = ref.watch(recentReorderProductsProvider);
    final products = reorderAsync.valueOrNull ?? const <Product>[];

    if (products.isEmpty) return const SizedBox.shrink();
    final shown = products.take(8).toList();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF5FAF7),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFDCE8E0)),
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
                    color: const Color(0xFFE3F1E8),
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
                  child: const Icon(
                    Icons.replay_rounded,
                    size: 20,
                    color: Color(0xFF07583F),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order again in 1 tap',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF143D2E),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quick reorder from your past orders',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A6B5D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFF07583F),
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: const Color(0x291C4637),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Haptics.tap();
                      context.push('/orders');
                    },
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
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
            height: 242 + 30 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: 152,
                child: CompactProductCard(
                  product: shown[i],
                  variant: CompactCardVariant.homeGrid,
                  singleLineTitle: true,
                ),
              ),
            ),
          ),
        ],
      ),
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
      assetPath: 'assets/images/category/homecare-v1.webp',
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

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.shotsTone,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.shotsRailBorder,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.movie_creation_outlined,
                    size: 19,
                    color: AppColors.shotsRailAccent,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Video Shots',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.serif(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Video demos and care guides',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Haptics.tap();
                      context.go('/shots');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Watch all',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.primaryDeep,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 236 + 100 * (MediaQuery.textScalerOf(context).scale(12) / 12 - 1).clamp(0, 2),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shots.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
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
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),

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

// ── 10. ConcernsGrid ("Care by concern" — 4-Column Borderless Pastel Tiles) ──
class HomeConcernsRail extends ConsumerWidget {
  const HomeConcernsRail({super.key});

  static const _concernPastels = <Color>[
    Color(0xFFFFF3E8),
    Color(0xFFEAF7EF),
    Color(0xFFF2EEFA),
    Color(0xFFE8F4FC),
    Color(0xFFFDF5E2),
    Color(0xFFFCEEF2),
    Color(0xFFEAF6F4),
    Color(0xFFF2F6E8),
  ];

  static ({IconData icon, Color fg}) _visualForSlug(String slug) {
    final lower = slug.toLowerCase();
    if (lower.contains('tick') ||
        lower.contains('flea') ||
        lower.contains('skin') ||
        lower.contains('coat')) {
      return (icon: Icons.shield_outlined, fg: const Color(0xFFB45309));
    }
    if (lower.contains('worm') ||
        lower.contains('gut') ||
        lower.contains('digest') ||
        lower.contains('liver')) {
      return (icon: Icons.medication_liquid_outlined, fg: const Color(0xFF15803D));
    }
    if (lower.contains('milk') ||
        lower.contains('calcium') ||
        lower.contains('udder') ||
        lower.contains('mastitis')) {
      return (icon: Icons.water_drop_outlined, fg: const Color(0xFF0369A1));
    }
    if (lower.contains('joint') ||
        lower.contains('bone') ||
        lower.contains('mobility')) {
      return (icon: Icons.accessibility_new_rounded, fg: const Color(0xFF7E22CE));
    }
    if (lower.contains('immun') ||
        lower.contains('vitamin') ||
        lower.contains('growth')) {
      return (icon: Icons.bolt_rounded, fg: const Color(0xFFC2410C));
    }
    return (icon: Icons.healing_outlined, fg: AppColors.primaryDeep);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final concernsAsync = ref.watch(homeConcernsProvider);
    return concernsAsync.maybeWhen(
      data: (concerns) {
        if (concerns.isEmpty) return const SizedBox.shrink();
        final shown = concerns.take(8).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Care by concern',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Haptics.tap();
                        context.push('/diseases');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          'See all →',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF07583F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final textScale =
                      (MediaQuery.textScalerOf(context).scale(12) / 12)
                          .clamp(1.0, 2.0);
                  final tileHeight = 116.0 + (textScale - 1.0) * 24.0;
                  return SizedBox(
                    height: tileHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => SizedBox(
                        width: 126,
                        child: _buildPastelConcernTile(
                          context,
                          shown[i],
                          _concernPastels[i % _concernPastels.length],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildPastelConcernTile(
    BuildContext context,
    HealthConcern concern,
    Color bg,
  ) {
    final visual = _visualForSlug(concern.slug);
    final borderColor = Color.lerp(bg, const Color(0xFF17322B), 0.11)!;
    return AppBounce(
      pressedScale: 0.96,
      onTap: () {
        Haptics.tap();
        context.push('/diseases/${concern.slug}');
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D14382B),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              concern.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF18221E),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: concern.imageUrl != null && concern.imageUrl!.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: concern.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        errorWidget: (_, _, _) => Icon(
                          visual.icon,
                          size: 21,
                          color: visual.fg,
                        ),
                      )
                    : Icon(
                        visual.icon,
                        size: 21,
                        color: visual.fg,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
