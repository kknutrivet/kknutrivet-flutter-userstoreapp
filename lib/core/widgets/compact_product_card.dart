import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'common.dart';
import 'product_image_cover.dart';
import 'variant_picker_sheet.dart';

/// Indian digit grouping for prices (`1250` → `1,250`), matching the
/// website's `toLocaleString("en-IN")` price rendering.
String formatInr(double value) {
  final digits = value.toStringAsFixed(0);
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final groupedHead = head.replaceAllMapped(
    RegExp(r'(\d)(?=(\d\d)+$)'),
    (m) => '${m[1]},',
  );
  return '$groupedHead,$tail';
}

/// Which website card surface to replicate.
///
/// * [homeGrid] — `ProductCard` with `mobileHomeGrid`: 4/3 image, 12px bold
///   name, deep-green filled Add pill (used in the home animal rails).
/// * [catalogue] — `ProductCard` with `mobileCatalogue`: square image,
///   11px semibold name, green `#0C831F` price, white Add pill with green
///   outline (used in the /products grid).
enum CompactCardVariant { homeGrid, catalogue }

/// Compact 2-column-grid product card — exact replica of the website's
/// mobile product card (`src/components/ProductCard.tsx`).
class CompactProductCard extends ConsumerStatefulWidget {
  const CompactProductCard({
    super.key,
    required this.product,
    this.variant = CompactCardVariant.catalogue,
    this.heroTag,
  });

  final Product product;
  final CompactCardVariant variant;
  final String? heroTag;

  @override
  ConsumerState<CompactProductCard> createState() =>
      _CompactProductCardState();
}

class _CompactProductCardState extends ConsumerState<CompactProductCard> {
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

  String? _inferDosageForm(Product product) {
    final text = '${product.name} ${product.category}'.toLowerCase();
    if (text.contains('syrup') || text.contains('liquid') || text.contains('suspension')) {
      return 'SYRUP';
    }
    if (text.contains('powder') || text.contains('granule')) return 'POWDER';
    if (text.contains('tablet') || text.contains('chewable')) return 'TABLET';
    if (text.contains('bolus')) return 'BOLUS';
    if (text.contains('spray')) return 'SPRAY';
    if (text.contains('shampoo') || text.contains('wash')) return 'SHAMPOO';
    if (text.contains('drop') || text.contains('spot on') || text.contains('spot-on')) {
      return 'DROPS';
    }
    if (text.contains('ointment') || text.contains('cream') || text.contains('gel')) {
      return 'CREAM';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final v = _resolveVariant(product);
    final quantity = ref.watch(cartQuantityProvider((product.id, v?.id)));
    final image = product.image ??
        (product.images.isNotEmpty ? product.images.first : null);
    final isCatalogue = widget.variant == CompactCardVariant.catalogue;
    final displayPrice = v?.price ?? product.effectivePrice;
    final displayMrp = v?.mrp ?? product.mrp;
    final hasDiscount = displayMrp != null && displayMrp > displayPrice;
    final discountPercent = hasDiscount
        ? (((displayMrp - displayPrice) / displayMrp) * 100).round()
        : 0;
    final dosageForm = _inferDosageForm(product);

    return AppBounce(
      pressedScale: 0.975,
      onTap: () => context.push(
        '/product/${product.slug.isNotEmpty ? product.slug : product.id}',
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDCE7E1)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D173C32),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageStack = Stack(
                children: [
                  Positioned.fill(
                    child: widget.heroTag != null
                        ? Hero(
                            tag: widget.heroTag!,
                            child: ProductImageCover(
                              imageUrl: image,
                              showPlaceholderOnLoading: false,
                              backdropOpacity: 0.85,
                              innerPadding: const EdgeInsets.all(6),
                            ),
                          )
                        : ProductImageCover(
                            imageUrl: image,
                            showPlaceholderOnLoading: false,
                            backdropOpacity: 0.85,
                            innerPadding: const EdgeInsets.all(6),
                          ),
                  ),
                  if (hasDiscount && discountPercent > 0)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF7EF),
                          border: Border.all(color: const Color(0xFFCEE4D5)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$discountPercent% off',
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF176441),
                          ),
                        ),
                      ),
                    ),
                  if (product.requiresPrescription)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rxBg,
                          border: Border.all(color: AppColors.rxBorder),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Rx required',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: AppColors.rxText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (dosageForm != null)
                    Positioned(
                      bottom: 5,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          border: Border.all(color: const Color(0xFFCFE3D9)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dosageForm,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: Color(0xFF0B6645),
                          ),
                        ),
                      ),
                    ),
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (constraints.hasBoundedHeight)
                    Expanded(child: imageStack)
                  else
                    AspectRatio(aspectRatio: 1.25, child: imageStack),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (product.variants.length > 1)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              Haptics.tap();
                              final picked = await showVariantPickerBottomSheet(
                                context: context,
                                product: product,
                                selectedVariant: v,
                              );
                              if (picked != null && mounted) {
                                setState(() => _selectedVariantId = picked.id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Pack: ${v?.name ?? 'Choose pack'} · ${product.variants.length} sizes ▾',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        height: 1.2,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if ((v?.name ?? product.size)?.isNotEmpty == true)
                          Text(
                            v?.name ?? product.size!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${formatInr(displayPrice)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.1,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.25,
                                      color: isCatalogue
                                          ? const Color(0xFF0C831F)
                                          : const Color(0xFF126B50),
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Text(
                                      '₹${formatInr(displayMrp)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        height: 1.1,
                                        color: AppColors.mrp,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 30,
                              width: quantity > 0 ? 74 : 62,
                              child: _CompactAddButton(
                                product: product,
                                variant: v,
                                quantity: quantity,
                                outlined: isCatalogue,
                                onVariantChanged: (picked) => setState(
                                    () => _selectedVariantId = picked.id),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Reserve space for readable names, pack details and controls.
double productCardExtent(BuildContext context) {
  final width = (MediaQuery.sizeOf(context).width - 44) / 2;
  return width / 1.25 +
      118 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.35);
}

class _CompactAddButton extends ConsumerStatefulWidget {
  const _CompactAddButton({
    required this.product,
    this.variant,
    required this.quantity,
    required this.outlined,
    this.onVariantChanged,
  });

  final Product product;
  final ProductVariant? variant;
  final int quantity;
  final bool outlined;
  final ValueChanged<ProductVariant>? onVariantChanged;

  @override
  ConsumerState<_CompactAddButton> createState() =>
      _CompactAddButtonState();
}

class _CompactAddButtonState extends ConsumerState<_CompactAddButton> {
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
          borderRadius: BorderRadius.circular(widget.outlined ? 8 : 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.outlined ? 8 : 20),
            onTap: () {
              Haptics.tap();
              context.push('/product/$target');
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.outlined ? 8 : 20),
                border: Border.all(color: AppColors.primaryWashDeep),
              ),
              child: const Center(
                child: Text(
                  'Bundle Only →',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
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
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(widget.outlined ? 8 : 20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Out of stock',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final hasMultipleVariants = product.variants.length > 1;

    final Widget buttonWidget;
    if (widget.quantity > 0) {
      final bool isMintStepper = !widget.outlined;
      final Color bg = isMintStepper
          ? const Color(0xFFF0F7F3)
          : AppColors.catalogueGreen;
      final Color fg = isMintStepper
          ? const Color(0xFF126B50)
          : Colors.white;

      buttonWidget = Container(
        key: const ValueKey('stepper'),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isMintStepper
              ? Border.all(color: const Color(0xFFBDD6C9), width: 1.2)
              : null,
          boxShadow: isMintStepper
              ? null
              : [
                  BoxShadow(
                    color: bg.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Decrease quantity of ${product.name}',
                child: AppBounce(
                  pressedScale: 0.85,
                  onTap: _busy ? null : () => _updateQuantity(-1),
                  child: Center(
                    child: Icon(Icons.remove, size: 14, color: fg),
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
                      }
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _busy
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppTextSwitcher(
                            text: '${widget.quantity}',
                            style: TextStyle(
                              color: fg,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (hasMultipleVariants) ...[
                            const SizedBox(width: 1),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 13,
                              color: fg,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Increase quantity of ${product.name}',
                child: AppBounce(
                  pressedScale: 0.85,
                  onTap: _busy ? null : () => _updateQuantity(1),
                  child: Center(
                    child: Icon(Icons.add, size: 14, color: fg),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (widget.outlined) {
      buttonWidget = Semantics(
        key: const ValueKey('add_outlined'),
        button: true,
        label: hasMultipleVariants
            ? 'Choose options for ${product.name}'
            : 'Add ${product.name} to cart',
        child: AppBounce(
          pressedScale: 0.94,
          onTap: _busy ? null : _handleInitialAdd,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: AppColors.catalogueGreen,
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.catalogueGreen,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!hasMultipleVariants) ...[
                          const Icon(
                            Icons.add,
                            size: 13,
                            color: AppColors.catalogueGreen,
                          ),
                          const SizedBox(width: 2),
                        ],
                        const Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.catalogueGreen,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (hasMultipleVariants) ...[
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: AppColors.catalogueGreen,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      );
    } else {
      buttonWidget = Semantics(
        key: const ValueKey('add_filled'),
        button: true,
        label: hasMultipleVariants
            ? 'Choose options for ${product.name}'
            : 'Add ${product.name} to cart',
        child: AppBounce(
          pressedScale: 0.94,
          onTap: _busy ? null : _handleInitialAdd,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF07583F),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF07583F).withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!hasMultipleVariants) ...[
                          const Icon(
                            Icons.add,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                        ],
                        const Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (hasMultipleVariants) ...[
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Colors.white,
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
