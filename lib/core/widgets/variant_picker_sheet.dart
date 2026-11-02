import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'common.dart';
import 'compact_product_card.dart' show formatInr;
import 'product_image_cover.dart';

/// Opens a native Material 3 modal bottom sheet to pick and add a pack size variant.
Future<ProductVariant?> showVariantPickerBottomSheet({
  required BuildContext context,
  required Product product,
  required ProductVariant? selectedVariant,
}) async {
  // Yield to the event loop so any in-flight pointer event packets finish
  // processing and layout passes complete before mounting the modal bottom sheet.
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return null;

  return showModalBottomSheet<ProductVariant>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => VariantPickerSheet(
      product: product,
      selectedVariant: selectedVariant,
    ),
  );
}

class VariantPickerSheet extends ConsumerStatefulWidget {
  const VariantPickerSheet({
    super.key,
    required this.product,
    required this.selectedVariant,
  });

  final Product product;
  final ProductVariant? selectedVariant;

  @override
  ConsumerState<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends ConsumerState<VariantPickerSheet> {
  late ProductVariant? _selected;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedVariant ??
        (widget.product.variants.isNotEmpty
            ? widget.product.variants.firstWhere(
                (v) => v.stock > 0,
                orElse: () => widget.product.variants.first,
              )
            : null);
  }

  Future<void> _handleAddToCart() async {
    final v = _selected;
    if (v == null) return;
    if (v.stock <= 0) {
      showToast('Selected pack is out of stock', isError: true);
      return;
    }

    final minQty = widget.product.minQtyFor(v);
    setState(() => _adding = true);
    try {
      await ref.read(cartProvider.notifier).addItem(
            productId: widget.product.id,
            variantId: v.id,
            quantity: minQty,
            product: widget.product,
            variant: v,
          );
      AppHaptics.cart();
      if (mounted) {
        showToast('Added ${widget.product.name} · ${v.name} to cart');
        Navigator.of(context).pop(v);
      }
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final selectedVariant = _selected;
    final selectedInStock = selectedVariant != null && selectedVariant.stock > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Header plate
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: ProductImageCover(
                      imageUrl: product.image,
                      borderRadius: BorderRadius.circular(10),
                      innerPadding: const EdgeInsets.all(2),
                      showPlaceholderOnLoading: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & brand
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brand != null && product.brand!.isNotEmpty)
                          Text(
                            product.brand!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.serif(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CHOOSE PACK SIZE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${product.variants.length} options',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Options List
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int index = 0; index < product.variants.length; index++) ...[
                      if (index > 0) const SizedBox(height: 8),
                      _buildVariantOption(
                        v: product.variants[index],
                        selectedVariant: selectedVariant,
                        product: product,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Action Bar
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
              child: Row(
                children: [
                  if (selectedVariant != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedVariant.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${formatInr(selectedVariant.price)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDeepest,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: selectedInStock && !_adding
                          ? _handleAddToCart
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 44),
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.surfaceAlt,
                        disabledForegroundColor: AppColors.textTertiary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _adding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              selectedInStock ? 'Add to Cart' : 'Out of Stock',
                              style: const TextStyle(
                                fontSize: 13.5,
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
      ),
    );
  }

  Widget _buildVariantOption({
    required ProductVariant v,
    required ProductVariant? selectedVariant,
    required Product product,
  }) {
    final isSelected = selectedVariant?.id == v.id;
    final inStock = v.stock > 0;
    final hasDisc = v.mrp != null && v.mrp! > v.price;
    final discPct =
        hasDisc ? (((v.mrp! - v.price) / v.mrp!) * 100).round() : 0;
    final minQty = product.minQtyFor(v);
    final inCartQty = ref.watch(
      cartQuantityProvider((product.id, v.id)),
    );

    return Material(
      color: isSelected ? AppColors.primaryWashFaint : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Haptics.selection();
          setState(() => _selected = v);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Radio indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.primaryDeep
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDeep
                        : AppColors.borderStrong,
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Variant description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            v.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: inStock
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        if (hasDisc) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$discPct% OFF',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          inStock ? 'In stock' : 'Out of stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: inStock ? AppColors.primary : AppColors.error,
                          ),
                        ),
                        if (minQty > 1) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· Min $minQty units',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (inCartQty > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWashDeep,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$inCartQty in cart',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Price column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${formatInr(v.price)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDeepest,
                    ),
                  ),
                  if (hasDisc)
                    Text(
                      '₹${formatInr(v.mrp!)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.mrp,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
