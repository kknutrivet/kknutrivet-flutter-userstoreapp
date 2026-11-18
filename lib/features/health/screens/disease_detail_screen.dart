import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/prescription_banner.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../home/screens/main_shell.dart';
import '../../products/widgets/catalogue_controls.dart' show AnimalSelectorRail;

final concernByNameProvider = FutureProvider.autoDispose
    .family<HealthConcern?, String>((ref, slug) async {
      final concerns = await ref
          .read(catalogServiceProvider)
          .fetchHealthConcerns();
      return concerns.where((c) => c.slug == slug).firstOrNull;
    });

final diseaseProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, name) {
      return ref.read(catalogServiceProvider).fetchProducts(disease: name);
    });

class DiseaseDetailScreen extends ConsumerStatefulWidget {
  const DiseaseDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<DiseaseDetailScreen> createState() =>
      _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends ConsumerState<DiseaseDetailScreen> {
  ScrollController? _scrollControllerInstance;
  ScrollController get _scrollController =>
      _scrollControllerInstance ??= ScrollController();

  String _selectedAnimal = 'All';
  String _sortBy = 'relevance';
  bool _inStockOnly = false;
  bool _under500 = false;
  bool _noRxOnly = false;

  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollControllerInstance = ScrollController();
  }

  @override
  void dispose() {
    _scrollControllerInstance?.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical || notification.depth != 0) {
      return false;
    }
    final currentY = notification.metrics.pixels.clamp(0.0, double.infinity);

    final nextShowBackToTop = currentY > 280.0;
    if (nextShowBackToTop != _showBackToTop) {
      setState(() => _showBackToTop = nextShowBackToTop);
    }
    return false;
  }

  void _scrollToTop() {
    AppHaptics.tap();
    setState(() {
      _showBackToTop = false;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Sort remedies by',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                for (final opt in [
                  ('relevance', 'Relevance'),
                  ('price-low', 'Price: Low to High'),
                  ('price-high', 'Price: High to Low'),
                  ('discount', 'Biggest Discount'),
                  ('name', 'Product Name: A to Z'),
                ])
                  ListTile(
                    title: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _sortBy == opt.$1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _sortBy == opt.$1
                            ? AppColors.primaryDeep
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: _sortBy == opt.$1
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryDeep,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      AppHaptics.selection();
                      setState(() => _sortBy = opt.$1);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _sortLabel(String sort) {
    switch (sort) {
      case 'price-low':
        return 'Price: Low to High';
      case 'price-high':
        return 'Price: High to Low';
      case 'discount':
        return 'Discount';
      case 'name':
        return 'Name: A-Z';
      default:
        return 'Sort: Relevance';
    }
  }

  bool _matchesAnimal(Product product, String animal) {
    final selected = animal.toLowerCase().trim();
    final targets = <String>{selected};
    if (selected == 'goat' || selected == 'goat/sheep') {
      targets.addAll({'goat', 'goat/sheep', 'sheep'});
    } else if (selected == 'exotic & small pets' || selected == 'exotic') {
      targets.addAll({'exotic', 'exotic & small pets', 'small pets'});
    }
    return product.animalTypes.any(
      (a) => targets.contains(a.toLowerCase().trim()),
    );
  }

  List<Product> _applyFilters(List<Product> allProducts) {
    var list = allProducts;
    if (_selectedAnimal != 'All') {
      list = list.where((p) => _matchesAnimal(p, _selectedAnimal)).toList();
    }
    if (_inStockOnly) {
      list = list.where((p) => p.inStock).toList();
    }
    if (_under500) {
      list = list.where((p) => p.price < 500).toList();
    }
    if (_noRxOnly) {
      list = list.where((p) => !p.requiresPrescription).toList();
    }

    final sorted = List<Product>.from(list);
    switch (_sortBy) {
      case 'price-low':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price-high':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'discount':
        sorted.sort((a, b) {
          final aSaving = (a.mrp != null && a.mrp! > a.price)
              ? ((a.mrp! - a.price) / a.mrp!)
              : 0.0;
          final bSaving = (b.mrp != null && b.mrp! > b.price)
              ? ((b.mrp! - b.price) / b.mrp!)
              : 0.0;
          return bSaving.compareTo(aSaving);
        });
        break;
      case 'name':
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      default:
        break;
    }
    return sorted;
  }

  int get _activeFilterCount =>
      (_selectedAnimal != 'All' ? 1 : 0) +
      (_inStockOnly ? 1 : 0) +
      (_under500 ? 1 : 0) +
      (_noRxOnly ? 1 : 0);

  void _showFilterSheet(BuildContext context, List<Product> allProducts) {
    String filterTab = 'animal';
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filteredCount = _applyFilters(allProducts).length;
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;
            const animals = [
              ('All', 'All Animals'),
              ('Dog', 'Dogs'),
              ('Cat', 'Cats'),
              ('Cattle', 'Cattle & Dairy'),
              ('Poultry', 'Poultry'),
              ('Goat/Sheep', 'Goats & Sheep'),
              ('Exotic & Small Pets', 'Exotic & Small Pets'),
            ];

            Widget optionTile({
              required String label,
              String? subtitle,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return InkWell(
                onTap: () {
                  AppHaptics.selection();
                  onTap();
                  setState(() {});
                  setSheetState(() {});
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryWashFaint
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryDeep
                          : const Color(0xFFE2EBE5),
                      width: selected ? 1.3 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryDeep
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryDeep
                                : const Color(0xFF94A3B8),
                            width: 1.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.sizeOf(ctx).height * 0.68,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REFINE REMEDIES',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Filters',
                                style: AppTheme.serif(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2EBE5)),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left rail
                        Container(
                          width: 132,
                          color: const Color(0xFFF6FAF7),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              for (final tab in [
                                ('animal', 'Animal type', _selectedAnimal != 'All' ? 1 : 0),
                                ('price', 'Price & Stock', (_inStockOnly ? 1 : 0) + (_under500 ? 1 : 0)),
                                ('rx', 'Prescription', _noRxOnly ? 1 : 0),
                              ])
                                InkWell(
                                  onTap: () =>
                                      setSheetState(() => filterTab = tab.$1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: filterTab == tab.$1
                                          ? Colors.white
                                          : Colors.transparent,
                                      border: Border(
                                        left: BorderSide(
                                          color: filterTab == tab.$1
                                              ? AppColors.primaryDeep
                                              : Colors.transparent,
                                          width: 3.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tab.$2,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: filterTab == tab.$1
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: filterTab == tab.$1
                                                  ? AppColors.primaryDeep
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        if (tab.$3 > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryDeep,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              '${tab.$3}',
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Right options pane
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(14),
                            children: [
                              if (filterTab == 'animal')
                                for (final a in animals)
                                  optionTile(
                                    label: a.$2,
                                    selected: _selectedAnimal == a.$1,
                                    onTap: () => _selectedAnimal = a.$1,
                                  )
                              else if (filterTab == 'price') ...[
                                optionTile(
                                  label: 'In stock only',
                                  subtitle:
                                      'Hide remedies that are currently sold out',
                                  selected: _inStockOnly,
                                  onTap: () => _inStockOnly = !_inStockOnly,
                                ),
                                optionTile(
                                  label: 'Under ₹500',
                                  subtitle:
                                      'Everyday care & affordable packs under ₹500',
                                  selected: _under500,
                                  onTap: () => _under500 = !_under500,
                                ),
                              ] else ...[
                                optionTile(
                                  label: 'All remedies (Rx & Non-Rx)',
                                  subtitle:
                                      'Show both OTC supplements and prescription medicines',
                                  selected: !_noRxOnly,
                                  onTap: () => _noRxOnly = false,
                                ),
                                optionTile(
                                  label: 'Non-Rx only (No prescription needed)',
                                  subtitle:
                                      'Instant checkout without uploading a vet slip',
                                  selected: _noRxOnly,
                                  onTap: () => _noRxOnly = true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      12 + bottomInset,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE2EBE5)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _clearAllFilters();
                              setSheetState(() {});
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Clear filters',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDeep,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Apply ($filteredCount ${filteredCount == 1 ? 'product' : 'products'})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
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
          },
        );
      },
    );
  }

  void _showSwitchConcernSheet(BuildContext context, String currentSlug) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final concernsAsync = ref.watch(
              FutureProvider.autoDispose((r) => r.read(catalogServiceProvider).fetchHealthConcerns()),
            );
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: EdgeInsets.only(bottom: bottomInset + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HEALTH CONCERNS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Switch health concern',
                                style: AppTheme.serif(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2EBE5)),
                  Flexible(
                    child: concernsAsync.when(
                      data: (concerns) => ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(14),
                        itemCount: concerns.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final item = concerns[i];
                          final active = item.slug == currentSlug;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(ctx);
                              if (!active) {
                                context.pushReplacement('/diseases/${item.slug}');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primaryWashFaint
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? AppColors.primaryDeep
                                      : const Color(0xFFE2EBE5),
                                  width: active ? 1.3 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: active
                                                ? FontWeight.w800
                                                : FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (item.description != null &&
                                            item.description!
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.description!.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    active
                                        ? Icons.check_circle_rounded
                                        : Icons.chevron_right_rounded,
                                    size: 18,
                                    color: active
                                        ? AppColors.primaryDeep
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final concernAsync = ref.watch(concernByNameProvider(widget.slug));
    final cartCount = ref.watch(cartCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
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
              context.go('/diseases');
            }
          },
        ),
        title: concernAsync.when(
          data: (concern) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'HEALTH CONCERN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                concern?.name ?? 'Health Concern',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          loading: () => const Text(
            'Health Concern',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          error: (error, stack) => const Text(
            'Health Concern',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Search remedies',
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
                    tooltip: 'Shopping Cart',
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
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Stack(
          children: [
            concernAsync.when(
              data: (concern) {
                if (concern == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Health concern not found',
                        description:
                            'It may have moved, or it may not be available right now.',
                        actionLabel: 'Browse Health Concerns',
                        onAction: () => context.go('/diseases'),
                      ),
                    ),
                  );
                }
                return _content(concern, cartCount);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: ProductGridSkeleton(itemCount: 4),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load guidance',
                    description: e.toString(),
                    actionLabel: 'Retry',
                    onAction: () =>
                        ref.invalidate(concernByNameProvider(widget.slug)),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom:
                  (cartCount > 0 ? 84 : 20) +
                  MediaQuery.paddingOf(context).bottom,
              child: IgnorePointer(
                ignoring: !_showBackToTop,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  scale: _showBackToTop ? 1.0 : 0.72,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    opacity: _showBackToTop ? 1.0 : 0.0,
                    child: _BackToTopButton(onTap: _scrollToTop),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
              child: IgnorePointer(
                ignoring: cartCount == 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  offset: cartCount > 0 ? Offset.zero : const Offset(0, 1.4),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    opacity: cartCount > 0 ? 1.0 : 0.0,
                    child: CartFloatingBar(count: cartCount, total: cartTotal),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(HealthConcern concern, int cartCount) {
    final productsAsync = ref.watch(diseaseProductsProvider(concern.name));

    return productsAsync.when(
      data: (allProducts) {
        final filteredProducts = _applyFilters(allProducts);

        return SafeArea(
          top: false,
          left: false,
          right: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(concernByNameProvider(widget.slug));
              ref.invalidate(diseaseProductsProvider(concern.name));
              await ref.read(diseaseProductsProvider(concern.name).future);
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Animal selector — same image-circle style as the catalogue
                SliverToBoxAdapter(
                  child: AnimalSelectorRail(
                    selectedAnimal: _selectedAnimal == 'All'
                        ? null
                        : _selectedAnimal,
                    onSelected: (animal) {
                      AppHaptics.selection();
                      setState(() => _selectedAnimal = animal ?? 'All');
                    },
                  ),
                ),

                // Catalogue Controls Row: Sort & Quick filters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Filter Button Pill (opens 2-pane split Filter bottom sheet)
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showFilterSheet(context, allProducts),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _activeFilterCount > 0
                                    ? AppColors.primaryWash
                                    : Colors.white,
                                border: Border.all(
                                  color: _activeFilterCount > 0
                                      ? AppColors.primaryDeep
                                      : const Color(0xFFD9E2DC),
                                  width: _activeFilterCount > 0 ? 1.2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: AppColors.primaryDeep,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _activeFilterCount > 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: _activeFilterCount > 0
                                          ? AppColors.primaryDeep
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (_activeFilterCount > 0) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDeep,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$_activeFilterCount',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Sort Button Pill
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _showSortSheet(context),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _sortBy != 'relevance'
                                    ? AppColors.primaryWash
                                    : Colors.white,
                                border: Border.all(
                                  color: _sortBy != 'relevance'
                                      ? AppColors.primaryDeep
                                      : const Color(0xFFD9E2DC),
                                  width: _sortBy != 'relevance' ? 1.2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.sort_rounded,
                                    size: 14,
                                    color: AppColors.primaryDeep,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _sortLabel(_sortBy),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: _sortBy != 'relevance'
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: _sortBy != 'relevance'
                                          ? AppColors.primaryDeep
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Quick filter: In stock
                          _quickFilterChip(
                            label: 'In stock',
                            active: _inStockOnly,
                            onTap: () =>
                                setState(() => _inStockOnly = !_inStockOnly),
                          ),

                          // Quick filter: Under ₹500
                          _quickFilterChip(
                            label: 'Under ₹500',
                            active: _under500,
                            onTap: () => setState(() => _under500 = !_under500),
                          ),

                          // Quick filter: Non-Rx
                          _quickFilterChip(
                            label: 'Non-Rx',
                            active: _noRxOnly,
                            onTap: () => setState(() => _noRxOnly = !_noRxOnly),
                          ),

                          // Quick filter: Best Offers
                          _quickFilterChip(
                            label: 'Best offers',
                            active: _sortBy == 'discount',
                            onTap: () => setState(
                              () => _sortBy = _sortBy == 'discount'
                                  ? 'relevance'
                                  : 'discount',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Prescription upload banner
                const SliverToBoxAdapter(child: PrescriptionBanner()),

                // Products count + Switch concern row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${filteredProducts.length} ${filteredProducts.length == 1 ? 'remedy' : 'remedies'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_hasActiveFilters) ...[
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _clearAllFilters,
                                child: const Text(
                                  'Reset filters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () =>
                              _showSwitchConcernSheet(context, concern.slug),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFD9E2DC),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Switch concern',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 15,
                                  color: AppColors.primaryDeep,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Products Grid
                if (filteredProducts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 36,
                      ),
                      child: AppEmptyState(
                        icon: Icons.pets_outlined,
                        title: 'No remedies match filters',
                        description:
                            'Try resetting animal type or filters to see all available care remedies for ${concern.name}.',
                        actionLabel: 'Reset All Filters',
                        onAction: _clearAllFilters,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: productCardExtent(context),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => CompactProductCard(
                          product: filteredProducts[i],
                          variant: CompactCardVariant.catalogue,
                        ),
                        childCount: filteredProducts.length,
                      ),
                    ),
                  ),

                // Vet Advice Banner
                SliverToBoxAdapter(
                  child: _VetAdviceBanner(
                    onConsult: () {
                      AppHaptics.light();
                      context.push('/consultations');
                    },
                    onAskDrPaw: () {
                      AppHaptics.light();
                      context.push('/vet');
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: cartCount > 0 ? 96 : 36),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: ProductGridSkeleton(itemCount: 4),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load products',
            description: e.toString(),
            actionLabel: 'Retry',
            onAction: () =>
                ref.invalidate(diseaseProductsProvider(concern.name)),
          ),
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedAnimal != 'All' ||
      _inStockOnly ||
      _under500 ||
      _noRxOnly ||
      _sortBy != 'relevance';

  void _clearAllFilters() {
    setState(() {
      _selectedAnimal = 'All';
      _inStockOnly = false;
      _under500 = false;
      _noRxOnly = false;
      _sortBy = 'relevance';
    });
  }

  Widget _quickFilterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryWash : Colors.white,
            border: Border.all(
              color: active ? AppColors.primaryDeep : const Color(0xFFD9E2DC),
              width: active ? 1.2 : 1,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active) ...[
                const Icon(Icons.check, size: 12, color: AppColors.primaryDeep),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active
                      ? AppColors.primaryDeep
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  const _BackToTopButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back to top',
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC5D8CE), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E17322B),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 24,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VetAdviceBanner extends StatelessWidget {
  const _VetAdviceBanner({required this.onConsult, required this.onAskDrPaw});

  final VoidCallback onConsult;
  final VoidCallback onAskDrPaw;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      child: AppCard(
        variant: AppCardVariant.tinted,
        backgroundColor: AppColors.homeHero,
        borderColor: AppColors.borderWarm,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.primaryDeep,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VETERINARY ADVICE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      Text(
                        'Symptoms persistent or worsening?',
                        style: AppTheme.serif(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'For severe symptoms, contact a veterinarian immediately. Start a Vet Care Chat to speak with our veterinary team; Dr. Paw AI provides general information, not a diagnosis.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () => context.push('/consultations'),
              child: const Text('Chat with a veterinarian'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Care team chat',
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 15,
                    ),
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.sm,
                    onPressed: onConsult,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Dr. Paw (AI)',
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
