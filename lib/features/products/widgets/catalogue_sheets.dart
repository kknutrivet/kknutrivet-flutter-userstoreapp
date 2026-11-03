import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/category.dart';
import '../../../models/product_facets.dart';
import '../../../providers/app_providers.dart';
import 'catalogue_controls.dart';

/// Website sort contract (`sortProducts` in presenters/buildProductList.ts +
/// the `/api/products` route): kebab-case values; only `newest`,
/// `price_low`, `price_high` and `name_asc` reach the API — `relevance` and
/// `discount` are applied client-side.
const catalogueSortOptions = [
  (
    value: 'relevance',
    label: 'Discover',
    description: 'A rotating mix across animals and care categories',
  ),
  (
    value: 'newest',
    label: 'Newest',
    description: 'Recently added products first',
  ),
  (
    value: 'price-low',
    label: 'Price: Low to High',
    description: 'Lowest-priced products first',
  ),
  (
    value: 'price-high',
    label: 'Price: High to Low',
    description: 'Highest-priced products first',
  ),
  (
    value: 'discount',
    label: 'Highest Discount',
    description: 'Products with the strongest savings first',
  ),
  (
    value: 'name',
    label: 'Name A–Z',
    description: 'Browse the catalogue alphabetically',
  ),
];

void showCatalogueSortSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const CatalogueSortSheet(),
  );
}

void showCatalogueFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const CatalogueFilterSheet(),
  );
}

class CatalogueSortSheet extends ConsumerWidget {
  const CatalogueSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(productFilterProvider).sort;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 44,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ARRANGE PRODUCTS',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'How should we show them?',
                        style: AppTheme.serif(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Close sorting options',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: catalogueSortOptions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final opt = catalogueSortOptions[i];
                final selected = current == opt.value;
                return Material(
                  color: selected ? AppColors.primaryWash : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      final f = ref.read(productFilterProvider);
                      ref.read(productFilterProvider.notifier).state =
                          f.copyWith(sort: opt.value);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.borderStrong,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.description,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

/// Tabbed mobile filter sheet: Category | Animal | Health concerns | Price |
/// More — with search-across-filters and `Apply · View N products`.
class CatalogueFilterSheet extends ConsumerStatefulWidget {
  const CatalogueFilterSheet({super.key});

  @override
  ConsumerState<CatalogueFilterSheet> createState() =>
      _CatalogueFilterSheetState();
}

class _CatalogueFilterSheetState extends ConsumerState<CatalogueFilterSheet> {
  static const _tabs = [
    ('category', 'Category'),
    ('animal', 'Animal'),
    ('health', 'Health concerns'),
    ('price', 'Price'),
    ('more', 'More'),
  ];

  String _tab = 'category';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final facetsAsync = ref.watch(productFacetsProvider);
    final facets = facetsAsync.value;
    final count = ref.watch(productsListProvider).maybeWhen(
          data: (raw) => applyClientProductFilters(raw, filter).length,
          orElse: () => 0,
        );
    final bottomInset = MediaQuery.of(context).padding.bottom;

    bool matches(String label) =>
        _search.trim().isEmpty ||
        label.toLowerCase().contains(_search.trim().toLowerCase());

    Widget choice({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      int? count,
      double indent = 0.0,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.only(
              left: 8 + indent,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.background),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.stepperBorderActive,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: selected
                      ? const Text(
                          '✓',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: indent > 0 ? 11.5 : 12,
                      fontWeight: indent > 0 && selected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    List<Widget> options() {
      final notifier = ref.read(productFilterProvider.notifier);
      switch (_tab) {
        case 'category':
          final cats = ref.watch(activeCategoriesProvider);
          final allCategories =
              ref.watch(categoriesProvider).valueOrNull ?? const <ProductCategory>[];
          return [
            if (matches('All categories'))
              choice(
                label: 'All categories',
                selected: filter.category == null && filter.subCategory == null,
                onTap: () => notifier.state = filter.copyWith(
                  clearCategory: true,
                  clearSubCategory: true,
                ),
                count: count,
              ),
            for (final c in cats.where(matches)) ...[
              choice(
                label: c,
                selected: filter.category == c && filter.subCategory == null,
                onTap: () => notifier.state =
                    (filter.category == c && filter.subCategory == null)
                        ? filter.copyWith(
                            clearCategory: true,
                            clearSubCategory: true,
                          )
                        : filter.copyWith(
                            category: c,
                            clearSubCategory: true,
                          ),
                count: facets?.categoryCounts[c],
              ),
              if (filter.category == c || _search.trim().isNotEmpty)
                ...() {
                  final parentObj = allCategories.firstWhere(
                    (cat) =>
                        cat.name.toLowerCase() == c.toLowerCase() &&
                        !cat.isSubcategory,
                    orElse: () => const ProductCategory(
                      id: '',
                      name: '',
                      slug: '',
                    ),
                  );
                  if (parentObj.id.isEmpty) return <Widget>[];
                  final subcats = allCategories
                      .where(
                        (cat) =>
                            cat.active && cat.parentId == parentObj.id,
                      )
                      .toList();
                  return subcats.where((sc) => matches(sc.name)).map(
                    (sc) => choice(
                      label: '↳ ${sc.name}',
                      selected:
                          filter.category == c && filter.subCategory == sc.name,
                      indent: 16.0,
                      onTap: () {
                        if (filter.category == c &&
                            filter.subCategory == sc.name) {
                          notifier.state =
                              filter.copyWith(clearSubCategory: true);
                        } else {
                          notifier.state = filter.copyWith(
                            category: c,
                            subCategory: sc.name,
                          );
                        }
                      },
                    ),
                  );
                }(),
            ],
          ];
        case 'animal':
          final hidden =
              ref.watch(storeSettingsProvider).valueOrNull?.hiddenCategories ?? const [];
          const allAnimals = [
            'Dog',
            'Cat',
            'Cattle',
            'Poultry',
            'Goat/Sheep',
            'Exotic & Small Pets',
          ];
          final animals = allAnimals.where((a) {
            final aLower = a.toLowerCase();
            return !hidden.any((h) => h.toLowerCase().trim() == aLower);
          }).toList();
          const labels = {
            'Dog': 'Dogs',
            'Cat': 'Cats',
            'Goat/Sheep': 'Goats & Sheep',
            'Exotic & Small Pets': 'Exotic & Small Pets',
          };
          return [
            if (matches('All animals'))
              choice(
                label: 'All animals',
                selected: filter.animalType == null,
                onTap: () => notifier.state =
                    filter.copyWith(clearAnimalType: true),
              ),
            for (final a in animals.where((a) => matches(labels[a] ?? a)))
              choice(
                label: labels[a] ?? a,
                selected: filter.animalType == a,
                onTap: () => notifier.state = filter.animalType == a
                    ? filter.copyWith(clearAnimalType: true)
                    : filter.copyWith(animalType: a),
                count: facets?.animalTypeCounts[a],
              ),
          ];
        case 'health':
          final opts = (facets?.diseaseOptions ?? const <DiseaseOption>[])
              .where((o) => matches(o.name))
              .toList();
          if (opts.isEmpty) {
            return [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 32),
                child: Text(
                  'No matching health concerns',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ];
          }
          return [
            for (final o in opts)
              choice(
                label: o.name,
                selected: filter.disease == o.name,
                onTap: () => notifier.state = filter.disease == o.name
                    ? filter.copyWith(clearDisease: true)
                    : filter.copyWith(disease: o.name),
                count: o.count,
              ),
          ];
        case 'price':
          const prices = [
            ('', 'Any price'),
            ('under-500', 'Under ₹500'),
            ('500-1000', '₹500–₹1,000'),
            ('over-1000', 'Above ₹1,000'),
          ];
          return [
            for (final p in prices.where((p) => matches(p.$2)))
              choice(
                label: p.$2,
                selected: (filter.priceRange ?? '') == p.$1,
                onTap: () => notifier.state = p.$1.isEmpty
                    ? filter.copyWith(clearPriceRange: true)
                    : filter.copyWith(priceRange: p.$1),
              ),
          ];
        default:
          return [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => notifier.state = filter.copyWith(
                      inStockOnly: !filter.inStockOnly,
                    ),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderStrong),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'In stock only',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: filter.inStockOnly,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => notifier.state =
                                filter.copyWith(inStockOnly: v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PRESCRIPTION',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final opt in const [
                    (null, 'All products'),
                    ('not-required', 'No prescription'),
                    ('required', 'Prescription required'),
                  ])
                    GestureDetector(
                      onTap: () => notifier.state = opt.$1 == null
                          ? filter.copyWith(clearPrescription: true)
                          : filter.copyWith(prescription: opt.$1),
                      child: Container(
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: filter.prescription == opt.$1
                                ? AppColors.primary
                                : AppColors.borderStrong,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: filter.prescription == opt.$1
                              ? AppColors.primaryWash
                              : Colors.white,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          opt.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ];
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 44,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderStrong),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Close filter panel',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search across filters…',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 108,
                      color: AppColors.background,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final t in _tabs)
                            GestureDetector(
                              onTap: () => setState(() {
                                _tab = t.$1;
                                _search = '';
                                _searchController.clear();
                              }),
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 20,
                                    ),
                                    color: _tab == t.$1
                                        ? Colors.white
                                        : Colors.transparent,
                                    child: Text(
                                      t.$2,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _tab == t.$1
                                            ? AppColors.primaryDeep
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  if (_tab == t.$1)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 4,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(6),
                        children: options(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: filter.hasAny
                          ? () => ref
                              .read(productFilterProvider.notifier)
                              .state = ProductFilter()
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'Clear filters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(
                        'Apply · View $count product${count == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
