import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../models/content.dart';
import '../../../models/homepage_section.dart';
import '../../../models/pet.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

final animalTypeProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, animalType) {
  return ref
      .read(catalogServiceProvider)
      .fetchProducts(animalType: animalType, limit: 10);
});

final homeBrandsProvider = FutureProvider.autoDispose<List<Brand>>((ref) {
  return ref.read(catalogServiceProvider).fetchBrands();
});

final homeBlogPostsProvider = FutureProvider.autoDispose<List<BlogPost>>((ref) {
  return ref.read(contentServiceProvider).fetchBlogPosts();
});

final homeConcernsProvider =
    FutureProvider.autoDispose<List<HealthConcern>>((ref) {
  return ref.read(catalogServiceProvider).fetchHealthConcerns();
});

final homePetsProvider = FutureProvider.autoDispose<List<PetProfile>>((
  ref,
) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  return ref.read(petServiceProvider).fetchPets();
});

/// Kept for product_list_screen.dart which reuses the trending rail source.
final trendingProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) {
  return ref
      .read(catalogServiceProvider)
      .fetchProducts(sort: 'stock_high', limit: 10);
});

final bestSellersProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) {
  return ref
      .read(catalogServiceProvider)
      .fetchProducts(sort: 'newest', limit: 12);
});

final spotlightProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) {
  return ref.read(catalogServiceProvider).fetchProducts(limit: 12);
});

final homeCareProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) {
  return ref
      .read(catalogServiceProvider)
      .fetchProducts(category: 'Home Care', limit: 8);
});

final homeShotsProvider = FutureProvider.autoDispose<List<ShotItem>>((ref) {
  return ref.read(contentServiceProvider).fetchShots();
});

final homepageSectionsProvider =
    FutureProvider.autoDispose<List<HomepageSection>>((ref) {
  return ref.read(contentServiceProvider).fetchHomepageSections();
});

final homeHeroSectionProvider =
    Provider.autoDispose<HeroSectionContent?>((ref) {
  final sections = ref.watch(homepageSectionsProvider).valueOrNull;
  if (sections == null) return null;
  for (final s in sections) {
    if (s.identifier == 'hero_carousel' && s.heroContent != null) {
      return s.heroContent;
    }
  }
  return null;
});

final homeReviewsSectionProvider =
    Provider.autoDispose<ReviewsSectionContent?>((ref) {
  final sections = ref.watch(homepageSectionsProvider).valueOrNull;
  if (sections == null) return null;
  for (final s in sections) {
    if (s.identifier == 'reviews' && s.reviewsContent != null) {
      return s.reviewsContent;
    }
  }
  return null;
});

final homeTrustSectionProvider =
    Provider.autoDispose<TrustSectionContent?>((ref) {
  final sections = ref.watch(homepageSectionsProvider).valueOrNull;
  if (sections == null) return null;
  for (final s in sections) {
    if (s.identifier == 'trust_badges' && s.trustContent != null) {
      return s.trustContent;
    }
  }
  return null;
});

final homeSeasonalPromoSectionProvider =
    Provider.autoDispose<SeasonalPromoContent?>((ref) {
  final sections = ref.watch(homepageSectionsProvider).valueOrNull;
  if (sections == null) return null;
  for (final s in sections) {
    if (s.identifier == 'seasonal-promo' && s.seasonalPromoContent != null) {
      return s.seasonalPromoContent;
    }
  }
  return null;
});

final homeCommunityStorySectionProvider =
    Provider.autoDispose<CommunityStoryContent?>((ref) {
  final sections = ref.watch(homepageSectionsProvider).valueOrNull;
  if (sections == null) return null;
  for (final s in sections) {
    if (s.identifier == 'community_story' && s.communityStoryContent != null) {
      return s.communityStoryContent;
    }
  }
  return null;
});

/// Rail surfaces copied from `lib/animal-category-images.ts`
/// (`animalRailSurfaces`) so each animal aisle reads exactly like the site.
class HomeRailSurface {
  const HomeRailSurface(
    this.background,
    this.border,
    this.heading,
    this.subtitle,
    this.accent,
  );
  final Color background;
  final Color border;
  final Color heading;
  final Color subtitle;
  final Color accent;
}

class HomeAnimalEntry {
  const HomeAnimalEntry({
    required this.name,
    required this.value,
    required this.query,
    required this.asset,
    required this.tone,
    required this.surface,
    required this.title,
    required this.description,
    this.selectorLabel,
  });
  final String name;
  final String value;
  final String query;
  final String asset;
  final Color tone;
  final HomeRailSurface surface;
  final String title;
  final String description;
  final String? selectorLabel;
}

class HomeCategoryEntry {
  const HomeCategoryEntry({
    required this.name,
    required this.label,
    required this.asset,
    required this.color,
    required this.background,
    required this.fallbackIcon,
  });
  final String name;
  final String label;
  final String asset;
  final Color color;
  final Color background;
  final IconData fallbackIcon;
}

class HomeNeedChip {
  const HomeNeedChip({
    required this.label,
    required this.icon,
    this.category,
    this.search,
    this.animalType,
  });
  final String label;
  final IconData icon;
  final String? category;
  final String? search;
  final String? animalType;
}

const kHomeCategories = [
  HomeCategoryEntry(
    name: 'Medicine',
    label: 'Health & Care',
    asset: 'assets/images/category/medicine-v1.png',
    color: Color(0xFF326C69),
    background: Color(0xFFE9F3F1),
    fallbackIcon: Icons.medication_outlined,
  ),
  HomeCategoryEntry(
    name: 'Supplement & Nutrition',
    label: 'Supplements',
    asset: 'assets/images/category/supplements-v1.png',
    color: Color(0xFF926526),
    background: Color(0xFFFBF2DF),
    fallbackIcon: Icons.favorite_border_rounded,
  ),
  HomeCategoryEntry(
    name: 'Feed',
    label: 'Feed',
    asset: 'assets/images/category/feed-v1.png',
    color: Color(0xFF6B7640),
    background: Color(0xFFF0F3E4),
    fallbackIcon: Icons.spa_outlined,
  ),
  HomeCategoryEntry(
    name: 'Grooming',
    label: 'Grooming',
    asset: 'assets/images/category/grooming-v1.png',
    color: Color(0xFF86638D),
    background: Color(0xFFF4ECF6),
    fallbackIcon: Icons.content_cut_outlined,
  ),
  HomeCategoryEntry(
    name: 'Spray',
    label: 'Spray',
    asset: 'assets/images/category/spray-v1.png',
    color: Color(0xFF4B7798),
    background: Color(0xFFEAF2F8),
    fallbackIcon: Icons.cleaning_services_outlined,
  ),
  HomeCategoryEntry(
    name: 'Device',
    label: 'Equipment',
    asset: 'assets/images/category/device-v1.png',
    color: Color(0xFF5C6994),
    background: Color(0xFFEDEFF7),
    fallbackIcon: Icons.medical_services_outlined,
  ),
  HomeCategoryEntry(
    name: 'Deworming',
    label: 'Digestive Care',
    asset: 'assets/images/category/deworming-v1.png',
    color: Color(0xFFAD7255),
    background: Color(0xFFFBEEE7),
    fallbackIcon: Icons.verified_user_outlined,
  ),
  HomeCategoryEntry(
    name: 'Home Care',
    label: 'Home Care',
    asset: 'assets/images/category/homecare-v1.png',
    color: Color(0xFF497868),
    background: Color(0xFFE8F2EB),
    fallbackIcon: Icons.home_outlined,
  ),
];

const kHomeAnimals = [
  HomeAnimalEntry(
    name: 'Dogs',
    value: 'Dog',
    query: 'Dog',
    asset: 'assets/images/animal-categories/dog.png',
    tone: AppColors.dogTone,
    surface: HomeRailSurface(
      AppColors.dogRailBg,
      AppColors.dogRailBorder,
      AppColors.dogRailHeading,
      AppColors.dogRailSubtitle,
      AppColors.dogRailAccent,
    ),
    title: 'Dog care like a tail wag',
    description: 'Food, treats and daily care.',
  ),
  HomeAnimalEntry(
    name: 'Cats',
    value: 'Cat',
    query: 'Cat',
    asset: 'assets/images/animal-categories/cat.png',
    tone: AppColors.catTone,
    surface: HomeRailSurface(
      AppColors.catRailBg,
      AppColors.catRailBorder,
      AppColors.catRailHeading,
      AppColors.catRailSubtitle,
      AppColors.catRailAccent,
    ),
    title: 'Cat care, no guesswork',
    description: 'Food, treats and daily care.',
  ),
  HomeAnimalEntry(
    name: 'Cattle',
    value: 'Cattle',
    query: 'Cattle',
    asset: 'assets/images/animal-categories/cattle.png',
    tone: AppColors.cattleTone,
    surface: HomeRailSurface(
      AppColors.cattleRailBg,
      AppColors.cattleRailBorder,
      AppColors.cattleRailHeading,
      AppColors.cattleRailSubtitle,
      AppColors.cattleRailAccent,
    ),
    title: 'Cattle care for the herd',
    description: 'Supplements and farm essentials.',
  ),
  HomeAnimalEntry(
    name: 'Goats & Sheep',
    value: 'Goat',
    query: 'Goat/Sheep',
    asset: 'assets/images/animal-categories/goat.png',
    tone: AppColors.goatTone,
    surface: HomeRailSurface(
      AppColors.goatRailBg,
      AppColors.goatRailBorder,
      AppColors.goatRailHeading,
      AppColors.goatRailSubtitle,
      AppColors.goatRailAccent,
    ),
    title: 'Goat & sheep care, simple',
    description: 'Everyday support for small flocks.',
  ),
  HomeAnimalEntry(
    name: 'Poultry',
    value: 'Poultry',
    query: 'Poultry',
    asset: 'assets/images/animal-categories/poultry.png',
    tone: AppColors.poultryTone,
    surface: HomeRailSurface(
      AppColors.poultryRailBg,
      AppColors.poultryRailBorder,
      AppColors.poultryRailHeading,
      AppColors.poultryRailSubtitle,
      AppColors.poultryRailAccent,
    ),
    title: 'Poultry care you can count on',
    description: 'Everyday support for your flock.',
  ),
  HomeAnimalEntry(
    name: 'Exotic Pets',
    selectorLabel: 'Small Pets',
    value: 'Exotic & Small Pets',
    query: 'Exotic & Small Pets',
    asset: 'assets/images/animal-categories/exotic.png',
    tone: AppColors.exoticTone,
    surface: HomeRailSurface(
      AppColors.exoticRailBg,
      AppColors.exoticRailBorder,
      AppColors.exoticRailHeading,
      AppColors.exoticRailSubtitle,
      AppColors.exoticRailAccent,
    ),
    title: 'Small pet care essentials',
    description: 'Food and care for small pets.',
  ),
];

const kHomeOtherAnimalEntry = HomeAnimalEntry(
  name: 'Other',
  selectorLabel: 'Other',
  value: 'Other',
  query: 'Other',
  asset: 'assets/images/animal-categories/other-v1.png',
  tone: Color(0xFFE2EDE6),
  surface: HomeRailSurface(
    Color(0xFFF3F8F5),
    Color(0xFFDCE6E0),
    Color(0xFF17322B),
    Color(0xFF52645C),
    Color(0xFF1A5C43),
  ),
  title: 'Other animals',
  description: 'Care essentials across species.',
);

const kAllNeedChips = [
  HomeNeedChip(
    label: 'Deworming',
    icon: Icons.bug_report_outlined,
    category: 'Deworming',
  ),
  HomeNeedChip(
    label: 'Ticks & Fleas',
    icon: Icons.pest_control_outlined,
    search: 'tick',
  ),
  HomeNeedChip(
    label: 'Medicines',
    icon: Icons.medication_outlined,
    category: 'Medicine',
  ),
  HomeNeedChip(
    label: 'Food & Feed',
    icon: Icons.spa_outlined,
    category: 'Feed',
  ),
  HomeNeedChip(
    label: 'Calcium & Tonics',
    icon: Icons.water_drop_outlined,
    search: 'calcium',
  ),
  HomeNeedChip(
    label: 'Grooming & Care',
    icon: Icons.content_cut_outlined,
    category: 'Grooming',
  ),
];

const kPetNeedChips = [
  HomeNeedChip(
    label: 'Ticks & Fleas',
    icon: Icons.bug_report_outlined,
    search: 'tick',
  ),
  HomeNeedChip(
    label: 'Deworming',
    icon: Icons.medication_outlined,
    category: 'Deworming',
  ),
  HomeNeedChip(
    label: 'Food & Nutrition',
    icon: Icons.spa_outlined,
    category: 'Feed',
  ),
  HomeNeedChip(
    label: 'Skin & Coat Care',
    icon: Icons.content_cut_outlined,
    category: 'Grooming',
  ),
  HomeNeedChip(
    label: 'Bone & Joint',
    icon: Icons.verified_user_outlined,
    search: 'calcium',
  ),
  HomeNeedChip(
    label: 'Digestion & Gut',
    icon: Icons.auto_awesome_outlined,
    search: 'digestive',
  ),
];

const kLivestockNeedChips = [
  HomeNeedChip(
    label: 'Milk & Calcium',
    icon: Icons.water_drop_outlined,
    animalType: 'Cattle',
    search: 'calcium',
  ),
  HomeNeedChip(
    label: 'Deworming Bolus',
    icon: Icons.bug_report_outlined,
    category: 'Deworming',
    animalType: 'Cattle',
  ),
  HomeNeedChip(
    label: 'Mastitis & Udder',
    icon: Icons.verified_user_outlined,
    search: 'mastitis',
  ),
  HomeNeedChip(
    label: 'Liver Tonics',
    icon: Icons.medication_outlined,
    search: 'liver',
  ),
  HomeNeedChip(
    label: 'Wound & Antiseptic',
    icon: Icons.auto_awesome_outlined,
    search: 'spray',
  ),
  HomeNeedChip(
    label: 'Feed & Minerals',
    icon: Icons.spa_outlined,
    category: 'Feed',
  ),
];

String homeAudienceFor(String? selectedAnimal) {
  if (selectedAnimal == null || selectedAnimal.isEmpty) return 'all';
  if (selectedAnimal == 'Cattle' ||
      selectedAnimal == 'Goat/Sheep' ||
      selectedAnimal == 'Goat' ||
      selectedAnimal == 'Poultry') {
    return 'livestock';
  }
  return 'pets';
}

HomeAnimalEntry? findHomeAnimalEntry(String? selectedAnimal) {
  if (selectedAnimal == null || selectedAnimal.isEmpty) return null;
  for (final a in kHomeAnimals) {
    if (a.query == selectedAnimal || a.value == selectedAnimal) return a;
  }
  return null;
}

bool homeProductMatchesAnimal(Product product, String? selectedAnimal) {
  if (selectedAnimal == null || selectedAnimal.isEmpty) return true;
  final needle = selectedAnimal.toLowerCase();
  final shortNeedle = needle.split('/').first.split(' ').first;
  return product.animalTypes.any((a) {
    final lower = a.toLowerCase();
    return lower.contains(needle) || lower.contains(shortNeedle);
  });
}

/// Web `SectionTitle`: serif heading + compact "View all" wash pill.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({super.key, required this.title, this.route});
  final String title;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTheme.serif(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (route != null)
          Material(
            color: AppColors.primaryWash,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Haptics.tap();
                context.push(route!);
              },
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 12,
                      color: AppColors.primaryDeep,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
