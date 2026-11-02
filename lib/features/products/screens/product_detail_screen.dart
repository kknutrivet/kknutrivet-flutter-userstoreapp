import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/combo_details_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../../models/delivery.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../prescriptions/screens/prescriptions_screen.dart'
    show prescriptionsProvider;
import '../../vet/widgets/dr_paw_companion_sheet.dart';
import '../widgets/product_description_renderer.dart';

/// Exact replica of the website's mobile product detail page
/// (`src/app/products/[id]/ProductDetailClient.tsx`):
/// back-title-favorite-share-cart app bar, 4/3 gallery with lightbox,
/// Ask Dr. Paw top pill, fact chips, wash price block, variant grid,
/// 2x2 product facts grid, bulk quantity discount tiers, stock stepper,
/// pincode delivery check, notify-me alert, Rx card, recommended care bundles,
/// helps-with concerns, structured description accordions, Dr. Paw companion
/// prompt card, confidence strip, Rx/Consult support banners, related grid,
/// and the fixed Add-to-Cart / live stepper / Buy-Now bar.
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, id) {
  return ref.read(catalogServiceProvider).fetchProduct(id);
});

final relatedProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((
  ref,
  productId,
) async {
  final results = await ref
      .read(catalogServiceProvider)
      .fetchProducts(relatedTo: productId, limit: 10);
  return results
      .where((p) => p.id != productId && p.inStock)
      .toList();
});

final _treatsProvider =
    FutureProvider.autoDispose.family<List<HealthConcern>, Product>((
  ref,
  product,
) async {
  if (product.diseases.isEmpty) return const [];
  final concerns =
      await ref.read(catalogServiceProvider).fetchHealthConcerns();
  final names = product.diseases.map((d) => d.toLowerCase()).toSet();
  return concerns
      .where((c) =>
          names.contains(c.name.toLowerCase()) ||
          names.contains(c.slug.toLowerCase()))
      .toList();
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedVariantId;
  int _quantity = 1;
  bool _initializedForProduct = false;
  int _imagePage = 0;
  bool _adding = false;
  bool _savingAlert = false;
  bool _alertSaved = false;
  final _pageController = PageController();
  final _bundleSectionKey = GlobalKey();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ProductVariant? _resolveVariant(Product product) {
    if (product.variants.isEmpty) return null;
    if (_selectedVariantId != null) {
      for (final v in product.variants) {
        if (v.id == _selectedVariantId) return v;
      }
    }
    if (product.size?.isNotEmpty == true && _selectedVariantId == null) {
      return null;
    }
    return product.variants.firstWhere(
      (v) => v.stock > 0,
      orElse: () => product.variants.first,
    );
  }

  void _ensureInitialDefaults(Product product) {
    if (_initializedForProduct) return;
    _initializedForProduct = true;
    if (product.variants.isNotEmpty &&
        (product.size == null || product.size!.isEmpty)) {
      final defaultVar = product.variants.firstWhere(
        (v) => v.stock > 0,
        orElse: () => product.variants.first,
      );
      _selectedVariantId = defaultVar.id;
    }
    final minQty = product.minQtyFor(_resolveVariant(product));
    if (_quantity < minQty) {
      _quantity = minQty;
    }
  }

  void _scrollToBundles() {
    final ctx = _bundleSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.id));
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        data: (product) {
          _ensureInitialDefaults(product);
          final selectedVariant = _resolveVariant(product);
          final minQty = product.minQtyFor(selectedVariant);
          final cartQty = ref.watch(
            cartQuantityProvider((product.id, selectedVariant?.id)),
          );
          final effectiveQty = cartQty > 0
              ? cartQty
              : (_quantity < minQty ? minQty : _quantity);

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(productDetailProvider(widget.id));
                  ref.invalidate(relatedProductsProvider(product.id));
                  ref.invalidate(homeCombosProvider);
                  await ref.read(productDetailProvider(widget.id).future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _appBar(context, ref, product, cartCount),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _GalleryCard(
                          product: product,
                          controller: _pageController,
                          page: _imagePage,
                          onPage: (i) => setState(() => _imagePage = i),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _DetailsCard(
                          product: product,
                          selectedVariantId: selectedVariant?.id,
                          quantity: effectiveQty,
                          cartQuantity: cartQty,
                          onVariant: (id) {
                            final nextVar = id == null
                                ? null
                                : product.variants
                                    .where((v) => v.id == id)
                                    .firstOrNull;
                            final nextMin = product.minQtyFor(nextVar);
                            final nextCartQty = ref.read(
                              cartQuantityProvider((product.id, nextVar?.id)),
                            );
                            setState(() {
                              _selectedVariantId = id;
                              _quantity =
                                  nextCartQty > 0 ? nextCartQty : nextMin;
                            });
                          },
                          onQuantity: (q) async {
                            if (cartQty > 0) {
                              final nextCartQty = q < minQty ? 0 : q;
                              setState(() {
                                _quantity =
                                    nextCartQty > 0 ? nextCartQty : minQty;
                              });
                              try {
                                Haptics.tap();
                                await ref
                                    .read(cartProvider.notifier)
                                    .setQuantity(
                                      productId: product.id,
                                      variantId: selectedVariant?.id,
                                      quantity: nextCartQty,
                                    );
                                if (context.mounted) {
                                  showToast(nextCartQty == 0
                                      ? '${product.name} removed from cart'
                                      : 'Cart updated');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  showToast(e.toString(), isError: true);
                                }
                              }
                            } else {
                              final clamped = q < minQty ? minQty : q;
                              setState(() => _quantity = clamped);
                            }
                          },
                          savingAlert: _savingAlert,
                          alertSaved: _alertSaved,
                          onNotifyMe: () => _saveStockAlert(product),
                          onScrollToBundles: _scrollToBundles,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      key: _bundleSectionKey,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: PdpComboBundleSection(product: product),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _TreatsCard(product: product),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _DescriptionCard(product: product),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _AskDrPawCompanionCard(product: product),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _ConfidenceStrip(),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _SupportBannersRow(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _RelatedCard(product: product),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 108 + MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                  ],
                ),
              ),
              _BuyBar(
                product: product,
                selectedVariantId: selectedVariant?.id,
                quantity: effectiveQty,
                adding: _adding,
                onAdd: _addToCart,
                onBuyNow: _buyNow,
                onScrollToBundles: _scrollToBundles,
              ),
            ],
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
          ),
          body: const LoadingView(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
          ),
          body: ErrorView(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(productDetailProvider(widget.id)),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    if (_adding) return;
    final selectedVariant = _resolveVariant(product);
    final minQty = product.minQtyFor(selectedVariant);
    final qtyToAdd = _quantity < minQty ? minQty : _quantity;
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).addItem(
            productId: product.id,
            variantId: selectedVariant?.id,
            quantity: qtyToAdd,
            product: product,
            variant: selectedVariant,
          );
      Haptics.success();
      AnalyticsService.instance.logAddToCart(
        itemId: product.id,
        itemName: product.name,
        itemCategory: product.category,
        price: selectedVariant?.price ?? product.effectivePrice,
        quantity: qtyToAdd,
      );
      if (!mounted) return;
      if (product.requiresPrescription) {
        _openRxSheet(product);
      } else {
        showToast('Added to cart');
      }
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _buyNow(Product product) async {
    final selectedVariant = _resolveVariant(product);
    final inCartQty = ref.read(
      cartQuantityProvider((product.id, selectedVariant?.id)),
    );
    if (inCartQty <= 0) {
      await _addToCart(product);
    }
    if (mounted) context.push('/cart');
  }

  Future<void> _saveStockAlert(Product product) async {
    if (ref.read(authProvider).value == null) {
      context.push('/login');
      return;
    }
    setState(() {
      _savingAlert = true;
      _alertSaved = false;
    });
    try {
      await ref
          .read(catalogServiceProvider)
          .saveStockAlert(product.id);
      if (mounted) {
        setState(() => _alertSaved = true);
        showToast('Stock alert saved.');
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('401') ||
            e.toString().toLowerCase().contains('unauthor')) {
          context.push('/login');
        } else {
          showToast(e.toString(), isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => _savingAlert = false);
    }
  }

  void _openRxSheet(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RxSheet(product: product),
    );
  }

  Widget _appBar(
    BuildContext context,
    WidgetRef ref,
    Product product,
    int cartCount,
  ) {
    final isFavorite = ref.watch(
      wishlistProvider.select((s) => s.value?.contains(product.id) ?? false),
    );

    return SliverAppBar(
      pinned: true,
      toolbarHeight: 60,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
      title: Row(
        children: [
          _circleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => context.pop(),
            semantics: 'Go back',
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _circleButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor:
                isFavorite ? AppColors.favoriteRed : AppColors.textPrimary,
            onTap: () {
              Haptics.tap();
              ref.read(wishlistProvider.notifier).toggle(product.id);
            },
            semantics: isFavorite
                ? 'Remove ${product.name} from wishlist'
                : 'Add ${product.name} to wishlist',
          ),
          _circleButton(
            icon: Icons.share_outlined,
            onTap: () => AppShare.shareProduct(context, product),
            semantics: 'Share ${product.name}',
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _circleButton(
                icon: Icons.shopping_cart_outlined,
                onTap: () => context.push('/cart'),
                semantics:
                    cartCount > 0 ? 'Cart, $cartCount items' : 'Cart',
              ),
              if (cartCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: IgnorePointer(
                    child: Container(
                      height: 18,
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String semantics,
    Color? iconColor,
  }) {
    return Semantics(
      button: true,
      label: semantics,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                icon,
                size: 19,
                color: iconColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gallery card: 4/3 swipe view, arrows, counter + zoom chips, thumbnails.
class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.product,
    required this.controller,
    required this.page,
    required this.onPage,
  });
  final Product product;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPage;

  List<String> get images => product.images.isNotEmpty
      ? product.images
      : [if (product.image != null) product.image!];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderWarm),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (images.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (ctx) => _Lightbox(
                    images: images,
                    initial: page,
                    name: product.name,
                  ),
                );
              }
            },
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryWashFaint,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (images.isEmpty)
                      const Center(
                        child: Icon(
                          Icons.medication_outlined,
                          size: 70,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      PageView.builder(
                        controller: controller,
                        itemCount: images.length,
                        onPageChanged: onPage,
                        itemBuilder: (context, i) {
                          final cover = ProductImageCover(
                            imageUrl: images[i],
                            borderRadius: BorderRadius.zero,
                            innerPadding: const EdgeInsets.all(12),
                            showPlaceholderOnLoading: false,
                          );
                          if (i == 0) {
                            return Hero(
                              tag: 'product_image_${product.id}',
                              child: cover,
                            );
                          }
                          return cover;
                        },
                      ),
                    if (product.offerLabel != null)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.offerLabel!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    if (images.length > 1 && page > 0)
                      _arrow(context, Icons.chevron_left_rounded, -1),
                    if (images.length > 1 && page < images.length - 1)
                      _arrow(context, Icons.chevron_right_rounded, 1),
                    if (images.length > 1)
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${page + 1}/${images.length} · Swipe',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (images.isNotEmpty)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to zoom',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length > 4 ? 5 : images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 4 && images.length > 4) {
                    return GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (ctx) => _Lightbox(
                          images: images,
                          initial: 4,
                          name: product.name,
                        ),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.homeCanvas,
                          border: Border.all(
                            color: AppColors.borderWarm,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${images.length - 4}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }
                  final selected = i == page;
                  return GestureDetector(
                    onTap: () {
                      controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                      onPage(i);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primaryWashDeep,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AppNetworkImage(
                        imageUrl: images[i],
                        fit: BoxFit.contain,
                        memCacheWidth: 200,
                        enableManualRetry: false,
                        fallbackIcon: Icons.pets,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _arrow(BuildContext context, IconData icon, int dir) {
    final isLeft = dir < 0;
    return Positioned(
      left: isLeft ? 8 : null,
      right: isLeft ? null : 8,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            controller.animateToPage(
              page + dir,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }
}

class _Lightbox extends StatefulWidget {
  const _Lightbox({
    required this.images,
    required this.initial,
    required this.name,
  });
  final List<String> images;
  final int initial;
  final String name;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late int _page = widget.initial;
  late final PageController _controller =
      PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => InteractiveViewer(
              child: Center(
                child: AppNetworkImage(
                  imageUrl: widget.images[i],
                  fit: BoxFit.contain,
                  memCacheWidth: 1200,
                  fallbackIcon: Icons.pets,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_page + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Details card: Ask Dr. Paw pill, chips, brand, serif title + share,
/// wash price block, purpose, variant grid, 2x2 facts grid, bulk quantity
/// discount ladder, stock stepper, pincode check, notify-me, Rx card.
class _DetailsCard extends ConsumerWidget {
  const _DetailsCard({
    required this.product,
    required this.selectedVariantId,
    required this.quantity,
    required this.cartQuantity,
    required this.onVariant,
    required this.onQuantity,
    required this.savingAlert,
    required this.alertSaved,
    required this.onNotifyMe,
    required this.onScrollToBundles,
  });
  final Product product;
  final String? selectedVariantId;
  final int quantity;
  final int cartQuantity;
  final ValueChanged<String?> onVariant;
  final ValueChanged<int> onQuantity;
  final bool savingAlert;
  final bool alertSaved;
  final VoidCallback onNotifyMe;
  final VoidCallback onScrollToBundles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedVariant = selectedVariantId == null
        ? null
        : product.variants
            .where((v) => v.id == selectedVariantId)
            .firstOrNull;
    final price = selectedVariant?.price ?? product.effectivePrice;
    final mrp = selectedVariant?.mrp ?? product.mrp;
    final stock = selectedVariant?.stock ?? product.stock;
    final minQty = product.minQtyFor(selectedVariant);
    final packLabel = selectedVariant?.name ?? product.size ?? 'Standard';
    final suitableFor = product.animalTypes.isNotEmpty
        ? product.animalTypes.join(', ')
        : 'All Pets';
    final categoryLabel = product.category ?? 'General';
    final prescriptionLabel =
        product.requiresPrescription ? 'Required (Rx)' : 'Not required';
    final purpose = _purposeOf(product.description);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderWarm),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top emerald pill: Ask Dr. Paw about this product (matching Web `ProductDetailClient.tsx:857-861`)
          Semantics(
            button: true,
            label: 'Ask Dr. Paw AI Chat about ${product.name}',
            child: Material(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Haptics.tap();
                  showDrPawCompanionSheet(context, product: product);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryWashDeep),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDCCEF5)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/marketing_image/dr-paw-genz-avatar.webp',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.auto_awesome,
                            color: AppColors.accentViolet,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 11,
                                  color: AppColors.primaryDeep,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'AI CHAT',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryDeep,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'Ask Dr Paw about this product',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '→',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in product.animalTypes)
                _chip(a, AppColors.successBg, AppColors.primaryDeep),
              if (product.category != null)
                _chip(
                  product.category!,
                  AppColors.infoBg,
                  AppColors.info,
                ),
              if (product.requiresPrescription)
                _chip(
                  'Rx Required',
                  AppColors.rxBg,
                  AppColors.rxText,
                ),
              if (product.onlyForCombo)
                _chip(
                  'Bundle Exclusive',
                  AppColors.homePeach,
                  AppColors.homePeachInk,
                ),
              if (product.offerLabel != null)
                _chip(
                  product.offerLabel!,
                  AppColors.warningBg,
                  AppColors.warning,
                ),
            ],
          ),
          if (product.brand != null) ...[
            const SizedBox(height: 12),
            Text(
              product.brand!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: AppTheme.serif(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.08,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Share',
                onPressed: () => AppShare.shareProduct(context, product),
                icon: const Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryWashFaint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      '₹${formatInr(price)}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.primaryDeepest,
                      ),
                    ),
                    if (mrp != null && mrp > price)
                      Text(
                        '₹${formatInr(mrp)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (mrp != null && mrp > price)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(((mrp - price) / mrp) * 100).round()}% off',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  minQty > 1
                      ? 'Inclusive of all taxes · Min. order: $minQty packs'
                      : 'Inclusive of all taxes',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (product.onlyForCombo) ...[
            const SizedBox(height: 12),
            Material(
              color: AppColors.homePeach,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Haptics.tap();
                  onScrollToBundles();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.coralSoft),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: AppColors.homePeachInk,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bundle Exclusive — Sold exclusively as part of a Care Combo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.homePeachInk,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tap to view eligible Care Bundles below ↓',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
            ),
          ],
          if (purpose != null) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Purpose: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: purpose),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (product.variants.isNotEmpty ||
              product.size?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose a package',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Select your preferred size',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
              children: [
                if (product.size?.isNotEmpty == true &&
                    product.variants.isEmpty)
                  _variantTile(
                    name: product.size!,
                    price: product.price,
                    mrp: product.mrp,
                    selected: selectedVariantId == null,
                    enabled: true,
                    onTap: () => onVariant(null),
                  ),
                for (final v in product.variants)
                  _variantTile(
                    name: v.name,
                    price: v.price,
                    mrp: v.mrp,
                    selected: selectedVariantId == v.id,
                    enabled: v.stock > 0,
                    onTap: () => onVariant(v.id),
                  ),
              ],
            ),
          ],
          if (product.quantityDiscounts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.coinsBg,
                border: Border.all(color: AppColors.coinsBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 16,
                        color: AppColors.coinsIcon,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Bulk / Multi-Pack Savings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tier in product.quantityDiscounts)
                        GestureDetector(
                          onTap: () {
                            Haptics.selection();
                            onQuantity(tier.minQuantity);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: quantity >= tier.minQuantity
                                  ? AppColors.successBg
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: quantity >= tier.minQuantity
                                    ? AppColors.primary
                                    : AppColors.coinsBorder,
                              ),
                            ),
                            child: Text(
                              'Buy ${tier.minQuantity}+ packs · Save ${tier.discountPercent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: quantity >= tier.minQuantity
                                    ? AppColors.primaryDeep
                                    : AppColors.textPrimary,
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
          const SizedBox(height: 12),
          if (!product.onlyForCombo) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryWashFaint,
                border: Border.all(color: AppColors.primaryWashDeep),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              stock > 0 ? '✓ In Stock' : 'Out of Stock',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: stock > 0
                                    ? AppColors.primary
                                    : AppColors.error,
                              ),
                            ),
                            if (cartQuantity > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.primaryWashDeep,
                                  ),
                                ),
                                child: Text(
                                  '$cartQuantity in Cart',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (stock > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            '₹${formatInr(price)} each · $quantity ${quantity == 1 ? 'pack' : 'packs'}: ₹${formatInr(price * quantity)}${minQty > 1 ? ' (Min $minQty)' : ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ] else if (minQty > 1)
                          Text(
                            'Minimum order: $minQty packs',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: cartQuantity > 0
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 48,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: 'Decrease quantity',
                            onPressed: (cartQuantity == 0 &&
                                    quantity <= minQty)
                                ? null
                                : () => onQuantity(
                                      cartQuantity > 0 && quantity <= minQty
                                          ? 0
                                          : quantity - 1,
                                    ),
                            icon: const Text(
                              '−',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border.symmetric(
                              vertical: BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          height: 48,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: 'Increase quantity',
                            onPressed: quantity >= stock
                                ? null
                                : () => onQuantity(quantity + 1),
                            icon: const Text(
                              '+',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 2x2 Product Facts Grid (moved below In Stock)
          Container(
            decoration: BoxDecoration(
              color: AppColors.homeCanvas,
              border: Border.all(color: AppColors.borderWarm),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _factCell(
                          label: 'SUITABLE FOR',
                          value: suitableFor,
                        ),
                      ),
                      Container(width: 1, color: AppColors.border),
                      Expanded(
                        child: _factCell(
                          label: 'CATEGORY',
                          value: categoryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _factCell(
                          label: 'PACK / FORM',
                          value: packLabel.isNotEmpty
                              ? packLabel
                              : 'Standard',
                        ),
                      ),
                      Container(width: 1, color: AppColors.border),
                      Expanded(
                        child: _factCell(
                          label: 'PRESCRIPTION',
                          value: prescriptionLabel,
                          valueColor: product.requiresPrescription
                              ? AppColors.warning
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PincodeCheck(),
          if (stock <= 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: savingAlert ? null : onNotifyMe,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                  backgroundColor: AppColors.successBg,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  savingAlert
                      ? 'Saving alert…'
                      : alertSaved
                          ? "✓ We'll notify you when it is back"
                          : 'Notify me when back in stock',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.homePeach,
              border: Border.all(color: AppColors.borderWarm),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rx',
                  style: AppTheme.serif(
                    fontSize: 24,
                    color: AppColors.accentCoral,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.requiresPrescription
                            ? 'Prescription required'
                            : 'No prescription required',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.requiresPrescription
                            ? 'Upload a valid prescription before ordering.'
                            : 'This product does not require a prescription.',
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factCell({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _variantTile({
    required String name,
    required double price,
    required double? mrp,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.successBg : Colors.white,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryDeep
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '₹${formatInr(price)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primaryDeep
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (mrp != null && mrp > price) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '₹${formatInr(mrp)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _purposeOf(String? description) {
    if (description == null) return null;
    final clean = description.replaceAll(RegExp(r'[#*_`>]'), '');
    for (final line in clean.split(RegExp(r'[.!?\n]'))) {
      final t = line.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }
}

/// Recommended Care Bundles section on the Product Detail Screen.
class PdpComboBundleSection extends ConsumerWidget {
  const PdpComboBundleSection({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combosAsync = ref.watch(homeCombosProvider);
    return combosAsync.maybeWhen(
      data: (combos) {
        final active = combos.where((c) => c.isActive).toList();
        var matching = active
            .where(
              (c) => c.items.any(
                (it) =>
                    it.productId == product.id ||
                    it.product?.id == product.id ||
                    it.product?.slug == product.slug,
              ),
            )
            .toList();
        if (matching.isEmpty && product.onlyForCombo) {
          final animal = product.animalTypes.firstOrNull;
          matching = active.where((c) => c.matchesAnimal(animal)).toList();
        }
        if (matching.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Recommended Care Bundle · Better Together',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            for (var i = 0; i < matching.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              PdpComboBundleCard(
                combo: matching[i],
                fallbackImage: product.image ??
                    (product.images.isNotEmpty ? product.images.first : null),
              ),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class PdpComboBundleCard extends ConsumerStatefulWidget {
  const PdpComboBundleCard({
    super.key,
    required this.combo,
    this.fallbackImage,
  });

  final ComboBundle combo;
  final String? fallbackImage;

  @override
  ConsumerState<PdpComboBundleCard> createState() =>
      _PdpComboBundleCardState();
}

class _PdpComboBundleCardState extends ConsumerState<PdpComboBundleCard> {
  bool _busy = false;

  Future<void> _updateBundleQty(int nextQty) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final currentQty = ref.read(comboCartQuantityProvider(widget.combo.id));
      if (currentQty == 0 && nextQty > 0) {
        Haptics.success();
        await ref.read(cartProvider.notifier).addCombo(
          widget.combo.id,
          comboName: widget.combo.name,
          comboPrice: widget.combo.comboPrice,
          comboImage: widget.combo.image,
        );
        if (mounted) showToast('Care Bundle added to cart');
      } else {
        Haptics.tap();
        await ref
            .read(cartProvider.notifier)
            .setComboQuantity(widget.combo.id, nextQty);
      }
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.combo;
    final qtyInCart = ref.watch(comboCartQuantityProvider(combo.id));
    final imageUrl = (combo.image != null && combo.image!.isNotEmpty)
        ? combo.image!
        : (combo.items.firstOrNull?.product?.image ?? widget.fallbackImage);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryWashDeep, width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryWashFaint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ProductImageCover(
                        imageUrl: imageUrl,
                        borderRadius: BorderRadius.circular(11),
                        innerPadding: const EdgeInsets.all(2),
                        showPlaceholderOnLoading: false,
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primaryDeep,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWash,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'CARE BUNDLE · ${combo.items.length} ITEMS',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeep,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (combo.savingPercent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.homePeach,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Save ${combo.savingPercent}%',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.homePeachInk,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      combo.name,
                      style: AppTheme.serif(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      button: true,
                      label: 'View ${combo.items.length} items in ${combo.name}',
                      child: GestureDetector(
                        onTap: () {
                          Haptics.tap();
                          showComboDetailsSheet(context, combo);
                        },
                        child: Text(
                          'View items (${combo.items.length}) →',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '₹${formatInr(combo.comboPrice)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDeepest,
                          ),
                        ),
                        if (combo.originalPrice > combo.comboPrice) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${formatInr(combo.originalPrice)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mrp,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text(
                      'Bundle price · Inclusive of taxes',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (qtyInCart > 0)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeep,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Decrease bundle quantity',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _busy
                                ? null
                                : () => _updateBundleQty(qtyInCart - 1),
                            child: const Center(
                              child: Icon(
                                Icons.remove_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _busy
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                '$qtyInCart in Cart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Increase bundle quantity',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _busy
                                ? null
                                : () => _updateBundleQty(qtyInCart + 1),
                            child: const Center(
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _updateBundleQty(1),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: const Text(
                      'Add Bundle',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact pincode delivery checker (`DeliveryChecker compact` on the site).
class _PincodeCheck extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PincodeCheck> createState() => _PincodeCheckState();
}

class _PincodeCheckState extends ConsumerState<_PincodeCheck> {
  final _controller = TextEditingController();
  DeliveryInfo? _info;
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter a 6-digit pincode');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
      _info = null;
    });
    try {
      final info =
          await ref.read(deliveryServiceProvider).checkPincode(code);
      ref.read(deliveryPincodeProvider.notifier).setPincode(code);
      if (mounted) setState(() => _info = info);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(deliveryPincodeProvider).value;
    if (_controller.text.isEmpty && saved != null) {
      _controller.text = saved;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'Enter delivery pincode',
                    counterText: '',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _check(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _checking ? null : _check,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Check',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.error,
              ),
            ),
          ],
          if (_info != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _info!.serviceable
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 16,
                  color: _info!.serviceable
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _info!.serviceable
                        ? 'Delivery to ${_info!.pincode} · ${_info!.etaLabel}${_info!.cod ? ' · COD available' : ''}'
                        : 'We don\u2019t deliver to ${_info!.pincode} yet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _info!.serviceable
                          ? AppColors.primaryDeep
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// "Helps with" concern chips (`product.diseases` → concern pages).
class _TreatsCard extends ConsumerWidget {
  const _TreatsCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (product.diseases.isEmpty) return const SizedBox.shrink();
    final treatsAsync = ref.watch(_treatsProvider(product));
    return treatsAsync.maybeWhen(
      data: (treats) {
        if (treats.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HELPS WITH',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in treats)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Haptics.tap();
                          context.push('/diseases/${t.slug}');
                        },
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWash,
                            border: Border.all(
                              color: AppColors.primaryWashDeep,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  t.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '↗',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDeep,
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
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Multi-section structured accordions + dosage note (matching Web `detailSections`).
class _DescriptionCard extends StatefulWidget {
  const _DescriptionCard({required this.product});
  final Product product;

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  final Set<int> _openIndices = {0};

  @override
  Widget build(BuildContext context) {
    final sections = buildProductDetailSections(widget.product);
    if (sections.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryWashDeep),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            InkWell(
              onTap: () {
                Haptics.selection();
                setState(() {
                  if (_openIndices.contains(i)) {
                    _openIndices.remove(i);
                  } else {
                    _openIndices.add(i);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      detailSectionIcon(sections[i].id),
                      size: 16,
                      color: AppColors.primaryDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sections[i].title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                    Text(
                      _openIndices.contains(i) ? '−' : '+',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_openIndices.contains(i))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ProductDescriptionRenderer(
                    text: sections[i].content,
                    isComposition: sections[i].isComposition,
                  ),
                ),
              ),
          ],
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Dosage is displayed only when it has been verified for the animal and product. Follow the label or your veterinarian's advice.",
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ask Dr. Paw about this item" Companion Card (matching Web `ProductDetailClient.tsx:1258-1333`).
class _AskDrPawCompanionCard extends StatelessWidget {
  const _AskDrPawCompanionCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final animal = p.animalTypes.firstOrNull ?? 'my pet';
    final prompts = [
      'How to use ${p.name}?',
      'Is this safe for $animal?',
      'Active ingredients & clinical benefits',
      'Are there equivalent alternatives?',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryWashFaint,
        border: Border.all(color: AppColors.primaryWashDeep),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCCEF5)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/marketing_image/dr-paw-genz-avatar.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.primaryDeep,
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Haptics.tap();
                        showDrPawCompanionSheet(context, product: product);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Ask Dr. Paw about this item',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF137333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Get verified dosage, animal safety & active ingredients',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Open Dr. Paw Companion',
                child: FilledButton(
                  onPressed: () {
                    Haptics.tap();
                    showDrPawCompanionSheet(context, product: product);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Open Companion',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final prompt in prompts)
                Semantics(
                  button: true,
                  label: prompt,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Haptics.tap();
                        showDrPawCompanionSheet(
                          context,
                          product: product,
                          initialQuestion: prompt,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6.5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryWashDeep),
                        ),
                        child: Text(
                          '💬 $prompt',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two Web support cards above Related Products:
/// 1. "Need the same composition? Upload your prescription" (/prescriptions)
/// 2. "Not sure if this suits your pet? Consult a Vet" (/consultations)
class _SupportBannersRow extends StatelessWidget {
  const _SupportBannersRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _supportBanner(
          context: context,
          icon: Icons.upload_file_outlined,
          bgColor: AppColors.rxBg,
          borderColor: AppColors.rxBorder,
          accentColor: AppColors.rxText,
          title: 'Need the same composition? Upload your prescription',
          subtitle:
              'Our veterinary pharmacists will match verified equivalents for your animal.',
          cta: 'Upload Rx →',
          route: '/prescriptions',
        ),
        const SizedBox(height: 8),
        _supportBanner(
          context: context,
          icon: Icons.medical_services_outlined,
          bgColor: AppColors.homeLavender,
          borderColor: AppColors.catRailBorder,
          accentColor: AppColors.homeLavenderInk,
          title: 'Not sure if this suits your pet? Consult a Vet',
          subtitle:
              'Book a consultation with an experienced veterinary doctor.',
          cta: 'Consult a Vet →',
          route: '/consultations',
        ),
      ],
    );
  }

  Widget _supportBanner({
    required BuildContext context,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String cta,
    required String route,
  }) {
    return Semantics(
      button: true,
      label: '$title. $cta',
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Haptics.tap();
            context.push(route);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cta,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
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

/// Mobile 4-up confidence strip (genuine / delivery / returns / secure).
class _ConfidenceStrip extends StatelessWidget {
  const _ConfidenceStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.badge_outlined, 'Genuine products'),
      (Icons.local_shipping_outlined, 'Check delivery'),
      (Icons.restart_alt_rounded, '7 Day Return'),
      (Icons.lock_outline_rounded, 'Secure Payment'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryWashFaint,
        border: Border.all(color: AppColors.borderWarm),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.$1,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      item.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
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

/// Related grid ("You may also need" + View All → category listing).
class _RelatedCard extends ConsumerWidget {
  const _RelatedCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(relatedProductsProvider(product.id));
    return relatedAsync.maybeWhen(
      data: (related) {
        if (related.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'You may also need',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(
                        '/products?category=${Uri.encodeComponent(product.category ?? '')}',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.homeCanvas,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'View All →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: productCardExtent(context),
                ),
                itemCount: related.length.clamp(0, 6),
                itemBuilder: (context, i) =>
                    CompactProductCard(product: related[i]),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Fixed mobile purchase bar: selected pack size + price + Add to Cart / live stepper + Buy Now.
class _BuyBar extends ConsumerStatefulWidget {
  const _BuyBar({
    required this.product,
    required this.selectedVariantId,
    required this.quantity,
    required this.adding,
    required this.onAdd,
    required this.onBuyNow,
    required this.onScrollToBundles,
  });
  final Product product;
  final String? selectedVariantId;
  final int quantity;
  final bool adding;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onBuyNow;
  final VoidCallback onScrollToBundles;

  @override
  ConsumerState<_BuyBar> createState() => _BuyBarState();
}

class _BuyBarState extends ConsumerState<_BuyBar> {
  bool _stepping = false;

  Future<void> _stepCartQuantity({
    required Product product,
    required ProductVariant? variant,
    required int currentQty,
    required int delta,
  }) async {
    if (_stepping) return;
    final minQty = product.minQtyFor(variant);
    final nextQty = delta < 0
        ? (currentQty <= minQty ? 0 : currentQty + delta)
        : currentQty + delta;
    setState(() => _stepping = true);
    try {
      Haptics.tap();
      await ref.read(cartProvider.notifier).setQuantity(
            productId: product.id,
            variantId: variant?.id,
            quantity: nextQty,
          );
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _stepping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variant = widget.selectedVariantId == null
        ? null
        : product.variants
            .where((v) => v.id == widget.selectedVariantId)
            .firstOrNull;
    final price = variant?.price ?? product.effectivePrice;
    final stock = variant?.stock ?? product.stock;
    final packLabel = variant?.name ?? product.size ?? 'Standard Pack';
    final cartQty = ref.watch(
      cartQuantityProvider((product.id, widget.selectedVariantId)),
    );
    final displayQty = cartQty > 0 ? cartQty : widget.quantity;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadowLifted,
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 72, maxWidth: 116),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayQty > 1 ? '$displayQty × $packLabel' : packLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  const Text(
                    'Inclusive of all taxes',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${formatInr(price * displayQty)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (product.onlyForCombo)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: widget.onScrollToBundles,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined, size: 17),
                    label: const Text(
                      'Bundle Exclusive · View Combos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: cartQty > 0
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryDeep,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Semantics(
                                button: true,
                                label: 'Decrease quantity in cart',
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 48,
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _stepping
                                        ? null
                                        : () => _stepCartQuantity(
                                              product: product,
                                              variant: variant,
                                              currentQty: cartQty,
                                              delta: -1,
                                            ),
                                    child: const Center(
                                      child: Text(
                                        '−',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: _stepping
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        '$cartQty in Cart',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                              Semantics(
                                button: true,
                                label: 'Increase quantity in cart',
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 48,
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _stepping || cartQty >= stock
                                        ? null
                                        : () => _stepCartQuantity(
                                              product: product,
                                              variant: variant,
                                              currentQty: cartQty,
                                              delta: 1,
                                            ),
                                    child: const Center(
                                      child: Text(
                                        '+',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : OutlinedButton(
                          onPressed: widget.adding || stock <= 0
                              ? null
                              : () => widget.onAdd(product),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.adding ? 'Adding…' : 'Add to Cart',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
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
                    onPressed: stock <= 0
                        ? null
                        : () => widget.onBuyNow(product),
                    style: FilledButton.styleFrom(
                      backgroundColor: cartQty > 0
                          ? AppColors.primary
                          : AppColors.accentCoral,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rx upload sheet (`RxDialog`): pick a prescription photo, upload it for
/// review, then the item stays in the cart for fulfilment after approval.
class _RxSheet extends ConsumerStatefulWidget {
  const _RxSheet({required this.product});
  final Product product;

  @override
  ConsumerState<_RxSheet> createState() => _RxSheetState();
}

class _RxSheetState extends ConsumerState<_RxSheet> {
  XFile? _file;
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (file != null && mounted) {
        setState(() {
          _file = file;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _upload() async {
    if (_file == null) {
      setState(() => _error = 'Please select a prescription image');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final url = await ref
          .read(uploadServiceProvider)
          .uploadImage(_file!.path, purpose: 'prescription');
      await ref.read(prescriptionServiceProvider).uploadPrescription(
            imageUrls: [url],
            notes: 'For ${widget.product.name}',
          );
      ref.invalidate(prescriptionsProvider);
      if (mounted) {
        Navigator.pop(context);
        showToast('Prescription submitted for review');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSpace = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + bottomSpace,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.homePeach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rx',
                  style: AppTheme.serif(
                    fontSize: 20,
                    color: AppColors.accentCoral,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prescription required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload a valid prescription. Our team will review it before fulfilment.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          if (_file != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryWashFaint,
                border: Border.all(color: AppColors.primaryWashDeep),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: AppColors.primaryDeep,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _file!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  GestureDetector(
                    onTap: _busy
                        ? null
                        : () => setState(() => _file = null),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _upload,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Upload prescription',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
