import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/combo_details_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../core/widgets/product_image_cover.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

ComboBundle resolveComboFromCart(
  String comboId,
  List<CartItem> bundleItems,
  List<ComboBundle> allCombos,
) {
  final cleanId = comboId.trim();
  final matched = allCombos.where((c) => c.id.trim() == cleanId).firstOrNull ??
      (bundleItems.isNotEmpty && bundleItems.first.comboName != null
          ? allCombos
              .where((c) =>
                  c.name.trim().toLowerCase() ==
                  bundleItems.first.comboName!.trim().toLowerCase())
              .firstOrNull
          : null);
  if (matched != null) return matched;
  final first = bundleItems.first;
  final bundleQty = (first.comboQuantity ?? first.quantity).clamp(1, 999);
  final comboPriceRaw = bundleItems
      .map((i) => i.comboPrice ?? 0.0)
      .fold(0.0, (max, p) => p > max ? p : max);
  final totalLine = comboPriceRaw > 0
      ? comboPriceRaw * bundleQty
      : bundleItems.fold<double>(0, (s, i) => s + i.lineTotal);
  final totalMrp = bundleItems.fold<double>(
    0,
    (s, i) {
      final unitMrp = i.variant?.mrp ??
          i.product?.mrp ??
          i.variant?.price ??
          i.product?.price ??
          i.product?.effectivePrice;
      return s + ((unitMrp ?? i.unitPrice) * i.quantity);
    },
  );
  return ComboBundle(
    id: comboId,
    name: first.comboName ?? 'Care Combo Bundle',
    description: first.comboDescription,
    image: first.comboImage ?? first.product?.image,
    originalPrice: totalMrp > 0 ? totalMrp / bundleQty : totalLine / bundleQty,
    comboPrice: totalLine / bundleQty,
    items: bundleItems
        .map(
          (i) => ComboItem(
            id: i.id,
            productId: i.productId,
            quantity: (i.quantity / bundleQty).round().clamp(1, 999),
            variantId: i.variantId,
            product: i.product,
          ),
        )
        .toList(),
  );
}

/// Grouped Combo Bundle Cart Card (`item.comboId != null`).
class ComboBundleCartTile extends ConsumerStatefulWidget {
  const ComboBundleCartTile({
    super.key,
    required this.comboId,
    required this.bundleItems,
    required this.combos,
  });

  final String comboId;
  final List<CartItem> bundleItems;
  final List<ComboBundle> combos;

  @override
  ConsumerState<ComboBundleCartTile> createState() =>
      _ComboBundleCartTileState();
}

class _ComboBundleCartTileState extends ConsumerState<ComboBundleCartTile> {
  bool _busy = false;

  Future<void> _updateQty(String bundleName, int nextQty) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(cartProvider.notifier)
          .setComboQuantity(widget.comboId, nextQty);
      if (nextQty <= 0) {
        showToast('$bundleName removed from cart');
      } else {
        showToast('Updated $bundleName quantity to $nextQty');
      }
    } catch (e) {
      showToast('Could not update bundle: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeBundle(String bundleName) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(cartProvider.notifier)
          .setComboQuantity(widget.comboId, 0);
      showToast('$bundleName removed from cart');
    } catch (e) {
      showToast('Could not remove bundle: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.bundleItems.first;
    final resolvedCombo =
        resolveComboFromCart(widget.comboId, widget.bundleItems, widget.combos);
    final coverImage =
        first.comboImage ?? resolvedCombo.image ?? first.product?.image;
    final bundleName = first.comboName ?? resolvedCombo.name;
    final itemCount = resolvedCombo.items.isNotEmpty
        ? resolvedCombo.items.length
        : widget.bundleItems.length;
    final int rawQty = first.comboQuantity ??
        ref.watch(comboCartQuantityProvider(widget.comboId));
    final bundleQty = rawQty.clamp(1, 999);

    final double rawComboPrice = widget.bundleItems
        .map((i) => i.comboPrice ?? 0.0)
        .fold(0.0, (max, p) => p > max ? p : max);
    final double unitBundlePrice = rawComboPrice > 0
        ? rawComboPrice
        : (resolvedCombo.comboPrice > 0
            ? resolvedCombo.comboPrice
            : widget.bundleItems.fold<double>(0, (sum, i) => sum + i.lineTotal));
    final double bundleTotal = unitBundlePrice * bundleQty;

    final double rawMrpFromItems = widget.bundleItems.fold<double>(
      0,
      (sum, i) {
        final unitMrp = i.variant?.mrp ??
            i.product?.mrp ??
            i.variant?.price ??
            i.product?.price ??
            i.product?.effectivePrice;
        return sum + ((unitMrp ?? 0) * i.quantity);
      },
    );
    final double catalogMrp = resolvedCombo.originalPrice > 0
        ? (resolvedCombo.originalPrice * bundleQty)
        : 0;
    final double resolvedComboItemsMrp = resolvedCombo.items.isNotEmpty
        ? resolvedCombo.items.fold<double>(
            0,
            (sum, ci) {
              final pMrp = ci.product?.mrp ??
                  ci.product?.price ??
                  ci.product?.effectivePrice ??
                  0;
              return sum + (pMrp * ci.quantity * bundleQty);
            },
          )
        : 0;

    final double mrpTotal = [
      rawMrpFromItems,
      catalogMrp,
      resolvedComboItemsMrp,
    ].reduce((a, b) => a > b ? a : b);

    final bool hasMrpSaving = mrpTotal > bundleTotal;
    final int discountPercent = hasMrpSaving && mrpTotal > 0
        ? (((mrpTotal - bundleTotal) / mrpTotal) * 100).round()
        : (resolvedCombo.savingPercent > 0 ? resolvedCombo.savingPercent : 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryWashDeep),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1F372F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => showComboDetailsSheet(context, resolvedCombo),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ProductImageCover(
                  imageUrl: coverImage,
                  borderRadius: BorderRadius.circular(12),
                  innerPadding: const EdgeInsets.all(3),
                  backdropOpacity: 0.85,
                  showPlaceholderOnLoading: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryWash,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'COMBO BUNDLE · $itemCount items',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDeep,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () =>
                                  showComboDetailsSheet(context, resolvedCombo),
                              child: Text(
                                bundleName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  height: 1.28,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () =>
                                  showComboDetailsSheet(context, resolvedCombo),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  'View bundle items →',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Remove bundle',
                        onPressed:
                            _busy ? null : () => _removeBundle(bundleName),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                        icon: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFF8A9B93),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '₹${formatInr(bundleTotal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: AppColors.primaryDeepest,
                                  ),
                                ),
                                if (hasMrpSaving)
                                  Text(
                                    '₹${formatInr(mrpTotal)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mrp,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                if (discountPercent > 0)
                                  Text(
                                    '$discountPercent% OFF',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                              ],
                            ),
                            if (bundleQty > 1) ...[
                              const SizedBox(height: 2),
                              Text(
                                '₹${formatInr(unitBundlePrice)} × $bundleQty',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Webapp-style mint rectangular quantity stepper
                      Container(
                        height: 34,
                        width: 92,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F8F5),
                          border: Border.all(color: const Color(0xFFBDD6C9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 29,
                              height: 34,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(7),
                                ),
                                onTap: _busy
                                    ? null
                                    : () => _updateQty(
                                          bundleName,
                                          bundleQty - 1,
                                        ),
                                child: Icon(
                                  bundleQty <= 1
                                      ? Icons.delete_outline_rounded
                                      : Icons.remove,
                                  size: 15,
                                  color: _busy
                                      ? AppColors.textTertiary
                                      : (bundleQty <= 1
                                          ? AppColors.error
                                          : AppColors.brandPrimary),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 34,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border.symmetric(
                                    vertical: BorderSide(
                                      color: Color(0xFFD2E4DB),
                                    ),
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.brandPrimary,
                                        ),
                                      )
                                    : Text(
                                        '$bundleQty',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.primaryDeepest,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(
                              width: 29,
                              height: 34,
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(7),
                                ),
                                onTap: _busy
                                    ? null
                                    : () => _updateQty(
                                          bundleName,
                                          bundleQty + 1,
                                        ),
                                child: Icon(
                                  Icons.add,
                                  size: 15,
                                  color: _busy
                                      ? AppColors.textTertiary
                                      : AppColors.brandPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone Cart Item Tile with smart "UPGRADE & SAVE" combo bundle banner.
class CartItemTile extends ConsumerStatefulWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.allCartItems,
    required this.combos,
  });

  final CartItem item;
  final List<CartItem> allCartItems;
  final List<ComboBundle> combos;

  @override
  ConsumerState<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<CartItemTile> {
  bool _busy = false;

  ComboBundle? _findUpgradeCombo() {
    if (widget.item.comboId != null) return null;
    for (final combo in widget.combos) {
      if (!combo.isActive) continue;
      final alreadyInCart =
          widget.allCartItems.any((ci) => ci.comboId == combo.id);
      if (alreadyInCart) continue;
      final containsProduct =
          combo.items.any((ci) => ci.productId == widget.item.productId);
      if (containsProduct) return combo;
    }
    return null;
  }

  Future<void> _removeItem(String title) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(cartProvider.notifier).removeItem(widget.item.id);
      showToast('$title removed from cart');
    } catch (e) {
      showToast('Could not remove item: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateQuantity(String title, int nextQty) async {
    if (_busy) return;
    if (nextQty <= 0 || nextQty < widget.item.minimumQuantity) {
      await _removeItem(title);
      return;
    }
    if (nextQty > widget.item.maxStock) {
      showToast('Maximum available stock reached (${widget.item.maxStock})',
          isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cartProvider.notifier).setQuantity(
            productId: widget.item.productId,
            variantId: widget.item.variantId,
            quantity: nextQty,
          );
      showToast('Updated quantity to $nextQty');
    } catch (e) {
      showToast('Could not update quantity: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showUpgradeConfirmation(
    BuildContext context,
    ComboBundle combo,
  ) async {
    final productName =
        widget.item.product?.name ?? widget.item.comboName ?? 'item';
    final savings = combo.savingAmount > 0
        ? ' (Save ₹${combo.savingAmount.toStringAsFixed(0)})'
        : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Upgrade to Bundle?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will replace "$productName" in your cart with the complete "${combo.name}" bundle$savings at the discounted bundle price.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
            ),
            child: const Text('Upgrade & Replace'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _upgradeToBundle(combo);
    }
  }

  Future<void> _upgradeToBundle(ComboBundle combo) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(cartProvider.notifier).removeItem(widget.item.id);
      await ref.read(cartProvider.notifier).addCombo(
            combo.id,
            comboName: combo.name,
            comboPrice: combo.comboPrice,
            comboImage: combo.image,
          );
      showToast('Upgraded to ${combo.name}! Bundle savings applied.');
    } catch (e) {
      showToast('Could not upgrade to bundle: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final title = item.comboName ?? item.product?.name ?? 'Item';
    final image = item.product?.image ??
        (item.product?.images.isNotEmpty == true
            ? item.product!.images.first
            : null);
    final outOfStock =
        item.comboId == null && (item.product?.inStock == false);
    final upgradeCombo = _findUpgradeCombo();
    final packLabel = item.variant?.name ?? item.product?.size;
    final unitPrice = item.unitPrice;
    final unitMrp = item.variant?.mrp ?? item.product?.mrp;
    final lineTotal = item.lineTotal;
    final mrpTotal = unitMrp != null ? unitMrp * item.quantity : null;
    final hasMrpSaving = mrpTotal != null && mrpTotal > lineTotal;
    final discountPercent = hasMrpSaving
        ? (((mrpTotal - lineTotal) / mrpTotal) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryWashDeep),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1F372F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ProductImageCover(
                    imageUrl: image,
                    borderRadius: BorderRadius.circular(12),
                    innerPadding: const EdgeInsets.all(3),
                    backdropOpacity: 0.85,
                    showPlaceholderOnLoading: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    height: 1.28,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (packLabel != null &&
                                    packLabel.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pack: $packLabel',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (item.minimumQuantity > 1) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryWash,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Min order: ${item.minimumQuantity}',
                                      style: const TextStyle(
                                        color: AppColors.primaryDeep,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                if (outOfStock) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Out of stock',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Remove item',
                            onPressed:
                                _busy ? null : () => _removeItem(title),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: _busy
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.error,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFF8A9B93),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '₹${formatInr(lineTotal)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        color: AppColors.primaryDeepest,
                                      ),
                                    ),
                                    if (hasMrpSaving)
                                      Text(
                                        '₹${formatInr(mrpTotal)}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.mrp,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    if (discountPercent > 0)
                                      Text(
                                        '$discountPercent% OFF',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDeep,
                                        ),
                                      ),
                                  ],
                                ),
                                if (item.quantity > 1) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${formatInr(unitPrice)} × ${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Webapp-style mint rectangular quantity stepper
                          Container(
                            height: 34,
                            width: 92,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F8F5),
                              border:
                                  Border.all(color: const Color(0xFFBDD6C9)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 29,
                                  height: 34,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(7),
                                    ),
                                    onTap: _busy
                                        ? null
                                        : () => _updateQuantity(
                                              title,
                                              item.quantity - 1,
                                            ),
                                    child: Icon(
                                      item.quantity <= item.minimumQuantity
                                          ? Icons.delete_outline_rounded
                                          : Icons.remove,
                                      size: 15,
                                      color: _busy
                                          ? AppColors.textTertiary
                                          : (item.quantity <=
                                                  item.minimumQuantity
                                              ? AppColors.error
                                              : AppColors.brandPrimary),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      border: Border.symmetric(
                                        vertical: BorderSide(
                                          color: Color(0xFFD2E4DB),
                                        ),
                                      ),
                                    ),
                                    child: _busy
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.brandPrimary,
                                            ),
                                          )
                                        : Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12.5,
                                              color: AppColors.brandPrimary,
                                            ),
                                          ),
                                  ),
                                ),
                                SizedBox(
                                  width: 29,
                                  height: 34,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(7),
                                    ),
                                    onTap: _busy
                                        ? null
                                        : () => _updateQuantity(
                                              title,
                                              item.quantity + 1,
                                            ),
                                    child: Icon(
                                      Icons.add,
                                      size: 15,
                                      color: _busy
                                          ? AppColors.textTertiary
                                          : (item.quantity >= item.maxStock
                                              ? AppColors.textTertiary
                                              : AppColors.brandPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Smart "UPGRADE & SAVE" Combo Upgrade Banner
          if (upgradeCombo != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF8F3), Color(0xFFF9FCFA)],
                ),
                border: Border.all(color: const Color(0xFFA7F3D0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => showComboDetailsSheet(
                      context,
                      upgradeCombo,
                      primaryCtaLabel: 'Upgrade to Bundle',
                      onPrimaryAction: () =>
                          _showUpgradeConfirmation(context, upgradeCombo),
                    ),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: ProductImageCover(
                        imageUrl: upgradeCombo.image,
                        borderRadius: BorderRadius.circular(8),
                        innerPadding: const EdgeInsets.all(2),
                        showPlaceholderOnLoading: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => showComboDetailsSheet(
                        context,
                        upgradeCombo,
                        primaryCtaLabel: 'Upgrade to Bundle',
                        onPrimaryAction: () =>
                            _showUpgradeConfirmation(context, upgradeCombo),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF047857),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BUNDLE & SAVE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              if (upgradeCombo.savingAmount > 0)
                                Text(
                                  'Save ₹${upgradeCombo.savingAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF022C22),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            upgradeCombo.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '₹${upgradeCombo.comboPrice.toStringAsFixed(0)} · View items ›',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () =>
                              _showUpgradeConfirmation(context, upgradeCombo),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Upgrade',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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
