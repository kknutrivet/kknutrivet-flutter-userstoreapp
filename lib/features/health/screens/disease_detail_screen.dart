import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../home/screens/main_shell.dart';

final concernByNameProvider =
    FutureProvider.autoDispose.family<HealthConcern?, String>((ref, slug) async {
  final concerns =
      await ref.read(catalogServiceProvider).fetchHealthConcerns();
  return concerns.where((c) => c.slug == slug).firstOrNull;
});

final diseaseProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, name) {
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
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryDeep, size: 20)
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

  String _animalEmoji(String animal) {
    switch (animal.toLowerCase()) {
      case 'dog':
        return '🐶';
      case 'cat':
        return '🐱';
      case 'cattle':
        return '🐮';
      case 'poultry':
        return '🐔';
      case 'goat':
        return '🐐';
      default:
        return '🐾';
    }
  }

  List<Product> _applyFilters(List<Product> allProducts) {
    var list = allProducts;
    if (_selectedAnimal != 'All') {
      list = list
          .where((p) => p.animalTypes.any(
              (a) => a.toLowerCase() == _selectedAnimal.toLowerCase()))
          .toList();
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
        sorted.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      default:
        break;
    }
    return sorted;
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
              bottom: cartCount > 0 ? 84 : 20,
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
                    child: CartFloatingBar(
                      count: cartCount,
                      total: cartTotal,
                    ),
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

        final animalOptions = [
          'All',
          'Dog',
          'Cat',
          'Cattle',
          'Poultry',
          'Goat',
        ];

        return RefreshIndicator(
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
              // Concern Header
              SliverToBoxAdapter(
                child: _DetailHeader(concern: concern),
              ),

              // Prescription Support Card
              SliverToBoxAdapter(
                child: _prescriptionSupportCard(context),
              ),

              // Catalogue Controls Row: Sort & Quick filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Sort Button Pill
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showSortSheet(context),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                const Icon(Icons.sort_rounded,
                                    size: 14, color: AppColors.primaryDeep),
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
                          onTap: () =>
                              setState(() => _under500 = !_under500),
                        ),

                        // Quick filter: Non-Rx
                        _quickFilterChip(
                          label: 'Non-Rx',
                          active: _noRxOnly,
                          onTap: () =>
                              setState(() => _noRxOnly = !_noRxOnly),
                        ),

                        // Quick filter: Best Offers
                        _quickFilterChip(
                          label: 'Best offers',
                          active: _sortBy == 'discount',
                          onTap: () => setState(() => _sortBy =
                              _sortBy == 'discount' ? 'relevance' : 'discount'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Products count row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredProducts.length} ${filteredProducts.length == 1 ? 'remedy' : 'remedies'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_hasActiveFilters)
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
                  ),
                ),
              ),

              // Animal selector choice chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                  child: Row(
                    children: animalOptions.map((animal) {
                      final selected = _selectedAnimal == animal;
                      final count = animal == 'All'
                          ? allProducts.length
                          : allProducts
                              .where((p) => p.animalTypes.any((a) =>
                                  a.toLowerCase() == animal.toLowerCase()))
                              .length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Text(
                            _animalEmoji(animal),
                            style: const TextStyle(fontSize: 13),
                          ),
                          selected: selected,
                          label: Text('$animal ($count)'),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppColors.primaryDeep
                                : AppColors.textSecondary,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFFE3F3EC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.primaryDeep
                                  : const Color(0xFFD9E2DC),
                              width: selected ? 1.2 : 1,
                            ),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) {
                            AppHaptics.selection();
                            setState(() => _selectedAnimal = animal);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Products Grid
              if (filteredProducts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 36),
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

  Widget _prescriptionSupportCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            AppHaptics.light();
            context.push('/prescriptions');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF2F9F5), Color(0xFFFDFAF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD6EAE0), width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0817322B),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBCE3CE)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Have a vet prescription?',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFFFDE68A), width: 0.8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🪙 ', style: TextStyle(fontSize: 8)),
                                Text(
                                  '+5% Coins',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Upload photo • Care team fulfills remedies',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Upload CTA button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeep,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2417322B),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Upload',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
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

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.concern});
  final HealthConcern concern;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE8F6EF),
              Color(0xFFFBFDFB),
              Color(0xFFFFF7ED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6EAE0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C17322B),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: concern.imageUrl != null &&
                        concern.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: concern.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => _fallbackIcon(),
                      )
                    : _fallbackIcon(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFBFE0D0), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 11, color: AppColors.primaryDeep),
                        SizedBox(width: 4),
                        Text(
                          'VET-CURATED CONCERN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    concern.name,
                    style: AppTheme.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (concern.description != null &&
                      concern.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      concern.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
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

  Widget _fallbackIcon() {
    return Container(
      color: AppColors.primaryWash,
      child: Center(
        child: Text(
          concern.icon != null && concern.icon!.isNotEmpty
              ? concern.icon!
              : '🐾',
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }
}

class _VetAdviceBanner extends StatelessWidget {
  const _VetAdviceBanner({
    required this.onConsult,
    required this.onAskDrPaw,
  });

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
              'For severe symptoms, contact a veterinarian. Care team chat offers support; a booked vet consultation is a separate service. Dr. Paw AI provides general information, not a diagnosis.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () => context.push('/consultations/book'),
              child: const Text('Book a vet consultation'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Care team chat',
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 15),
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
