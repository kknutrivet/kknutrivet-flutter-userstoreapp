import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../providers/app_providers.dart';
import '../../home/widgets/home_combos_and_rx.dart';
import '../widgets/catalogue_controls.dart';
import '../widgets/catalogue_sheets.dart';

export '../widgets/catalogue_controls.dart'
    show
        ProductFilter,
        productFilterProvider,
        productsListProvider,
        productFacetsProvider;

/// Exact replica of the website's mobile catalogue
/// (`src/app/products/ProductsClient.tsx` + `MobileCatalogueControls.tsx`).
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({
    super.key,
    this.initialAnimalType,
    this.initialCategory,
    this.initialSearch,
    this.initialDisease,
    this.initialSort,
  });

  final String? initialAnimalType;
  final String? initialCategory;
  final String? initialSearch;
  final String? initialDisease;
  final String? initialSort;

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  ScrollController? _scrollControllerInstance;
  ScrollController get _scrollController =>
      _scrollControllerInstance ??= ScrollController();
  bool _controlsVisible = true;
  bool _showBackToTop = false;
  double _previousScrollY = 0.0;
  double _scrollTravel = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollControllerInstance = ScrollController();
    _applyInitialFilters();
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
    final delta = currentY - _previousScrollY;
    _previousScrollY = currentY;

    final nextShowBackToTop = currentY > 280.0;
    var nextControlsVisible = _controlsVisible;

    if (currentY < 80.0) {
      _scrollTravel = 0.0;
      nextControlsVisible = true;
    } else if (delta != 0.0) {
      if (_scrollTravel != 0.0 && delta.sign != _scrollTravel.sign) {
        _scrollTravel = 0.0;
      }
      _scrollTravel += delta;
      if (_scrollTravel >= 12.0) {
        nextControlsVisible = false;
      } else if (_scrollTravel <= -8.0) {
        nextControlsVisible = true;
      }
    }

    if (nextShowBackToTop != _showBackToTop ||
        nextControlsVisible != _controlsVisible) {
      setState(() {
        _showBackToTop = nextShowBackToTop;
        _controlsVisible = nextControlsVisible;
      });
    }
    return false;
  }

  void _scrollToTop() {
    AppHaptics.tap();
    setState(() {
      _controlsVisible = true;
      _showBackToTop = false;
      _scrollTravel = 0.0;
      _previousScrollY = 0.0;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void didUpdateWidget(ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAnimalType != widget.initialAnimalType ||
        oldWidget.initialCategory != widget.initialCategory ||
        oldWidget.initialSearch != widget.initialSearch ||
        oldWidget.initialDisease != widget.initialDisease || oldWidget.initialSort != widget.initialSort) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(productFilterProvider.notifier).state = ProductFilter(
          animalType: widget.initialAnimalType,
          category: widget.initialCategory,
          search: widget.initialSearch,
          disease: widget.initialDisease,
          sort: widget.initialSort ?? 'relevance',
        );
      });
    }
  }

  void _applyInitialFilters() {
    if (widget.initialAnimalType != null ||
        widget.initialCategory != null ||
        widget.initialSearch != null ||
        widget.initialDisease != null || widget.initialSort != null) {
      Future.microtask(() {
        if (!mounted) return;
        final current = ref.read(productFilterProvider);
        if (current.animalType != widget.initialAnimalType ||
            current.category != widget.initialCategory ||
            current.search != widget.initialSearch ||
            current.disease != widget.initialDisease || current.sort != (widget.initialSort ?? 'relevance')) {
          ref.read(productFilterProvider.notifier).state = ProductFilter(
            animalType: widget.initialAnimalType,
            category: widget.initialCategory,
            search: widget.initialSearch,
            disease: widget.initialDisease,
          sort: widget.initialSort ?? 'relevance',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
              context.go('/home');
            }
          },
        ),
        title: Consumer(
          builder: (context, ref, _) {
            final filter = ref.watch(productFilterProvider);
            String title = 'All products';
            if (filter.search != null && filter.search!.isNotEmpty) {
              title = 'Results for "${filter.search}"';
            } else if (filter.disease != null && filter.disease!.isNotEmpty) {
              title = filter.animalType != null
                  ? '${filter.disease} for ${filter.animalType}'
                  : filter.disease!;
            } else if (filter.animalType != null && filter.category != null) {
              title = '${filter.category} for ${filter.animalType}';
            } else if (filter.animalType != null) {
              final animalLabel = filter.animalType == 'Dog'
                  ? 'Dog Products'
                  : filter.animalType == 'Cat'
                      ? 'Cat Products'
                      : filter.animalType == 'Cattle'
                          ? 'Cattle Products'
                          : '${filter.animalType} Products';
              title = animalLabel;
            } else if (filter.category != null) {
              title = filter.category!;
            }
            return Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              size: 22,
              color: AppColors.textPrimary,
            ),
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
      body: Consumer(
        builder: (context, ref, _) {
          final filter = ref.watch(productFilterProvider);
          final cartCount = ref.watch(cartCountProvider);
          final topToolbarClearance =
              125.0 + (filter.hasVisibleActiveChips ? 40.0 : 0.0);

          return NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CatalogueBody(
                  scrollController: _scrollController,
                  topPadding: topToolbarClearance,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      offset: _controlsVisible
                          ? Offset.zero
                          : const Offset(0, -1),
                      child: IgnorePointer(
                        ignoring: !_controlsVisible,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: _controlsVisible && _previousScrollY > 8
                                ? const [
                                    BoxShadow(
                                      color: Color(0x1417322B),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CatalogueHorizontalAnimalRail(),
                              CatalogueControlBar(
                                onOpenFilters: () =>
                                    showCatalogueFilterSheet(context),
                                onOpenSort: () =>
                                    showCatalogueSortSheet(context),
                              ),
                              CatalogueActiveChips(
                                onClearAll: () =>
                                    ref
                                        .read(productFilterProvider.notifier)
                                        .state = ProductFilter(),
                              ),
                            ],
                          ),
                        ),
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
                        child: _BackToTopButton(
                          key: const ValueKey('catalogue-back-to-top'),
                          onTap: _scrollToTop,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  const _BackToTopButton({super.key, required this.onTap});
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

class _CatalogueBody extends ConsumerWidget {
  const _CatalogueBody({
    required this.scrollController,
    required this.topPadding,
  });

  final ScrollController scrollController;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);

    if (filter.category == 'Combos') {
      final combosAsync = ref.watch(homeCombosProvider);
      return combosAsync.when(
        data: (rawCombos) {
          final list = rawCombos
              .where((c) => c.matchesAnimal(filter.animalType))
              .toList();
          if (list.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: _EmptyState(filter: filter),
            );
          }
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${list.length} care combos',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryWash,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Bundle & Save',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 290,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => AppFadeSlide(
                      delay: Duration(milliseconds: (i % 6) * 35),
                      child: HomeComboCard(combo: list[i]),
                    ),
                    childCount: list.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: const ProductGridSkeleton(itemCount: 4),
        ),
        error: (e, _) => Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(homeCombosProvider),
          ),
        ),
      );
    }

    final productsAsync = ref.watch(productsListProvider);

    return productsAsync.when(
      data: (raw) {
        final list = applyClientProductFilters(raw, filter);
        if (list.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: _EmptyState(filter: filter),
          );
        }
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topPadding)),
            SliverToBoxAdapter(
              child: _prescriptionSupportCard(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                child: Text(
                  '${list.length} products',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: productCardExtent(context),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => AppFadeSlide(
                    delay: Duration(milliseconds: (i % 6) * 35),
                    child: CompactProductCard(
                      product: list[i],
                      heroTag: 'product_image_${list[i].id}',
                    ),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const ProductGridSkeleton(itemCount: 8),
      ),
      error: (e, _) => Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(productsListProvider),
        ),
      ),
    );
  }

  Widget _prescriptionSupportCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDE4D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'PRESCRIPTION SUPPORT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Text('🪙 ', style: TextStyle(fontSize: 10)),
                    Text(
                      '+5% KK Coins',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Have a vet prescription?',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Photo from camera or gallery. Reviewed by our care team.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => context.push('/prescriptions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.file_upload_outlined, size: 15, color: Colors.white),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Upload prescription',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "No products match" empty state with Clear filters / Ask Dr. Paw /
/// Browse health concerns actions.
class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.filter});
  final ProductFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No products match',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try a different search term, remove a filter, or browse by health concern.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      ref.read(productFilterProvider.notifier).state =
                          ProductFilter(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Clear filters →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/vet'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: AppColors.borderStrong),
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '✦ Ask Dr. Paw for help',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/diseases'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: AppColors.borderStrong),
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Browse health concerns',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
