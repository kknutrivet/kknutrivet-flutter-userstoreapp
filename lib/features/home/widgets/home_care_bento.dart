import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/app_providers.dart';
import 'home_models_and_data.dart';

// ── 1. Editorial Hero Spotlight Banner ─────────────────────────────────────
/// Full-bleed studio-composited hero card using `mobile-shop-hero-v3.webp`
/// so animals stand naturally in a sunlit forest with zero cutout seams or boxes.
class HomeEditorialHeroBanner extends ConsumerWidget {
  const HomeEditorialHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final animalEntry = findHomeAnimalEntry(selectedAnimal);

    final String eyebrow = animalEntry != null
        ? '${animalEntry.name.toUpperCase()} CARE AISLE'
        : 'VET-TRUSTED · ALL INDIA DISPATCH';
    final String headlineTop = animalEntry != null
        ? animalEntry.title
        : 'Thoughtful care for';
    final String headlineAccent = animalEntry != null
        ? animalEntry.description
        : 'every pet & herd.';
    final String ctaLabel = animalEntry != null
        ? 'Shop ${animalEntry.name}'
        : 'Explore Store';
    final String ctaRoute = animalEntry != null
        ? '/products?animalType=${Uri.encodeComponent(animalEntry.query)}'
        : '/products';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        constraints: const BoxConstraints(minHeight: 164),
        decoration: BoxDecoration(
          color: const Color(0xFF0A3626),
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/images/mobile-shop-hero-v3.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F073828),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.56, 1.0],
              colors: [
                const Color(0xFF082C1F).withValues(alpha: 0.94),
                const Color(0xFF0A3626).withValues(alpha: 0.78),
                const Color(0xFF0A3626).withValues(alpha: 0.10),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 118, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Column(
                    key: ValueKey(selectedAnimal ?? 'all'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          eyebrow,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: Color(0xFFC9FF67),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        headlineTop,
                        style: AppTheme.serif(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        headlineAccent,
                        style: AppTheme.serif(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          height: 1.18,
                          color: const Color(0xFFD8F7A8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          Haptics.tap();
                          context.go(ctaRoute);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: AppColors.primaryDeep,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          Haptics.tap();
                          context.push('/prescriptions');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 13,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Upload Rx',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 2. Curated "Care in spotlight" Horizontal Pastel Tiles ──────────────────
class _SpotlightCardData {
  const _SpotlightCardData({
    required this.title,
    required this.subtitle,
    required this.background,
    required this.cutoutAsset,
    required this.route,
    this.framedPhoto = false,
  });

  final String title;
  final String subtitle;
  final Color background;
  final String cutoutAsset;
  final String route;
  final bool framedPhoto;
}

const _kDefaultSpotlightCards = [
  _SpotlightCardData(
    title: "What's wrong\nwith your animal?",
    subtitle: 'Ask Dr. Paw AI',
    background: Color(0xFFEDE4FF),
    cutoutAsset: 'assets/images/dr-paw-genz.webp',
    route: '/vet',
  ),
  _SpotlightCardData(
    title: 'Order\nwith Rx',
    subtitle: 'Upload vet slip',
    background: Color(0xFFDDF5E6),
    cutoutAsset: 'assets/images/rx-order-3d.webp',
    route: '/prescriptions',
  ),
  _SpotlightCardData(
    title: 'Peak Milk\nStore',
    subtitle: 'Dairy minerals',
    background: Color(0xFFFDECC8),
    cutoutAsset: 'assets/images/peak-milk-3d.webp',
    route: '/products?animalType=Cattle',
  ),
  _SpotlightCardData(
    title: 'Tick & Worm\nShield',
    subtitle: '360° protection',
    background: Color(0xFFDCEEFF),
    cutoutAsset: 'assets/images/seasonal-shield-3d.webp',
    route: '/products?category=Deworming',
  ),
];

const _kDogSpotlightCards = [
  _SpotlightCardData(
    title: "What's wrong\nwith your dog?",
    subtitle: 'Symptoms & diet',
    background: Color(0xFFE3EEFF),
    cutoutAsset: 'assets/images/dr-paw-genz.webp',
    route: '/vet',
  ),
  _SpotlightCardData(
    title: 'Tick & Worm\nShield',
    subtitle: 'Spot-ons & chews',
    background: Color(0xFFDCEEFF),
    cutoutAsset: 'assets/images/seasonal-shield-3d.webp',
    route: '/products?animalType=Dog&category=Deworming',
  ),
  _SpotlightCardData(
    title: 'Coat, Joint\n& Immunity',
    subtitle: 'Omega & tonics',
    background: Color(0xFFFDECC8),
    cutoutAsset: 'assets/images/category/supplements-v1.webp',
    route: '/products?animalType=Dog&category=Supplement+%26+Nutrition',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Kibble &\nPuppy Meals',
    subtitle: 'Daily nutrition',
    background: Color(0xFFDDF5E6),
    cutoutAsset: 'assets/images/category/feed-v1.webp',
    route: '/products?animalType=Dog&category=Feed',
    framedPhoto: true,
  ),
];

const _kCatSpotlightCards = [
  _SpotlightCardData(
    title: "What's wrong\nwith your cat?",
    subtitle: 'Symptoms & care',
    background: Color(0xFFEEE4FF),
    cutoutAsset: 'assets/images/dr-paw-genz.webp',
    route: '/vet',
  ),
  _SpotlightCardData(
    title: 'Hairball &\nCoat Care',
    subtitle: 'Taurine & washes',
    background: Color(0xFFF3E5F8),
    cutoutAsset: 'assets/images/category/grooming-v1.webp',
    route: '/products?animalType=Cat&category=Grooming',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Flea & Gut\nDeworming',
    subtitle: 'Indoor protection',
    background: Color(0xFFDCEEFF),
    cutoutAsset: 'assets/images/seasonal-shield-3d.webp',
    route: '/products?animalType=Cat&category=Deworming',
  ),
  _SpotlightCardData(
    title: 'Cat Daily\nSupplements',
    subtitle: 'Immunity & care',
    background: Color(0xFFFDECC8),
    cutoutAsset: 'assets/images/category/supplements-v1.webp',
    route: '/products?animalType=Cat&category=Supplement+%26+Nutrition',
    framedPhoto: true,
  ),
];

const _kCattleSpotlightCards = [
  _SpotlightCardData(
    title: 'Peak Milk\nStore',
    subtitle: 'Chelated minerals',
    background: Color(0xFFFDECC8),
    cutoutAsset: 'assets/images/peak-milk-3d.webp',
    route: '/products?animalType=Cattle&category=Supplement+%26+Nutrition',
  ),
  _SpotlightCardData(
    title: 'Udder &\nMilking Care',
    subtitle: 'Gels & support',
    background: Color(0xFFDFF2EE),
    cutoutAsset: 'assets/images/category/medicine-v1.webp',
    route: '/products?animalType=Cattle&category=Medicine',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Herd\nDeworming',
    subtitle: 'Fluke & liver care',
    background: Color(0xFFFCE6DC),
    cutoutAsset: 'assets/images/category/deworming-v1.webp',
    route: '/products?animalType=Cattle&category=Deworming',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Order Farm\nwith Rx',
    subtitle: 'Upload vet slip',
    background: Color(0xFFDDF5E6),
    cutoutAsset: 'assets/images/rx-order-3d.webp',
    route: '/prescriptions',
  ),
];

const _kGoatSpotlightCards = [
  _SpotlightCardData(
    title: 'Grower\nNutrition Store',
    subtitle: 'Minerals & amino',
    background: Color(0xFFDFF3E7),
    cutoutAsset: 'assets/images/category/supplements-v1.webp',
    route: '/products?animalType=Goat%2FSheep&category=Supplement+%26+Nutrition',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Flock\nDeworming',
    subtitle: 'Gut & appetite',
    background: Color(0xFFFCE6DC),
    cutoutAsset: 'assets/images/category/deworming-v1.webp',
    route: '/products?animalType=Goat%2FSheep&category=Deworming',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Hoof, Skin\n& Spray Care',
    subtitle: 'Topical sprays',
    background: Color(0xFFDFEEFA),
    cutoutAsset: 'assets/images/category/spray-v1.webp',
    route: '/products?animalType=Goat%2FSheep&category=Spray',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Order\nwith Rx',
    subtitle: 'Herd prescriptions',
    background: Color(0xFFFDECC8),
    cutoutAsset: 'assets/images/rx-order-3d.webp',
    route: '/prescriptions',
  ),
];

const _kPoultrySpotlightCards = [
  _SpotlightCardData(
    title: 'Broiler\nNutrition Store',
    subtitle: 'FCR & starters',
    background: Color(0xFFFCE6DA),
    cutoutAsset: 'assets/images/category/supplements-v1.webp',
    route: '/products?animalType=Poultry&category=Supplement+%26+Nutrition',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Layer Shell\n& Egg Yield',
    subtitle: 'Calcium & D3',
    background: Color(0xFFFDECC8),
    cutoutAsset: 'assets/images/category/feed-v1.webp',
    route: '/products?animalType=Poultry&category=Feed',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Flock\nImmunity',
    subtitle: 'Liver & electrolytes',
    background: Color(0xFFDFF2EE),
    cutoutAsset: 'assets/images/category/medicine-v1.webp',
    route: '/products?animalType=Poultry&category=Medicine',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Coop & Litter\nHygiene',
    subtitle: 'Biosecurity sprays',
    background: Color(0xFFDDF5E6),
    cutoutAsset: 'assets/images/category/homecare-v1.webp',
    route: '/products?animalType=Poultry&category=Home+Care',
    framedPhoto: true,
  ),
];

const _kExoticSpotlightCards = [
  _SpotlightCardData(
    title: 'Ask Dr. Paw\nSmall Pets',
    subtitle: 'Guided care',
    background: Color(0xFFDEF2F2),
    cutoutAsset: 'assets/images/dr-paw-genz.webp',
    route: '/vet',
  ),
  _SpotlightCardData(
    title: 'Hay, Seed\n& Pellet Mix',
    subtitle: 'Daily feed',
    background: Color(0xFFE8F2DA),
    cutoutAsset: 'assets/images/category/feed-v1.webp',
    route: '/products?animalType=Exotic+%26+Small+Pets&category=Feed',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Vitamin C &\nElectrolytes',
    subtitle: 'Water drops',
    background: Color(0xFFFDECC8),
    cutoutAsset: 'assets/images/category/supplements-v1.webp',
    route: '/products?animalType=Exotic+%26+Small+Pets&category=Supplement+%26+Nutrition',
    framedPhoto: true,
  ),
  _SpotlightCardData(
    title: 'Gentle\nHealth Care',
    subtitle: 'Gut & feather care',
    background: Color(0xFFDFF2EE),
    cutoutAsset: 'assets/images/category/medicine-v1.webp',
    route: '/products?animalType=Exotic+%26+Small+Pets&category=Medicine',
    framedPhoto: true,
  ),
];

List<_SpotlightCardData> _spotlightCardsForAnimal(String? animal) {
  if (animal == null || animal.trim().isEmpty) return _kDefaultSpotlightCards;
  final key = animal.trim().toLowerCase();
  if (key.contains('dog')) return _kDogSpotlightCards;
  if (key.contains('cat')) return _kCatSpotlightCards;
  if (key.contains('cattle') || key.contains('cow')) return _kCattleSpotlightCards;
  if (key.contains('goat') || key.contains('sheep')) return _kGoatSpotlightCards;
  if (key.contains('poultry') || key.contains('bird')) return _kPoultrySpotlightCards;
  if (key.contains('small') || key.contains('exotic')) return _kExoticSpotlightCards;
  return _kDefaultSpotlightCards;
}

/// Clean Blinkit-style horizontal pastel spotlight row (`Care in spotlight`).
class HomeCareBentoSection extends ConsumerWidget {
  const HomeCareBentoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final animalTheme = homeAnimalThemeFor(selectedAnimal);
    final cards = _spotlightCardsForAnimal(selectedAnimal);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = (screenWidth * 0.37).clamp(132.0, 154.0);
    final textScale =
        (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 2.0);
    final tileHeight = 118.0 + (textScale - 1.0) * 26.0;

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              animalTheme.shortName.isNotEmpty
                  ? '${animalTheme.shortName} care in spotlight'
                  : 'Care in spotlight',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
                color: Color(0xFF1C1C1C),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: tileWidth,
                child: _SpotlightPastelTile(
                  item: cards[i],
                  height: tileHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPastelTile extends StatelessWidget {
  const _SpotlightPastelTile({required this.item, required this.height});
  final _SpotlightCardData item;
  final double height;

  @override
  Widget build(BuildContext context) {
    final borderTint = Color.lerp(item.background, const Color(0xFF17322B), 0.11)!;
    final deeperBg = Color.lerp(item.background, Colors.white, 0.28)!;
    return AppBounce(
      pressedScale: 0.96,
      onTap: () {
        Haptics.tap();
        if (item.route.startsWith('/products') ||
            item.route.startsWith('/consultations')) {
          context.go(item.route);
        } else {
          context.push(item.route);
        }
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deeperBg, item.background],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderTint, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F14382B),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: item.framedPhoto ? 7 : 2,
              bottom: item.framedPhoto ? 7 : 1,
              width: item.framedPhoto ? 54 : 64,
              height: item.framedPhoto ? 54 : 64,
              child: IgnorePointer(
                child: item.framedPhoto
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x16000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          item.cutoutAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      )
                    : Image.asset(
                        item.cutoutAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.15,
                      color: Color(0xFF18221E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 88),
                    child: Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600,
                        height: 1.18,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3. Signature Brand Closing Section (Modern App Sign-Off) ────────────────
class HomeBrandSignatureFooter extends StatelessWidget {
  const HomeBrandSignatureFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E2E24),
              Color(0xFF071A14),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2407271F),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top glass pill button ("Explore all medicines & nutrition >")
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Material(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Haptics.tap();
                    context.go('/products');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Explore all medicines & nutrition',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Full-bleed studio forest animal banner with gradient fade
            SizedBox(
              height: 144,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/mobile-shop-hero-v3.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.35, 0.85, 1.0],
                        colors: [
                          Color(0xFF0C281F),
                          Color(0x220C281F),
                          Color(0xCC071A14),
                          Color(0xFF071A14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bold typographic statement
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INDIA’S ANIMAL\nCARE COMPANION',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -0.6,
                      color: Color(0xFF81B29A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Packed with clinical care in Brahmapur, Odisha · Delivered across 18+ states in India.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 28,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          color: Colors.white.withValues(alpha: 0.85),
                          errorBuilder: (_, _, _) => const Text(
                            'KK NUTRIVET',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Material(
                          color: const Color(0xFF1A5C43),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              Haptics.tap();
                              launchUrl(
                                Uri.parse(
                                  'https://wa.me/917846932453?text=${Uri.encodeComponent('Hi KK Nutrivet, I need help choosing the right product.')}',
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 14,
                                    color: Color(0xFFC9FF67),
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'WhatsApp Vet Help',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
