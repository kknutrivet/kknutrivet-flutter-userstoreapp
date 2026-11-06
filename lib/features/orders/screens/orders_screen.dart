import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/order_status.dart';
import '../../../core/widgets/common.dart';
import '../../../models/order.dart';
import '../../../providers/app_providers.dart';

final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.read(orderServiceProvider).fetchOrders();
});

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _selectedFilter = 'All';

  static const _filters = ['All', 'In Transit', 'Delivered', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.homeCanvas,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
          title: Text(
            'My Orders',
            style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppEmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'No orders yet',
                      description:
                          'When you place orders for pet food, medicines or veterinary bundles, you can track their live status here.',
                      actionLabel: 'Start Shopping',
                      onAction: () => context.go('/products'),
                    ),
                  ),
                );
              }

              final filteredOrders = orders.where((o) {
                if (_selectedFilter == 'All') return true;
                final s = o.status.toUpperCase();
                if (_selectedFilter == 'In Transit') {
                  return s == 'CONFIRMED' ||
                      s == 'PROCESSING' ||
                      s == 'PACKED' ||
                      s == 'DISPATCHED' ||
                      s == 'SHIPPED';
                }
                if (_selectedFilter == 'Delivered') {
                  return s == 'DELIVERED';
                }
                if (_selectedFilter == 'Cancelled') {
                  return s == 'CANCELLED' || s == 'RETURNED';
                }
                return true;
              }).toList();

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(ordersProvider);
                  await ref.read(ordersProvider.future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Filter chips
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: _filters.map((f) {
                            final sel = _selectedFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: sel,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: sel
                                      ? AppColors.primaryDeep
                                      : AppColors.textSecondary,
                                ),
                                selectedColor: AppColors.primaryWash,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: sel
                                        ? AppColors.primary
                                        : AppColors.borderWarm,
                                  ),
                                ),
                                onSelected: (_) {
                                  AppHaptics.selection();
                                  setState(() => _selectedFilter = f);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    if (filteredOrders.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 48,
                          ),
                          child: AppEmptyState(
                            icon: Icons.filter_alt_off_outlined,
                            title: 'No $_selectedFilter orders',
                            description:
                                'You do not have any orders matching the "$_selectedFilter" status filter.',
                            actionLabel: 'Show All Orders',
                            onAction: () =>
                                setState(() => _selectedFilter = 'All'),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OrderCard(order: filteredOrders[i]),
                            ),
                            childCount: filteredOrders.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: AppLoader.large()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to load orders',
                  description: e.toString(),
                  actionLabel: 'Try Again',
                  onAction: () => ref.invalidate(ordersProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final info = statusInfoFor(order.status);
    final isOnline = order.paymentMethod == 'CASHFREE' || order.partialCod;
    final paid =
        order.paymentStatus == 'PAID' || order.paymentStatus == 'ADVANCE_PAID';
    final payFailed =
        isOnline &&
        (order.paymentStatus == 'FAILED' ||
            order.paymentStatus == 'USER_DROPPED');
    final payPending = isOnline && !paid && !payFailed;
    final visibleItems = order.items.take(4).toList();
    final extraCount = order.items.length - visibleItems.length;

    final (statusLabel, statusTone) = payFailed
        ? ('Payment Failed', AppBadgeTone.coral)
        : payPending
        ? ('Payment Pending', AppBadgeTone.amber)
        : (info.label, _toneFromStatus(order.status));

    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(16),
      onTap: () {
        AppHaptics.light();
        context.push('/order/${order.id}');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AppBadge(label: statusLabel, tone: statusTone),
              const SizedBox(width: 10),
              Text(
                formatPrice(order.totalAmount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final item in visibleItems)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: item.product?.image != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.product!.image!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppColors.primaryWash,
                                      child: const Icon(
                                        Icons.pets,
                                        size: 18,
                                        color: AppColors.primaryDeep,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 170,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.product?.name ?? 'Item',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (extraCount > 0)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryWash,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$extraCount more',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const Divider(height: 22, color: AppColors.borderWarmSoft),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDate(order.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Row(
                children: [
                  Text(
                    'View order',
                    style: TextStyle(
                      color: AppColors.primaryDeep,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.primaryDeep,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBadgeTone _toneFromStatus(String status) {
    return switch (status.toUpperCase()) {
      'DELIVERED' => AppBadgeTone.emerald,
      'SHIPPED' || 'DISPATCHED' => AppBadgeTone.blue,
      'CANCELLED' || 'RETURNED' => AppBadgeTone.coral,
      'CONFIRMED' || 'PROCESSING' || 'PACKED' => AppBadgeTone.amber,
      _ => AppBadgeTone.neutral,
    };
  }
}
