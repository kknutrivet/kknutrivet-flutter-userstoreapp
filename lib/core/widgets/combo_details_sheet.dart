import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/product.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/haptics.dart';
import 'app_network_image.dart';
import 'common.dart';

Future<void> showComboDetailsSheet(
  BuildContext context,
  ComboBundle combo, {
  String? primaryCtaLabel,
  VoidCallback? onPrimaryAction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ComboDetailsSheet(
      combo: combo,
      primaryCtaLabel: primaryCtaLabel,
      onPrimaryAction: onPrimaryAction,
    ),
  );
}

class ComboDetailsSheet extends ConsumerStatefulWidget {
  const ComboDetailsSheet({
    super.key,
    required this.combo,
    this.primaryCtaLabel,
    this.onPrimaryAction,
  });

  final ComboBundle combo;
  final String? primaryCtaLabel;
  final VoidCallback? onPrimaryAction;

  @override
  ConsumerState<ComboDetailsSheet> createState() => _ComboDetailsSheetState();
}

class _ComboDetailsSheetState extends ConsumerState<ComboDetailsSheet> {
  bool _busy = false;

  Future<void> _updateBundleQty(int nextQty) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      Haptics.tap();
      final currentQty = ref.read(comboCartQuantityProvider(widget.combo.id));
      if (currentQty == 0 && nextQty > 0) {
        await ref.read(cartProvider.notifier).addCombo(
          widget.combo.id,
          comboName: widget.combo.name,
          comboPrice: widget.combo.comboPrice,
          comboImage: widget.combo.image,
        );
        showToast('${widget.combo.name} bundle added to cart!');
      } else if (nextQty == 0) {
        await ref
            .read(cartProvider.notifier)
            .setComboQuantity(widget.combo.id, 0);
        showToast('${widget.combo.name} bundle removed from cart');
      } else {
        await ref
            .read(cartProvider.notifier)
            .setComboQuantity(widget.combo.id, nextQty);
        showToast('Updated bundle quantity to $nextQty');
      }
    } catch (e) {
      showToast('Could not update bundle: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.combo;
    final qtyInCart = ref.watch(comboCartQuantityProvider(combo.id));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (combo.image != null && combo.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AppNetworkImage(
                      imageUrl: combo.image,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _bundleFallbackIcon(),
                    ),
                  )
                else
                  _bundleFallbackIcon(),
                const SizedBox(width: 14),
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
                                fontSize: 10,
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
                                'SAVE ${combo.savingPercent}% (${formatPrice(combo.savingAmount)})',
                                style: const TextStyle(
                                  fontSize: 10,
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
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (combo.description != null &&
                          combo.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          combo.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                IconButton(
                  tooltip: 'Close',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              itemCount: combo.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = combo.items[index];
                final p = item.product;
                final title = p?.name ?? 'Bundle item ${index + 1}';
                final imageUrl = p?.image;
                final slugOrId = (p?.slug.isNotEmpty == true)
                    ? p!.slug
                    : (p?.id ?? item.productId);

                return Material(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: slugOrId.isEmpty
                        ? null
                        : () {
                            Haptics.tap();
                            Navigator.of(context).pop();
                            context.push('/product/$slugOrId');
                          },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.borderSubtle,
                              ),
                            ),
                            child: AppNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(9),
                              fallbackIcon: Icons.medication_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryWashFaint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Qty: ${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDeep,
                                        ),
                                      ),
                                    ),
                                    if (p?.size != null &&
                                        p!.size!.isNotEmpty)
                                      Text(
                                        p.size!,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BUNDLE PRICE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            formatPrice(combo.comboPrice),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeepest,
                            ),
                          ),
                          if (combo.originalPrice > combo.comboPrice) ...[
                            const SizedBox(width: 8),
                            Text(
                              formatPrice(combo.originalPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mrp,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.onPrimaryAction != null)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onPrimaryAction!();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(160, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(widget.primaryCtaLabel ?? 'Upgrade to Bundle'),
                    ),
                  )
                else if (qtyInCart > 0)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decrease bundle quantity',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: _busy
                              ? null
                              : () => _updateBundleQty(qtyInCart - 1),
                          icon: const Icon(
                            Icons.remove_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
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
                                    fontSize: 13.5,
                                  ),
                                ),
                        ),
                        IconButton(
                          tooltip: 'Increase bundle quantity',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: _busy
                              ? null
                              : () => _updateBundleQty(qtyInCart + 1),
                          icon: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              if (widget.onPrimaryAction != null) {
                                Navigator.of(context).pop();
                                widget.onPrimaryAction!();
                              } else {
                                _updateBundleQty(1);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(156, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.shopping_bag_outlined,
                              size: 18, color: Colors.white),
                      label: Text(widget.primaryCtaLabel ?? 'Add Bundle'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bundleFallbackIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primaryDeep,
        size: 28,
      ),
    );
  }
}
