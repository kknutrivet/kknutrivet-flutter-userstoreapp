import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/widgets/home_combos_and_rx.dart'
    show homeComboLookupProvider;
import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../i18n/app_language.dart';
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
    this.singleLineTitle = false,
    this.heroTag,
  });

  final Product product;
  final CompactCardVariant variant;
  final bool singleLineTitle;
  final String? heroTag;

  @override
  ConsumerState<CompactProductCard> createState() => _CompactProductCardState();
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

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final product = widget.product;
    final v = _resolveVariant(product);
    final quantity = ref.watch(cartQuantityProvider((product.id, v?.id)));
    final comboHint = ref.watch(homeComboLookupProvider)[product.id];
    final image =
        product.image ??
        (product.images.isNotEmpty ? product.images.first : null);
    final isCatalogue = widget.variant == CompactCardVariant.catalogue;
    final displayPrice = v?.price ?? product.effectivePrice;
    final displayMrp = v?.mrp ?? product.mrp;
    final inStock = v != null ? v.stock > 0 : product.inStock;
    final hasDiscount = displayMrp != null && displayMrp > displayPrice;
    final discountPercent = hasDiscount
        ? (((displayMrp - displayPrice) / displayMrp) * 100).round()
        : 0;
    final highlightBadge = product.resolvedHighlightBadge;

    return AppBounce(
      pressedScale: 0.975,
      onTap: () => context.push(
        '/product/${product.slug.isNotEmpty ? product.slug : product.id}',
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE8E1), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1214382B),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Material(
            color: Colors.white,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTightHeight =
                    constraints.hasBoundedHeight && constraints.maxHeight <= 226;
                final coverWidget = ProductImageCover(
                  imageUrl: image,
                  showPlaceholderOnLoading: false,
                  enableBackdrop: true,
                  backdropOpacity: 0.78,
                  blurSigma: 13,
                  fit: BoxFit.contain,
                  innerPadding: const EdgeInsets.all(6),
                  backgroundColor: const Color(0xFFF6FAF7),
                  borderRadius: BorderRadius.circular(10),
                );
                final imageStack = Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: widget.heroTag != null
                            ? Hero(tag: widget.heroTag!, child: coverWidget)
                            : coverWidget,
                      ),
                      if (!inStock)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F5),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Sold out',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (hasDiscount &&
                          discountPercent > 0 &&
                          !product.requiresPrescription)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECF7EF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCEE4D5)),
                            ),
                            child: Text(
                              '$discountPercent% OFF',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF176441),
                                height: 1.15,
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
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rxBg,
                              border: Border.all(color: AppColors.rxBorder),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Rx required',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.rxText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      if (product.ratingCount > 0)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFD5E6DC),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x10000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${product.ratingAverage.toStringAsFixed(1)} ★',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '(${product.ratingCount})',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xC4142D24),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.visibility_outlined,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  product.formattedViewsLabel,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (constraints.hasBoundedHeight)
                      Expanded(child: imageStack)
                    else
                      AspectRatio(aspectRatio: 1.18, child: imageStack),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        10,
                        isTightHeight ? 6 : 8,
                        10,
                        isTightHeight ? 8 : 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (comboHint != null && !isTightHeight) ...[
                            GestureDetector(
                              onTap: () {
                                Haptics.tap();
                                context.push('/combos/${comboHint.id}');
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF8F2),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFCBE6D6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.card_giftcard_rounded,
                                      size: 10,
                                      color: Color(0xFF07583F),
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        comboHint.savings > 0
                                            ? 'Combo · Save ₹${comboHint.savings}'
                                            : 'Combo available',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF07583F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (highlightBadge != null && !isTightHeight) ...[
                            _HighlightBadgePill(badge: highlightBadge),
                          ],
                          Text(
                            product.localizedName(locale.code),
                            maxLines: widget.singleLineTitle ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCatalogue ? 13.5 : 13.5,
                              height: 1.24,
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
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 20),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Pack: ${v?.name ?? (product.basePackLabel.isNotEmpty ? product.basePackLabel : 'Choose pack')} · ${buildPackOptions(product).length} sizes ▾',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF07583F),
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
                                fontSize: 11.5,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          SizedBox(height: isTightHeight ? 6 : 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${formatInr(displayPrice)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDeep,
                                      ),
                                    ),
                                    if (hasDiscount)
                                      Text(
                                        '₹${formatInr(displayMrp)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          height: 1.12,
                                          color: AppColors.mrp,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                height: 34,
                                width: quantity > 0
                                    ? 80
                                    : (!inStock || product.onlyForCombo ? 88 : 70),
                                child: _CompactAddButton(
                                  product: product,
                                  variant: v,
                                  quantity: quantity,
                                  outlined: false,
                                  onVariantChanged: (picked) => setState(
                                    () => _selectedVariantId = picked.id,
                                  ),
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
      ),
    );
  }
}

class _HighlightBadgePill extends StatelessWidget {
  const _HighlightBadgePill({required this.badge});

  final ProductHighlightBadge badge;

  static (Color bg, Color border, Color fg) _paletteFor(String tone) {
    switch (tone) {
      case 'fire':
        return (
          const Color(0xFFFFF7ED),
          const Color(0xFFFED7AA),
          const Color(0xFF9A3412),
        );
      case 'views':
        return (
          const Color(0xFFEFF6FF),
          const Color(0xFFBFDBFE),
          const Color(0xFF1E40AF),
        );
      case 'pet':
        return (
          const Color(0xFFF5F3FF),
          const Color(0xFFDDD6FE),
          const Color(0xFF5B21B6),
        );
      case 'vet':
        return (
          const Color(0xFFF0FDFA),
          const Color(0xFF99F6E4),
          const Color(0xFF115E59),
        );
      case 'new':
        return (
          const Color(0xFFF7FEE7),
          const Color(0xFFBEF264),
          const Color(0xFF3F6212),
        );
      case 'farmer':
      default:
        return (
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          const Color(0xFF065F46),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = _paletteFor(badge.tone);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        badge.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

/// Reserve space for readable names, highlight badges, pack details and controls.
double productCardExtent(BuildContext context) {
  final width = (MediaQuery.sizeOf(context).width - 44) / 2;
  return width / 1.18 + 114 + 54 * MediaQuery.textScalerOf(context).scale(1);
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
  ConsumerState<_CompactAddButton> createState() => _CompactAddButtonState();
}

class _CompactAddButtonState extends ConsumerState<_CompactAddButton> {
  bool _busy = false;
  bool _notified = false;

  Future<void> _handleNotifyMe() async {
    if (_busy || _notified) return;
    final user = ref.read(authProvider).valueOrNull;
    if (user == null || user.isAnonymous) {
      Haptics.tap();
      context.push('/login');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(catalogServiceProvider).saveStockAlert(widget.product.id);
      AppHaptics.success();
      if (mounted) {
        setState(() => _notified = true);
        showToast("We'll notify you when ${widget.product.name} is back in stock");
      }
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
        final nextQty = widget.quantity <= minQty ? 0 : widget.quantity + delta;
        AppHaptics.step();
        await ref
            .read(cartProvider.notifier)
            .setQuantity(
              productId: widget.product.id,
              variantId: v?.id,
              quantity: nextQty,
            );
      } else if (widget.quantity == 0) {
        await ref
            .read(cartProvider.notifier)
            .addItem(
              productId: widget.product.id,
              variantId: v?.id,
              quantity: minQty,
              product: widget.product,
              variant: v,
            );
        AppHaptics.cart();
      } else {
        AppHaptics.step();
        await ref
            .read(cartProvider.notifier)
            .setQuantity(
              productId: widget.product.id,
              variantId: v?.id,
              quantity: widget.quantity + delta,
            );
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
                    fontSize: 12,
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
      return Semantics(
        button: true,
        label: _notified
            ? "We'll notify you when ${product.name} is back"
            : 'Notify me when ${product.name} is back in stock',
        child: AppBounce(
          pressedScale: 0.95,
          onTap: _busy || _notified ? null : _handleNotifyMe,
          child: Container(
            decoration: BoxDecoration(
              color: _notified ? const Color(0xFFFFF8F6) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _notified
                    ? const Color(0xFFF3D2C8)
                    : const Color(0xFFD6E0DA),
              ),
            ),
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFA8553F),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _notified
                              ? Icons.check_rounded
                              : Icons.notifications_none_rounded,
                          size: 13,
                          color: _notified
                              ? const Color(0xFFA8553F)
                              : AppColors.primaryDeep,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _notified ? "We'll notify you" : 'Notify Me',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _notified
                                  ? const Color(0xFFA8553F)
                                  : AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    final hasMultipleVariants = product.variants.length > 1;

    final Widget buttonWidget;
    if (widget.quantity > 0) {
      const Color bg = Color(0xFF07583F);
      const Color fg = Colors.white;

      buttonWidget = Container(
        key: const ValueKey('stepper'),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.24),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Decrease quantity of ${product.name}',
                child: AppBounce(
                  pressedScale: 0.85,
                  onTap: _busy ? null : () => _updateQuantity(-1),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: const Icon(Icons.remove, size: 14, color: fg),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: _busy
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Text(
                      '${widget.quantity}',
                      style: const TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, size: 14, color: fg),
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
              color: const Color(0xFFEEF7F2),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFF07583F).withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Center(
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF07583F),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!hasMultipleVariants) ...[
                          const Icon(
                            Icons.add,
                            size: 13,
                            color: Color(0xFF07583F),
                          ),
                          const SizedBox(width: 2),
                        ],
                        const Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF07583F),
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (hasMultipleVariants) ...[
                          const SizedBox(width: 1),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Color(0xFF07583F),
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
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF07583F).withValues(alpha: 0.24),
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
                        const Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (hasMultipleVariants) ...[
                          const SizedBox(width: 2),
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
