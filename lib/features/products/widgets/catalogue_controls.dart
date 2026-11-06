import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../models/product_facets.dart';
import '../../../providers/app_providers.dart';

class ProductFilter {
  ProductFilter({
    this.animalType,
    this.category,
    this.subCategory,
    this.search,
    this.disease,
    this.sort = 'relevance',
    this.brand,
    this.priceRange,
    this.inStockOnly = false,
    this.prescription,
  });

  // Server-side (sent to /api/products + /api/products/facets)
  final String? animalType;
  final String? category;
  final String? subCategory;
  final String? search;
  final String? disease;
  final String sort;

  // Client-side — the website applies these to the already-fetched list,
  // since the API has no brand/price/stock/prescription sort params
  // (sort itself is also client-side for `discount`/`relevance`).
  final String? brand;
  final String? priceRange; // 'under-500' | '500-1000' | 'over-1000'
  final bool inStockOnly;
  final String? prescription; // 'required' | 'not-required'

  bool get hasAny =>
      animalType != null ||
      category != null ||
      subCategory != null ||
      search != null ||
      disease != null ||
      sort != 'relevance' ||
      brand != null ||
      priceRange != null ||
      inStockOnly ||
      prescription != null;

  /// Badge on the Refine button — every set dimension counts, exactly like
  /// the website's `activeFilterCount`.
  int get activeCount =>
      (animalType != null ? 1 : 0) +
      (category != null ? 1 : 0) +
      (subCategory != null ? 1 : 0) +
      (disease != null ? 1 : 0) +
      (search != null ? 1 : 0) +
      (priceRange != null ? 1 : 0) +
      (prescription != null ? 1 : 0) +
      (inStockOnly ? 1 : 0);

  /// Whether [CatalogueActiveChips] renders a 40dp chip strip below the control bar.
  bool get hasVisibleActiveChips =>
      category != null ||
      disease != null ||
      search != null ||
      (priceRange != null && priceRange != 'under-500') ||
      (prescription != null && prescription != 'not-required');

  ProductFilter copyWith({
    String? animalType,
    bool clearAnimalType = false,
    String? category,
    bool clearCategory = false,
    String? subCategory,
    bool clearSubCategory = false,
    String? search,
    bool clearSearch = false,
    String? disease,
    bool clearDisease = false,
    String? sort,
    String? brand,
    bool clearBrand = false,
    String? priceRange,
    bool clearPriceRange = false,
    bool? inStockOnly,
    String? prescription,
    bool clearPrescription = false,
  }) {
    return ProductFilter(
      animalType: clearAnimalType ? null : (animalType ?? this.animalType),
      category: clearCategory ? null : (category ?? this.category),
      subCategory: (clearCategory || clearSubCategory)
          ? null
          : (subCategory ?? this.subCategory),
      search: clearSearch ? null : (search ?? this.search),
      disease: clearDisease ? null : (disease ?? this.disease),
      sort: sort ?? this.sort,
      brand: clearBrand ? null : (brand ?? this.brand),
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      prescription: clearPrescription
          ? null
          : (prescription ?? this.prescription),
    );
  }
}

String? apiSortForCatalogue(String sort) {
  switch (sort) {
    case 'popularity':
      return null; // Legacy link: no sales ranking is exposed by the API.
    case 'newest':
      return 'newest';
    case 'price-low':
      return 'price_low';
    case 'price-high':
      return 'price_high';
    case 'name':
      return 'name_asc';
    default:
      return null; // relevance + discount are client-side
  }
}

final productFilterProvider = StateProvider<ProductFilter>(
  (ref) => ProductFilter(),
);

final productsListProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  final filter = ref.watch(productFilterProvider);
  return ref
      .read(catalogServiceProvider)
      .fetchProducts(
        animalType: filter.animalType,
        category: filter.category,
        subCategory: filter.subCategory,
        search: filter.search,
        disease: filter.disease,
        sort: apiSortForCatalogue(filter.sort),
      );
});

final productFacetsProvider = FutureProvider.autoDispose<ProductFacets>((ref) {
  final filter = ref.watch(productFilterProvider);
  return ref
      .read(catalogServiceProvider)
      .fetchFacets(
        category: filter.category,
        animalType: filter.animalType,
        search: filter.search,
        disease: filter.disease,
      );
});

List<Product> applyClientProductFilters(
  List<Product> products,
  ProductFilter filter,
) {
  final list = products.where((p) {
    if (filter.subCategory != null && p.subCategory != filter.subCategory) {
      return false;
    }
    if (filter.brand != null && p.brand != filter.brand) return false;
    if (filter.inStockOnly && !p.inStock) return false;
    if (filter.prescription == 'required' && !p.requiresPrescription) {
      return false;
    }
    if (filter.prescription == 'not-required' && p.requiresPrescription) {
      return false;
    }
    if (filter.priceRange != null) {
      final price = p.effectivePrice;
      switch (filter.priceRange) {
        case 'under-500':
          if (price >= 500) return false;
        case '500-1000':
          if (price < 500 || price > 1000) return false;
        case 'over-1000':
          if (price <= 1000) return false;
      }
    }
    return true;
  }).toList();
  if (filter.sort == 'discount') {
    list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
  }
  return list;
}

/// Sticky left animal portrait rail (72px) — `featuredAnimals` rail on the
/// website's mobile catalogue. Values match `PRODUCT_ANIMAL_TYPES` exactly.
class CatalogueAnimalRail extends ConsumerWidget {
  const CatalogueAnimalRail({super.key});

  static const _animals = [
    ('Dog', 'Dogs', 'assets/images/animal-categories/dog.webp', AppColors.dogTone),
    ('Cat', 'Cats', 'assets/images/animal-categories/cat.webp', AppColors.catTone),
    (
      'Cattle',
      'Cattle',
      'assets/images/animal-categories/cattle.webp',
      AppColors.cattleTone,
    ),
    (
      'Goat/Sheep',
      'Goats & Sheep',
      'assets/images/animal-categories/goat.webp',
      AppColors.goatTone,
    ),
    (
      'Poultry',
      'Poultry',
      'assets/images/animal-categories/poultry.webp',
      AppColors.poultryTone,
    ),
    (
      'Exotic & Small Pets',
      'Small pets',
      'assets/images/animal-categories/exotic.webp',
      AppColors.exoticTone,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    Widget item({
      required bool selected,
      required VoidCallback onTap,
      required Widget portrait,
      required String label,
      String? semantics,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: semantics ?? label,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryWash : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SizedBox(width: 40, height: 40, child: portrait),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.primaryDeep
                              : AppColors.textSecondary,
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

    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.primaryWashFaint,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, 6, 0, 6 + bottomInset),
          children: [
            item(
              selected: filter.animalType == null,
              onTap: () {
                final f = ref.read(productFilterProvider);
                ref.read(productFilterProvider.notifier).state = f.copyWith(
                  clearAnimalType: true,
                );
              },
              portrait: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filter.animalType == null
                      ? AppColors.primaryDeep
                      : Colors.white,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'ALL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: filter.animalType == null
                        ? Colors.white
                        : AppColors.primaryDeep,
                  ),
                ),
              ),
              label: 'All',
              semantics: 'All pets',
            ),
            for (final a in _animals)
              item(
                selected: filter.animalType == a.$1,
                onTap: () {
                  final f = ref.read(productFilterProvider);
                  ref
                      .read(productFilterProvider.notifier)
                      .state = filter.animalType == a.$1
                      ? f.copyWith(clearAnimalType: true)
                      : f.copyWith(animalType: a.$1);
                },
                portrait: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: a.$4,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: filter.animalType == a.$1
                          ? AppColors.primaryDeep
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    a.$3,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.pets,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                label: a.$2,
              ),
          ],
        ),
      ),
    );
  }
}

/// One option rendered by [AnimalSelectorRail].
class AnimalSelectorEntry {
  const AnimalSelectorEntry({
    required this.value,
    required this.label,
    required this.asset,
    required this.tone,
  });

  final String value;
  final String label;
  final String asset;
  final Color tone;
}

/// Animal options shared by the catalogue and the remedies list.
const kCatalogueAnimalEntries = <AnimalSelectorEntry>[
  AnimalSelectorEntry(
    value: 'Dog',
    label: 'Dogs',
    asset: 'assets/images/animal-categories/dog.webp',
    tone: AppColors.dogTone,
  ),
  AnimalSelectorEntry(
    value: 'Cat',
    label: 'Cats',
    asset: 'assets/images/animal-categories/cat.webp',
    tone: AppColors.catTone,
  ),
  AnimalSelectorEntry(
    value: 'Cattle',
    label: 'Cattle',
    asset: 'assets/images/animal-categories/cattle.webp',
    tone: AppColors.cattleTone,
  ),
  AnimalSelectorEntry(
    value: 'Poultry',
    label: 'Poultry',
    asset: 'assets/images/animal-categories/poultry.webp',
    tone: AppColors.poultryTone,
  ),
  AnimalSelectorEntry(
    value: 'Goat/Sheep',
    label: 'Goats',
    asset: 'assets/images/animal-categories/goat.webp',
    tone: AppColors.goatTone,
  ),
  AnimalSelectorEntry(
    value: 'Exotic & Small Pets',
    label: 'Small pets',
    asset: 'assets/images/animal-categories/exotic.webp',
    tone: AppColors.exoticTone,
  ),
];

/// Horizontal scrollable image-circle animal selector matching
/// `MobileAnimalSelector.tsx`. Reused by the product catalogue and the
/// remedies list so both surfaces share the same selector style.
class AnimalSelectorRail extends StatelessWidget {
  const AnimalSelectorRail({
    super.key,
    required this.selectedAnimal,
    required this.onSelected,
    this.entries = kCatalogueAnimalEntries,
    this.showAll = true,
    this.backgroundColor = const Color(0xFFF8FAF9),
    this.borderColor = const Color(0xFFE2ECE6),
  });

  /// `null` renders the “All” option as selected.
  final String? selectedAnimal;

  /// Emits the chosen animal, or `null` when “All” is chosen.
  final ValueChanged<String?> onSelected;
  final List<AnimalSelectorEntry> entries;
  final bool showAll;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    Widget item({
      required bool selected,
      required VoidCallback onTap,
      required Widget portrait,
      required String label,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 66,
            padding: const EdgeInsets.fromLTRB(4, 5, 4, 5),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F5EE) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFFB8DEC8) : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 32, height: 32, child: portrait),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? AppColors.primaryDeep
                        : const Color(0xFF4B6358),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        children: [
          if (showAll)
            item(
              selected: selectedAnimal == null,
              onTap: () => onSelected(null),
              portrait: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedAnimal == null
                      ? AppColors.primaryDeep
                      : Colors.white,
                  border: Border.all(
                    color: selectedAnimal == null
                        ? AppColors.primaryDeep
                        : const Color(0xFFD2E0D8),
                    width: selectedAnimal == null ? 1.8 : 1.2,
                  ),
                  boxShadow: selectedAnimal == null
                      ? [
                          BoxShadow(
                            color: AppColors.primaryDeep.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'ALL',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: selectedAnimal == null
                        ? Colors.white
                        : const Color(0xFF4B6358),
                  ),
                ),
              ),
              label: 'All',
            ),
          for (final a in entries)
            item(
              selected: selectedAnimal == a.value,
              onTap: () => onSelected(a.value),
              portrait: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: a.tone,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedAnimal == a.value
                        ? AppColors.primaryDeep
                        : const Color(0xFFD2E0D8),
                    width: selectedAnimal == a.value ? 1.8 : 1.2,
                  ),
                  boxShadow: selectedAnimal == a.value
                      ? [
                          BoxShadow(
                            color: AppColors.primaryDeep.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    a.asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.pets,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              label: a.label,
            ),
        ],
      ),
    );
  }
}

/// Catalogue animal selector wired to [productFilterProvider].
class CatalogueHorizontalAnimalRail extends ConsumerWidget {
  const CatalogueHorizontalAnimalRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    return AnimalSelectorRail(
      selectedAnimal: filter.animalType,
      onSelected: (animal) {
        final f = ref.read(productFilterProvider);
        ref
            .read(productFilterProvider.notifier)
            .state = (animal == null || filter.animalType == animal)
            ? f.copyWith(clearAnimalType: true)
            : f.copyWith(animalType: animal);
      },
    );
  }
}

/// White Refine/Sort + quick-filter control bar (`MobileCatalogueControls`).
class CatalogueControlBar extends ConsumerWidget {
  const CatalogueControlBar({
    super.key,
    required this.onOpenFilters,
    required this.onOpenSort,
  });

  final VoidCallback onOpenFilters;
  final VoidCallback onOpenSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    final count = filter.activeCount;

    Widget pillButton({
      required Widget child,
      required VoidCallback onTap,
      bool active = false,
    }) {
      return Material(
        color: active ? AppColors.primaryWash : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: active ? AppColors.primaryDeep : AppColors.border,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontFamilyFallback: const ['Roboto', 'sans-serif'],
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primaryDeep : AppColors.textPrimary,
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    Widget quickChip({
      required String label,
      required bool active,
      required VoidCallback onTap,
    }) {
      return pillButton(
        active: active,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              const Padding(
                padding: EdgeInsets.only(right: 2),
                child: Text('✓'),
              ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primaryDeep : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    void togglePrice() {
      final f = ref.read(productFilterProvider);
      ref
          .read(productFilterProvider.notifier)
          .state = f.priceRange == 'under-500'
          ? f.copyWith(clearPriceRange: true)
          : f.copyWith(priceRange: 'under-500');
    }

    void toggleNoRx() {
      final f = ref.read(productFilterProvider);
      ref
          .read(productFilterProvider.notifier)
          .state = f.prescription == 'not-required'
          ? f.copyWith(clearPrescription: true)
          : f.copyWith(prescription: 'not-required');
    }

    void toggleOffers() {
      final f = ref.read(productFilterProvider);
      ref.read(productFilterProvider.notifier).state = f.copyWith(
        sort: f.sort == 'discount' ? 'relevance' : 'discount',
      );
    }

    void toggleStock() {
      final f = ref.read(productFilterProvider);
      ref.read(productFilterProvider.notifier).state = f.copyWith(
        inStockOnly: !f.inStockOnly,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            pillButton(
              active: count > 0,
              onTap: onOpenFilters,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list_rounded, size: 14),
                  const SizedBox(width: 6),
                  const Text('Refine'),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      height: 16,
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDeep,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            pillButton(
              onTap: onOpenSort,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('↕', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text('Sort by'),
                ],
              ),
            ),
            const SizedBox(width: 6),
            quickChip(
              label: 'In stock',
              active: filter.inStockOnly,
              onTap: toggleStock,
            ),
            const SizedBox(width: 6),
            quickChip(
              label: 'Under ₹500',
              active: filter.priceRange == 'under-500',
              onTap: togglePrice,
            ),
            const SizedBox(width: 6),
            quickChip(
              label: 'No prescription',
              active: filter.prescription == 'not-required',
              onTap: toggleNoRx,
            ),
            const SizedBox(width: 6),
            quickChip(
              label: 'Best offers',
              active: filter.sort == 'discount',
              onTap: toggleOffers,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dismissible active-filter chips (animal deliberately excluded — the rail
/// already shows it, exactly like the website's `mobileChips`).
class CatalogueActiveChips extends ConsumerWidget {
  const CatalogueActiveChips({super.key, required this.onClearAll});
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    final chips = <({String key, String label, VoidCallback clear})>[
      if (filter.category != null)
        (
          key: 'category',
          label: filter.category!,
          clear: () => ref.read(productFilterProvider.notifier).state = filter
              .copyWith(clearCategory: true),
        ),
      if (filter.disease != null)
        (
          key: 'disease',
          label: filter.disease!,
          clear: () => ref.read(productFilterProvider.notifier).state = filter
              .copyWith(clearDisease: true),
        ),
      if (filter.search != null)
        (
          key: 'search',
          label: '“${filter.search}”',
          clear: () => ref.read(productFilterProvider.notifier).state = filter
              .copyWith(clearSearch: true),
        ),
      if (filter.priceRange != null && filter.priceRange != 'under-500')
        (
          key: 'price',
          label: filter.priceRange == '500-1000'
              ? '₹500–₹1,000'
              : filter.priceRange == 'over-1000'
              ? 'Above ₹1,000'
              : filter.priceRange!,
          clear: () => ref.read(productFilterProvider.notifier).state = filter
              .copyWith(clearPriceRange: true),
        ),
      if (filter.prescription != null && filter.prescription != 'not-required')
        (
          key: 'rx',
          label: filter.prescription == 'required' ? 'Rx only' : 'Non-Rx',
          clear: () => ref.read(productFilterProvider.notifier).state = filter
              .copyWith(clearPrescription: true),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.background,
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        itemCount: chips.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          if (i == chips.length) {
            return GestureDetector(
              onTap: onClearAll,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            );
          }
          final chip = chips[i];
          return GestureDetector(
            onTap: chip.clear,
            child: Container(
              height: 32,
              padding: const EdgeInsets.only(left: 10, right: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryWash,
                border: Border.all(color: AppColors.primaryWashDeep),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 128),
                    child: Text(
                      chip.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '×',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
