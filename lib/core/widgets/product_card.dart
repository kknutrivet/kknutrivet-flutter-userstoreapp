import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'compact_product_card.dart';
import 'common.dart';
import 'product_image_cover.dart';
import 'variant_picker_sheet.dart';

export 'compact_product_card.dart';
export 'product_image_cover.dart';
export 'variant_picker_sheet.dart';

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAdd,
    this.showAddButton = true,
    this.heroTag,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final bool showAddButton;
  final String? heroTag;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  String? _selectedVariantId;

  ProductVariant? _resolveVariant(Product product) {
    if (product.variants.isEmpty) return null;
    if (_selectedVariantId != null) {
      for (final v in product.variants) {
        if (v.id == _selectedVariantId) return v;
      }
    }
    return product.variants.firstWhere(
      (v) => v.stock > 0,
      orElse: () => product.variants.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final v = _resolveVariant(product);
    final isFavorite = ref.watch(
      wishlistProvider.select((s) => s.value?.contains(product.id) ?? false),
    );
    final quantity = ref.watch(cartQuantityProvider((product.id, v?.id)));
    final displayPrice = v?.price ?? product.effectivePrice;
    final displayMrp = v?.mrp ?? product.mrp;
    final hasDiscount = displayMrp != null && displayMrp > displayPrice;
    final discountPercent = hasDiscount
        ? (((displayMrp - displayPrice) / displayMrp) * 100).round()
        : 0;

    return AppBounce(
      pressedScale: 0.98,
      onTap: () {
        Haptics.tap();
        widget.onTap();
      },
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image plate
              Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: widget.heroTag != null
                        ? Hero(
                            tag: widget.heroTag!,
                            child: ProductImageCover(
                              imageUrl: product.image,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              showPlaceholderOnLoading: false,
                            ),
                          )
                        : ProductImageCover(
                            imageUrl: product.image,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            showPlaceholderOnLoading: false,
                          ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentCoralDeep,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (product.requiresPrescription)
                    Positioned(
                      left: hasDiscount ? null : 8,
                      right: hasDiscount ? 52 : null,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rxBg,
                          border: Border.all(color: AppColors.rxBorder),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Rx',
                          style: TextStyle(
                            color: AppColors.rxText,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Semantics(
                      button: true,
                      label: isFavorite
                          ? 'Remove ${product.name} from wishlist'
                          : 'Add ${product.name} to wishlist',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Haptics.tap();
                            ref
                                .read(wishlistProvider.notifier)
                                .toggle(product.id);
                          },
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedScale(
                                scale: isFavorite ? 1.12 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isFavorite
                                      ? AppColors.favoriteRed
                                      : AppColors.favoriteHeartInactive,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Info block
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(
                        product.brand!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9.5,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 36,
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (v != null && product.variants.length > 1) ...[
                      const SizedBox(height: 4),
                      Semantics(
                        button: true,
                        label:
                            'Selected pack ${v.name}, ${product.variants.length} packs available. Tap to change pack size',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            Haptics.tap();
                            
                            if (!mounted) return;
                            final picked =
                                await showVariantPickerBottomSheet(
                              context: context,
                              product: product,
                              selectedVariant: v,
                            );
                            if (picked != null && mounted) {
                              setState(() => _selectedVariantId = picked.id);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWashFaint,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryWashDeep,
                              ),
                            ),
                            child: Text(
                              '${v.name} · ${product.variants.length} packs ▾',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryDeep,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (v != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        v.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ] else if (product.size != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.size!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          '₹${formatInr(displayPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            letterSpacing: -0.3,
                            color: AppColors.primaryDeepest,
                          ),
                        ),
                        if (hasDiscount) ...[
                          Text(
                            '₹${formatInr(displayMrp)}',
                            style: const TextStyle(
                              color: AppColors.mrp,
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (product.requiresPrescription) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Prescription required',
                        style: TextStyle(
                          color: AppColors.rxText,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.showAddButton)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _AddButton(
                    product: product,
                    variant: v,
                    quantity: quantity,
                    onAdded: widget.onAdd,
                    onVariantChanged: (picked) {
                      setState(() => _selectedVariantId = picked.id);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends ConsumerStatefulWidget {
  const _AddButton({
    required this.product,
    this.variant,
    required this.quantity,
    this.onAdded,
    this.onVariantChanged,
  });

  final Product product;
  final ProductVariant? variant;
  final int quantity;
  final VoidCallback? onAdded;
  final ValueChanged<ProductVariant>? onVariantChanged;

  @override
  ConsumerState<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends ConsumerState<_AddButton> {
  bool _busy = false;

  Future<void> _handleInitialAdd() async {
    if (widget.product.variants.length > 1) {
      
      if (!mounted) return;
      final picked = await showVariantPickerBottomSheet(
        context: context,
        product: widget.product,
        selectedVariant: widget.variant,
      );
      if (picked != null && mounted) {
        widget.onVariantChanged?.call(picked);
        widget.onAdded?.call();
      }
      return;
    }
    await _updateQuantity(1);
  }

  Future<void> _updateQuantity(int delta) async {
    final v = widget.variant;
    final minQty = widget.product.minQtyFor(v);
    setState(() => _busy = true);
    try {
      if (delta < 0) {
        final nextQty =
            widget.quantity <= minQty ? 0 : widget.quantity + delta;
        AppHaptics.step();
        await ref.read(cartProvider.notifier).setQuantity(
              productId: widget.product.id,
              variantId: v?.id,
              quantity: nextQty,
            );
        if (mounted) {
          showToast(nextQty == 0
              ? '${widget.product.name} removed from cart'
              : 'Cart updated');
        }
      } else if (widget.quantity == 0) {
        await ref.read(cartProvider.notifier).addItem(
              productId: widget.product.id,
              variantId: v?.id,
              quantity: minQty,
              product: widget.product,
              variant: v,
            );
        AppHaptics.cart();
        widget.onAdded?.call();
        if (mounted) showToast('Added to cart');
      } else {
        AppHaptics.step();
        await ref.read(cartProvider.notifier).setQuantity(
              productId: widget.product.id,
              variantId: v?.id,
              quantity: widget.quantity + delta,
            );
        if (mounted) showToast('Cart updated');
      }
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final v = widget.variant;
    final inStock = v != null ? v.stock > 0 : product.inStock;

    if (product.onlyForCombo) {
      final target = product.slug.isNotEmpty ? product.slug : product.id;
      return Semantics(
        button: true,
        label: 'Bundle Only, view ${product.name} details',
        child: Material(
          color: AppColors.primaryWashFaint,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Haptics.tap();
              context.push('/product/$target');
            },
            child: Container(
              width: double.infinity,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryWashDeep),
              ),
              child: const Center(
                child: Text(
                  'Bundle Only →',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!inStock) {
      return Container(
        width: double.infinity,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Out of stock',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final hasMultipleVariants = product.variants.length > 1;

    final Widget buttonWidget;
    if (widget.quantity > 0) {
      buttonWidget = Container(
        key: const ValueKey('add_stepper'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: AppColors.primaryDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryWashDeep),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeep.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: 'Decrease quantity of ${product.name}',
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                child: AppBounce(
                  pressedScale: 0.85,
                  onTap: _busy ? null : () => _updateQuantity(-1),
                  child: const Center(
                    child: Icon(Icons.remove, size: 17, color: Colors.white),
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hasMultipleVariants
                  ? () async {
                      if (!mounted) return;
                      final picked = await showVariantPickerBottomSheet(
                        context: context,
                        product: product,
                        selectedVariant: v,
                      );
                      if (picked != null && mounted) {
                        widget.onVariantChanged?.call(picked);
                        widget.onAdded?.call();
                      }
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppTextSwitcher(
                            text: '${widget.quantity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (hasMultipleVariants) ...[
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Increase quantity of ${product.name}',
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                child: AppBounce(
                  pressedScale: 0.85,
                  onTap: _busy ? null : () => _updateQuantity(1),
                  child: const Center(
                    child: Icon(Icons.add, size: 17, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      buttonWidget = Semantics(
        key: const ValueKey('add_initial'),
        button: true,
        label: hasMultipleVariants
            ? 'Choose options for ${product.name}'
            : 'Add ${product.name} to cart',
        child: AppBounce(
          pressedScale: 0.95,
          onTap: _busy ? null : _handleInitialAdd,
          child: Container(
            height: 38,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.stepperBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.stepperBorder,
                width: 1.2,
              ),
            ),
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryDeep,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!hasMultipleVariants) ...[
                          const Icon(
                            Icons.add,
                            size: 15,
                            color: AppColors.primaryDeep,
                          ),
                          const SizedBox(width: 4),
                        ],
                        const Text(
                          'ADD',
                          style: TextStyle(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (hasMultipleVariants) ...[
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.primaryDeep,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    return AppScaleSwitcher(child: buttonWidget);
  }
}
