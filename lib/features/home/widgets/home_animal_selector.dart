import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/compact_product_card.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
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

// ── 3. HomeAnimalSelector (Cream Pinned Horizontal Species Icon Tab Strip) ──────
class HomeAnimalSelector extends ConsumerWidget {
  const HomeAnimalSelector({super.key});

  static IconData _iconForSpecies(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('dog')) return Icons.pets_rounded;
    if (lower.contains('cat')) return Icons.cruelty_free_rounded;
    if (lower.contains('cattle')) return Icons.agriculture_outlined;
    if (lower.contains('poultry')) return Icons.egg_alt_outlined;
    if (lower.contains('goat')) return Icons.grass_rounded;
    return Icons.pest_control_rodent_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final animalTheme = homeAnimalThemeFor(selectedAnimal);
    final hiddenCategories =
        ref.watch(storeSettingsProvider).valueOrNull?.hiddenCategories ?? const [];
    final visibleAnimals = kHomeAnimals.where((animal) {
      final nameLower = animal.name.toLowerCase();
      final valLower = animal.value.toLowerCase();
      return !hiddenCategories.any((h) {
        final hl = h.toLowerCase().trim();
        return hl == nameLower || hl == valLower;
      });
    }).toList();

    final isAllSelected = selectedAnimal == null || selectedAnimal.isEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      height: 62,
      decoration: BoxDecoration(
        color: animalTheme.headerBg,
        border: Border(bottom: BorderSide(color: animalTheme.headerBorder)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SpeciesTabItem(
              label: 'All',
              icon: Icons.grid_view_rounded,
              selected: isAllSelected,
              accentColor: animalTheme.accent,
              semanticLabel: 'Shop all animals',
              onTap: () {
                Haptics.selection();
                ref.read(selectedHomeAnimalProvider.notifier).state = null;
              },
            ),
            for (final animal in visibleAnimals) ...[
              Builder(
                builder: (context) {
                  final label = animal.selectorLabel ?? animal.name;
                  final isSelected = selectedAnimal == animal.query ||
                      selectedAnimal == animal.value;
                  return _SpeciesTabItem(
                    label: label,
                    icon: _iconForSpecies(animal.query),
                    asset: animal.asset,
                    selected: isSelected,
                    accentColor: animalTheme.accent,
                    semanticLabel: 'Filter homepage by $label',
                    onTap: () {
                      Haptics.selection();
                      ref.read(selectedHomeAnimalProvider.notifier).state =
                          isSelected ? null : animal.query;
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeciesTabItem extends StatelessWidget {
  const _SpeciesTabItem({
    required this.label,
    required this.icon,
    this.asset,
    required this.selected,
    required this.accentColor,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? asset;
  final bool selected;
  final Color accentColor;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: selected ? accentColor : const Color(0x18000000),
                    width: selected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: asset != null
                    ? Image.asset(
                        asset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          icon,
                          size: 16,
                          color: selected ? accentColor : const Color(0xFF374151),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 16,
                        color: selected ? accentColor : const Color(0xFF374151),
                      ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.0,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? const Color(0xFF1C1C1C)
                      : const Color(0xFF525252),
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                width: selected ? 34 : 0,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4. HomeCategorySelector (4×2 Borderless Pastel Portrait Grid) ─────────
class HomeCategorySelector extends ConsumerWidget {
  const HomeCategorySelector({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  static (String title, Color bg) _pastelMetaFor(String name, String fallbackLabel) {
    switch (name.toLowerCase()) {
      case 'medicine':
        return ('Health &\nMedicine', const Color(0xFFE8F4F2));
      case 'supplement & nutrition':
      case 'supplements':
        return ('Daily\nSupplements', const Color(0xFFFDF3E1));
      case 'feed':
        return ('Animal\nFeed', const Color(0xFFEEF4E4));
      case 'grooming':
        return ('Coat &\nGrooming', const Color(0xFFF5ECF8));
      case 'spray':
        return ('Wound &\nSprays', const Color(0xFFE8F2FA));
      case 'device':
        return ('Vet\nEquipment', const Color(0xFFEDF0F9));
      case 'deworming':
        return ('Gut &\nDeworming', const Color(0xFFFCEEE8));
      case 'home care':
        return ('Home &\nShed Care', const Color(0xFFE6F4EC));
      default:
        return (fallbackLabel, const Color(0xFFEAF4EE));
    }
  }

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
            asset: 'assets/images/category/supplements-v1.webp',
            background: const Color(0xFFEAF4EE),
            color: AppColors.primaryDeep,
            fallbackIcon: Icons.category_outlined,
          ),
        );
      }
    }

    if (visible.isEmpty) return const SizedBox.shrink();

    final animalTheme = homeAnimalThemeFor(selectedAnimal);
    if (animalTheme.priorityCategories.isNotEmpty) {
      visible.sort((a, b) {
        final aIdx = animalTheme.priorityCategories.indexWhere(
          (p) => p.toLowerCase() == a.name.toLowerCase(),
        );
        final bIdx = animalTheme.priorityCategories.indexWhere(
          (p) => p.toLowerCase() == b.name.toLowerCase(),
        );
        return (aIdx == -1 ? 99 : aIdx) - (bIdx == -1 ? 99 : bIdx);
      });
    }

    final textScale =
        (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 2.0);
    final cardHeight = 126.0 + (textScale - 1.0) * 24.0;

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              animalTheme.shortName.isNotEmpty
                  ? 'Shop ${animalTheme.shortName.toLowerCase()} by category'
                  : 'Shop by category',
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
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final cat = visible[i];
                return SizedBox(
                  width: 108,
                  child: _PastelCategoryTile(
                    cat: cat,
                    meta: _pastelMetaFor(cat.name, cat.label),
                    selectedAnimal: selectedAnimal,
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

class _PastelCategoryTile extends StatelessWidget {
  const _PastelCategoryTile({
    required this.cat,
    required this.meta,
    this.selectedAnimal,
  });

  final HomeCategoryEntry cat;
  final (String title, Color bg) meta;
  final String? selectedAnimal;

  @override
  Widget build(BuildContext context) {
    final route = selectedAnimal != null && selectedAnimal!.isNotEmpty
        ? '/products?animalType=${Uri.encodeComponent(selectedAnimal!)}&category=${Uri.encodeComponent(cat.name)}'
        : '/products?category=${Uri.encodeComponent(cat.name)}';
    return Semantics(
      button: true,
      label: cat.label,
      child: AppBounce(
        pressedScale: 0.96,
        onTap: () {
          Haptics.tap();
          context.go(route);
        },
        child: Container(
          decoration: BoxDecoration(
            color: meta.$2,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                cat.asset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(
                    cat.fallbackIcon,
                    size: 28,
                    color: cat.color,
                  ),
                ),
              ),
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: 0.58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.48, 1.0],
                        colors: [
                          meta.$2.withValues(alpha: 0.97),
                          meta.$2.withValues(alpha: 0.85),
                          meta.$2.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 9, 9),
                  child: Text(
                    meta.$1,
                    maxLines: 2,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      height: 1.15,
                      color: Color(0xFF1C1C1C),
                    ),
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

class HomeCategoryProductShelves extends ConsumerWidget {
  const HomeCategoryProductShelves({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  static const Map<String, String> _categoryTitles = {
    'Feed': 'Daily Food & Feed',
    'Supplement & Nutrition': 'Daily Supplements & Tonics',
    'Medicine': 'Health & Medicines',
    'Grooming': 'Coat & Grooming',
    'Deworming': 'Gut & Deworming Care',
    'Spray': 'Wound & Skin Sprays',
    'Device': 'Vet & Farm Equipment',
  };

  static const List<String> _allOrder = [
    'Supplement & Nutrition',
    'Feed',
    'Deworming',
    'Grooming',
    'Medicine',
    'Spray',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = selectedAnimal ?? '';
    final products = ref.watch(homeCategoryProductsProvider(scope)).valueOrNull ?? const <Product>[];
    if (products.isEmpty) return const SizedBox.shrink();

    final hiddenCategories =
        ref.watch(storeSettingsProvider).valueOrNull?.hiddenCategories ?? const [];
    final hiddenLower = hiddenCategories.map((h) => h.toLowerCase().trim()).toSet();
    final animalTheme = homeAnimalThemeFor(selectedAnimal);

    final grouped = <String, List<Product>>{};
    for (final product in products) {
      if (product.requiresPrescription) continue;
      final rawCat = (product.category ?? '').trim();
      final cat = rawCat.isEmpty ? 'Other' : rawCat;
      final catLower = cat.toLowerCase();
      if (catLower == 'combos' || catLower == 'home care' || hiddenLower.contains(catLower)) {
        continue;
      }
      grouped.putIfAbsent(cat, () => <Product>[]).add(product);
    }

    final order = animalTheme.priorityCategories.isNotEmpty
        ? animalTheme.priorityCategories
        : _allOrder;

    final entries = grouped.entries
        .where((e) => e.value.length >= (scope.isNotEmpty ? 2 : 3))
        .toList()
      ..sort((a, b) {
        final aIdx = order.indexWhere((o) => o.toLowerCase() == a.key.toLowerCase());
        final bIdx = order.indexWhere((o) => o.toLowerCase() == b.key.toLowerCase());
        return (aIdx == -1 ? 99 : aIdx) - (bIdx == -1 ? 99 : bIdx);
      });

    final capped = (entries.isNotEmpty
            ? entries
            : grouped.entries.where((e) => e.value.isNotEmpty).toList())
        .take(scope.isNotEmpty ? 5 : 3)
        .toList();

    if (capped.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in capped)
          HomeScrollProductSection(
            title: animalTheme.shortName.isNotEmpty
                ? '${animalTheme.shortName} ${_categoryTitles[entry.key] ?? entry.key}'
                : (_categoryTitles[entry.key] ?? entry.key),
            description: '',
            route: scope.isNotEmpty
                ? '/products?animalType=${Uri.encodeComponent(scope)}&category=${Uri.encodeComponent(entry.key)}'
                : '/products?category=${Uri.encodeComponent(entry.key)}',
            products: entry.value,
            surface: const HomeRailSurface(
              Colors.white,
              Color(0xFFE5E7EB),
              Color(0xFF1C1C1C),
              Color(0xFF525252),
              Color(0xFF07583F),
            ),
            tone: AppColors.primaryDeep,
            fallbackIcon: Icons.category_outlined,
          ),
      ],
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

/// Modern borderless product rail (District-inspired open section header + floating cards).
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
    final nonRx = products.where((p) => !p.requiresPrescription).toList();
    if (nonRx.isEmpty) return const SizedBox.shrink();
    final shown = nonRx.take(8).toList();

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
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Haptics.tap();
                      if (route.startsWith('/products')) {
                        context.go(route);
                      } else {
                        context.push(route);
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 256 + 35 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: 166,
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

