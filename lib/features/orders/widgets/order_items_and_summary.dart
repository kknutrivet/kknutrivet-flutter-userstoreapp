import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

/// Shared elevated card wrapper used across Order Detail sections.
class OrderDetailCard extends StatelessWidget {
  const OrderDetailCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Grouped Care Bundle & standalone order items card with "Shop again" action.
class OrderItemsCard extends ConsumerWidget {
  const OrderItemsCard({super.key, required this.order});
  final Order order;

  String? _extractComboId(OrderItem item) {
    final val = item.comboId;
    if (val != null && val.trim().isNotEmpty) return val.trim();
    return null;
  }

  String? _extractComboName(OrderItem item) {
    final val = item.comboName;
    if (val != null && val.trim().isNotEmpty) return val.trim();
    return null;
  }

  /// Resolves a bundle grouping key (`comboId` or `comboName`, or a matched
  /// `ComboBundle` from `homeCombosProvider` when `onlyForCombo` items are present).
  (String key, String name, String? coverImage)? _resolveItemBundleInfo(
    OrderItem item,
    List<OrderItem> allItems,
    List<ComboBundle> combos,
  ) {
    final cid = _extractComboId(item);
    final cname = _extractComboName(item);
    if (cid != null || cname != null) {
      final matched = cid != null
          ? combos.where((c) => c.id == cid).firstOrNull
          : combos
                .where(
                  (c) => c.name.toLowerCase() == cname!.toLowerCase(),
                )
                .firstOrNull;
      return (
        cid ?? cname!,
        cname ?? matched?.name ?? 'Care Combo Bundle',
        matched?.image,
      );
    }
    if (item.product?.onlyForCombo == true) {
      final pid = item.product?.id;
      final matched = pid == null
          ? null
          : combos
                .where((c) => c.items.any((ci) => ci.productId == pid))
                .firstOrNull;
      if (matched != null) {
        return (matched.id, matched.name, matched.image);
      }
      return ('__care_bundle__', 'Care Combo Bundle', null);
    }
    return null;
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      for (final item in order.items) {
        await cartNotifier.addItem(
          productId: item.product?.id ?? item.id,
          quantity: item.quantity,
        );
      }
      if (!context.mounted) return;
      showToast('Items added to cart');
      context.push('/cart');
    } catch (e) {
      if (!context.mounted) return;
      showToast(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combos = ref.watch(homeCombosProvider).value ?? const <ComboBundle>[];

    // Group items that share a comboId or comboName.
    final bundleGroups = <String, List<OrderItem>>{};
    final bundleMeta = <String, (String name, String? coverImage)>{};
    final itemBundleKeys = <String, String>{};

    for (final item in order.items) {
      final info = _resolveItemBundleInfo(item, order.items, combos);
      if (info != null) {
        final (key, name, cover) = info;
        itemBundleKeys[item.id] = key;
        bundleGroups.putIfAbsent(key, () => []).add(item);
        bundleMeta.putIfAbsent(key, () => (name, cover));
      }
    }

    final renderedBundles = <String>{};
    final children = <Widget>[];

    for (final item in order.items) {
      final bKey = itemBundleKeys[item.id];
      if (bKey != null) {
        if (renderedBundles.add(bKey)) {
          final group = bundleGroups[bKey]!;
          final meta = bundleMeta[bKey]!;
          children.add(
            OrderComboBundleGroupCard(
              bundleName: meta.$1,
              coverImage: meta.$2 ?? group.first.product?.image,
              members: group,
            ),
          );
        }
      } else {
        children.add(OrderStandaloneItemRow(item: item));
      }
    }

    final displayCount =
        order.items.length -
        itemBundleKeys.length +
        bundleGroups.length;

    return OrderDetailCard(
      title: 'Items ($displayCount)',
      trailing: TextButton(
        onPressed: () => _reorder(context, ref),
        child: const Text('Shop again', style: TextStyle(fontSize: 12.5)),
      ),
      child: Column(children: children),
    );
  }
}

/// Grouped Care Bundle card inside Order Details.
class OrderComboBundleGroupCard extends StatelessWidget {
  const OrderComboBundleGroupCard({
    super.key,
    required this.bundleName,
    required this.coverImage,
    required this.members,
  });

  final String bundleName;
  final String? coverImage;
  final List<OrderItem> members;

  @override
  Widget build(BuildContext context) {
    final cover = coverImage;
    final double rawPrice = members
        .map((m) => m.comboPrice ?? 0.0)
        .fold(0.0, (max, p) => p > max ? p : max);
    final int qty = members.first.comboQuantity ?? 1;
    final double bundleTotal = rawPrice > 0
        ? rawPrice * qty
        : members.fold<double>(0, (sum, m) => sum + m.lineTotal);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryWashFaint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryWashDeep),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: cover != null && cover.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primaryWash,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primaryDeep,
                            size: 22,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWash,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'CARE BUNDLE · ${members.length} ITEMS',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDeep,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bundleName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatPrice(bundleTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primaryDeepest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.primaryWashDeep),
          const SizedBox(height: 8),
          ...members.map((member) {
            final packLabel = member.variant?.name ?? member.product?.size;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: member.product?.image != null
                            ? CachedNetworkImage(
                                imageUrl: member.product!.image!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.background,
                                child: const Icon(
                                  Icons.pets,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.product?.name ?? 'Bundle item',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${packLabel != null && packLabel.isNotEmpty ? '$packLabel · ' : ''}×${member.quantity}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Standalone item row inside Order Details.
class OrderStandaloneItemRow extends StatelessWidget {
  const OrderStandaloneItemRow({super.key, required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: item.product?.image != null
                  ? CachedNetworkImage(
                      imageUrl: item.product!.image!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.background,
                      child: const Icon(
                        Icons.pets,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? 'Item',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                if (item.variant != null)
                  Text(
                    item.variant!.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Qty ${item.quantity} · ${formatPrice(item.price)} each',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPrice(item.lineTotal),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

/// Order bill summary card (subtotal, coupon/discount, delivery, total).
class OrderBillSummaryCard extends StatelessWidget {
  const OrderBillSummaryCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return OrderDetailCard(
      title: 'Order summary',
      child: Column(
        children: [
          if (order.subtotal != null) _priceRow('Subtotal', order.subtotal!),
          if (order.discountAmount != null && order.discountAmount! > 0)
            _priceRow(
              order.couponCode != null
                  ? 'Coupon (${order.couponCode})'
                  : 'Discount',
              -order.discountAmount!,
              valueColor: AppColors.primary,
            ),
          _priceRow(
            'Delivery',
            order.deliveryCharge ?? 0,
            isFree: (order.deliveryCharge ?? 0) == 0,
          ),
          const Divider(height: 20),
          _priceRow(
            order.isPaidOnline ? 'Total paid' : 'Total',
            order.totalAmount,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    double value, {
    bool bold = false,
    bool isFree = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontSize: bold ? 15 : 13.5,
            ),
          ),
          Text(
            isFree ? 'FREE' : formatPrice(value),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 15 : 13.5,
              color: isFree ? AppColors.primary : valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Delivery address card in Order Details.
class OrderDeliveryAddressCard extends StatelessWidget {
  const OrderDeliveryAddressCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return OrderDetailCard(
      title: 'Delivery address',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.recipientName != null)
                  Text(
                    order.recipientName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                if (order.shippingAddress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.shippingAddress!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (order.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.phone!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Support section with "Continue shopping" and "Chat on WhatsApp" cards.
class OrderSupportSection extends StatelessWidget {
  const OrderSupportSection({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.go('/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.storefront_outlined, color: AppColors.primary),
                    SizedBox(height: 6),
                    Text(
                      'Continue shopping',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: AppColors.whatsAppGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => launchUrl(
                Uri.parse(
                  'https://wa.me/917846932453?text=${Uri.encodeComponent('Hi, I need help with my order #${order.orderNumber}')}',
                ),
                mode: LaunchMode.externalApplication,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.whatsAppGreen.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat, color: AppColors.whatsAppGreen),
                    SizedBox(height: 6),
                    Text(
                      'Chat on WhatsApp',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
