import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/compact_product_card.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../products/widgets/catalogue_controls.dart';
import 'home_models_and_data.dart';

// ── 2c. HomeMyPetsBar (Personalized Quick Switcher for Pet Parents) ───────
class HomeMyPetsBar extends ConsumerWidget {
  const HomeMyPetsBar({super.key});

  static String mapPetTypeToAnimalQuery(String petType) {
    final lower = petType.toLowerCase();
    if (lower.contains('dog')) return 'Dog';
    if (lower.contains('cat')) return 'Cat';
    if (lower.contains('cow') || lower.contains('cattle') || lower.contains('buffalo')) return 'Cattle';
    if (lower.contains('goat') || lower.contains('sheep')) return 'Goat/Sheep';
    if (lower.contains('poultry') || lower.contains('chicken') || lower.contains('bird')) return 'Poultry';
    return petType;
  }

  static String petEmojiForAnimal(String petType) {
    final lower = petType.toLowerCase();
    if (lower.contains('dog')) return '🐕';
    if (lower.contains('cat')) return '🐈';
    if (lower.contains('cow') || lower.contains('cattle') || lower.contains('buffalo')) return '🐄';
    if (lower.contains('goat') || lower.contains('sheep')) return '🐐';
    if (lower.contains('poultry') || lower.contains('bird')) return '🐔';
    return '🐾';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(homePetsProvider);
    final pets = petsAsync.valueOrNull ?? const [];
    if (pets.isEmpty) return const SizedBox.shrink();

    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'My Pets & Animals',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeep.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pets.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Haptics.tap();
                      context.push('/pets');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        'Manage →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pets.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == pets.length) {
                  return AppBounce(
                    onTap: () {
                      Haptics.tap();
                      context.push('/pets/new');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD6E4DC),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline, size: 15, color: AppColors.primaryDeep),
                          SizedBox(width: 5),
                          Text(
                            'Add Pet',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final pet = pets[index];
                final targetSpecies = mapPetTypeToAnimalQuery(pet.animalType);
                final isSelected = selectedAnimal != null &&
                    selectedAnimal.toLowerCase() == targetSpecies.toLowerCase();

                return AppBounce(
                  onTap: () {
                    Haptics.selection();
                    if (isSelected) {
                      ref.read(selectedHomeAnimalProvider.notifier).state = null;
                    } else {
                      ref.read(selectedHomeAnimalProvider.notifier).state = targetSpecies;
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryDeep : const Color(0xFFE8ECE9),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.primaryDeep.withValues(alpha: 0.12)
                              : const Color(0x06173C32),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFF0FDF4),
                          backgroundImage: (pet.photoUrl != null && pet.photoUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(pet.photoUrl!)
                              : null,
                          child: (pet.photoUrl == null || pet.photoUrl!.isEmpty)
                              ? Text(
                                  petEmojiForAnimal(pet.animalType),
                                  style: const TextStyle(fontSize: 13),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  pet.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? AppColors.primaryDeep : AppColors.textPrimary,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle, size: 12, color: AppColors.primaryDeep),
                                ],
                              ],
                            ),
                            Text(
                              pet.breed?.isNotEmpty == true ? pet.breed! : pet.animalType,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isSelected
                                    ? AppColors.primaryDeep.withValues(alpha: 0.8)
                                    : AppColors.textSecondary,
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

// ── 3. HomeAnimalSelector (matches src/components/home/HomeAnimalSelector.tsx) ──
class HomeAnimalSelector extends ConsumerWidget {
  const HomeAnimalSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final hiddenCategories =
        ref.watch(storeSettingsProvider).valueOrNull?.hiddenCategories ?? const [];
    final allAnimals = [...kHomeAnimals, kHomeOtherAnimalEntry];
    final visibleAnimals = allAnimals.where((animal) {
      final nameLower = animal.name.toLowerCase();
      final valLower = animal.value.toLowerCase();
      return !hiddenCategories.any((h) {
        final hl = h.toLowerCase().trim();
        return hl == nameLower || hl == valLower;
      });
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'Shop by animal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Haptics.selection();
                      ref.read(selectedHomeAnimalProvider.notifier).state = null;
                      ref.read(productFilterProvider.notifier).state =
                          ProductFilter();
                      context.push('/products');
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text(
                          'All animals',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDeep,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 102 + 55 * (MediaQuery.textScalerOf(context).scale(12) / 12 - 1).clamp(0, 2),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < visibleAnimals.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Builder(
                      builder: (context) {
                        final animal = visibleAnimals[i];
                        final label = animal.selectorLabel ?? animal.name;
                        final isSelected = selectedAnimal == animal.query ||
                            selectedAnimal == animal.value;
                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: 'Shop for $label',
                          child: SizedBox(
                            width: 72 + 48 * (MediaQuery.textScalerOf(context).scale(12) / 12 - 1).clamp(0, 2),
                            child: AppBounce(
                              pressedScale: 0.92,
                              onTap: () {
                                Haptics.selection();
                                ref
                                    .read(selectedHomeAnimalProvider.notifier)
                                    .state = animal.query;
                                ref.read(productFilterProvider.notifier).state =
                                    ProductFilter(animalType: animal.query);
                                context.push(
                                  '/products?animalType=${Uri.encodeComponent(animal.query)}',
                                );
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: animal.surface.background,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryDeep
                                            : Colors.black
                                                .withValues(alpha: 0.06),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isSelected
                                                  ? AppColors.primaryDeep
                                                  : Colors.black)
                                              .withValues(
                                                  alpha: isSelected ? 0.28 : 0.07),
                                          blurRadius: isSelected ? 10 : 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Transform.scale(
                                      scale: 1.8,
                                      child: Image.asset(
                                        animal.asset,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Icon(
                                          Icons.pets,
                                          size: 26,
                                          color: animal.surface.heading,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.25,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primaryDeep
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. HomeCategorySelector (matches src/components/home/HomeCategorySelector.tsx) ──
class HomeCategorySelector extends ConsumerWidget {
  const HomeCategorySelector({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategories = ref.watch(activeCategoriesProvider);
    final activeLower =
        activeCategories.map((c) => c.toLowerCase().trim()).toSet();

    final visible = <HomeCategoryEntry>[
      for (final cat in kHomeCategories)
        if (activeLower.contains(cat.name.toLowerCase()) ||
            activeLower.contains(cat.label.toLowerCase()))
          cat,
    ];

    for (final catName in activeCategories) {
      final exists = visible.any(
        (c) =>
            c.name.toLowerCase() == catName.toLowerCase() ||
            c.label.toLowerCase() == catName.toLowerCase(),
      );
      if (!exists) {
        visible.add(
          HomeCategoryEntry(
            name: catName,
            label: catName,
            asset: 'assets/images/category/supplements-v1.png',
            background: const Color(0xFFECF6EC),
            color: AppColors.primaryDeep,
            fallbackIcon: Icons.category_outlined,
          ),
        );
      }
    }

    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Shop by category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Haptics.tap();
                    context.push('/products');
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDeep,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Text(
            'Everyday essentials, all in one place.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.textScalerOf(context).scale(12) > 16 ? 2 : 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              mainAxisExtent: 98 + 55 * (MediaQuery.textScalerOf(context).scale(12) / 12 - 1).clamp(0, 2),
            ),
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final cat = visible[i];
              return Semantics(
                button: true,
                label: cat.label,
                child: AppBounce(
                  pressedScale: 0.92,
                  onTap: () {
                    Haptics.tap();
                    context.push(
                      '/products?category=${Uri.encodeComponent(cat.name)}',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: cat.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F17322B),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            cat.asset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              cat.fallbackIcon,
                              size: 26,
                              color: cat.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Kept as an alias so any legacy tests or references still compile cleanly.
class HomeShopByNeedChips extends HomeCategorySelector {
  const HomeShopByNeedChips({super.key, super.selectedAnimal});
}

// ── 5. HomeAnimalScrollRail (matches src/components/home/HomeAnimalScrollRail.tsx) ──
class HomeAnimalProductRail extends ConsumerWidget {
  const HomeAnimalProductRail({super.key, required this.entry});
  final HomeAnimalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenCategories =
        ref.watch(storeSettingsProvider).valueOrNull?.hiddenCategories ?? const [];
    final isHidden = hiddenCategories.any((h) {
      final hl = h.toLowerCase().trim();
      return hl == entry.name.toLowerCase() || hl == entry.value.toLowerCase();
    });
    if (isHidden) {
      return const SizedBox.shrink();
    }

    final productsAsync = ref.watch(animalTypeProductsProvider(entry.value));
    final products = productsAsync.value ?? const <Product>[];
    if (productsAsync.hasError || products.isEmpty) {
      return const SizedBox.shrink();
    }
    final shown = products.take(8).toList();
    final route = '/products?animalType=${Uri.encodeComponent(entry.query)}';

    return HomeScrollProductSection(
      title: entry.title,
      description: entry.description,
      route: route,
      products: shown,
      surface: entry.surface,
      tone: entry.tone,
      assetPath: entry.asset,
      fallbackIcon: Icons.pets,
    );
  }
}

/// Shared full-bleed horizontal product rail matching `HomeAnimalScrollRail.tsx` (`compact` mode).
class HomeScrollProductSection extends StatelessWidget {
  const HomeScrollProductSection({
    super.key,
    required this.title,
    required this.description,
    required this.route,
    required this.products,
    required this.surface,
    required this.tone,
    this.assetPath,
    required this.fallbackIcon,
  });

  final String title;
  final String description;
  final String route;
  final List<Product> products;
  final HomeRailSurface surface;
  final Color tone;
  final String? assetPath;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final shown = products.take(8).toList();

    return Container(
      margin: const EdgeInsets.only(top: 12,bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: surface.background,  
        border: Border(
          top: BorderSide(color: surface.border),
          bottom: BorderSide(color: surface.border),
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
                    color: tone,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x141C4637),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: assetPath != null
                      ? Image.asset(
                          assetPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            fallbackIcon,
                            size: 24,
                            color: surface.heading,
                          ),
                        )
                      : Icon(
                          fallbackIcon,
                          size: 24,
                          color: surface.heading,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.28,
                          color: surface.heading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: surface.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: surface.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Haptics.tap();
                      context.push(route);
                    },
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
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
            height: 252 + 35 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: 168,
                child: CompactProductCard(
                  product: shown[i],
                  variant: CompactCardVariant.catalogue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

