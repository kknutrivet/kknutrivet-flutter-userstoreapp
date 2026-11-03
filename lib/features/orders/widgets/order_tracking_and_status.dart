import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/order_status.dart';
import '../../../core/widgets/common.dart';
import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../../checkout/screens/cashfree_checkout_screen.dart';
import 'order_items_and_summary.dart';

final orderDetailProvider =
    FutureProvider.autoDispose.family<Order, String>((ref, id) {
  return ref.read(orderServiceProvider).fetchOrder(id);
});

final orderTrackingProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) {
  return ref.read(orderServiceProvider).fetchTracking(id);
});

/// Dark hero card: order number, placed date, total, invoice + current status.
class OrderHeroCard extends StatelessWidget {
  const OrderHeroCard({super.key, required this.order});
  final Order order;

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return Icons.check_rounded;
      case 'PENDING':
        return Icons.hourglass_top_rounded;
      case 'PROCESSING':
        return Icons.inventory_2_outlined;
      case 'SHIPPED':
        return Icons.local_shipping_outlined;
      case 'OUT_FOR_DELIVERY':
        return Icons.delivery_dining_outlined;
      case 'DELIVERED':
        return Icons.task_alt_rounded;
      case 'CANCELLED':
        return Icons.close_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = statusInfoFor(order.status);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(18),
      ),
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
                    const Text(
                      'ORDER DETAILS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Placed on ${formatDate(order.createdAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.isPaidOnline ? 'Total paid' : 'Order total',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPrice(order.totalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 26),
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _statusIcon(order.status),
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      info.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Banner shown when the order has been cancelled.
class OrderCancelledBanner extends StatelessWidget {
  const OrderCancelledBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.error),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Order cancelled. Please contact us if you need any help with this order.',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4-milestone delivery journey tracker: Placed -> Packed -> Shipped -> Delivered.
/// Clean, spacious, and modern layout that prevents awkward text wrapping on mobile.
class OrderJourneyTracker extends StatelessWidget {
  const OrderJourneyTracker({super.key, required this.order});
  final Order order;

  int _getCompletedCount(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 0;
      case 'CONFIRMED':
        return 1;
      case 'PROCESSING':
      case 'PACKED':
        return 2;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return 3;
      case 'DELIVERED':
        return 4;
      default:
        return 1;
    }
  }

  static const _milestones = [
    ('Placed', Icons.receipt_long_outlined),
    ('Packed', Icons.inventory_2_outlined),
    ('Shipped', Icons.local_shipping_outlined),
    ('Delivered', Icons.home_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final completedCount = _getCompletedCount(order.status);
    final info = statusInfoFor(order.status);

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery journey',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track your order progress',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: info.bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  info.label,
                  style: TextStyle(
                    color: info.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final stepWidth = totalWidth / 4;
              final firstCenter = stepWidth / 2;
              final lastCenter = totalWidth - (stepWidth / 2);
              final fillRatio = (completedCount >= 4 ? 1.0 : (completedCount / 3.0)).clamp(0.0, 1.0);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background gray track
                  Positioned(
                    top: 14.5,
                    left: firstCenter,
                    right: firstCenter,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Completed green track
                  Positioned(
                    top: 14.5,
                    left: firstCenter,
                    child: Container(
                      height: 3,
                      width: (lastCenter - firstCenter) * fillRatio,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Step items
                  Row(
                    children: List.generate(4, (index) {
                      final isDone = index < completedCount;
                      final isActive = index == completedCount;
                      final step = _milestones[index];

                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? AppColors.primary
                                    : (isActive ? Colors.white : const Color(0xFFF3F4F6)),
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.primary
                                      : (isActive ? AppColors.primary : const Color(0xFFD1D5DB)),
                                  width: isActive ? 2.5 : 1.5,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : Icon(
                                        step.$2,
                                        size: 16,
                                        color: isActive
                                            ? AppColors.primary
                                            : const Color(0xFF9CA3AF),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.$1,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w800
                                    : (isDone ? FontWeight.w600 : FontWeight.w500),
                                color: (isDone || isActive)
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Current status highlight box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: info.bgColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: info.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  info.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: info.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.description,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
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
}

/// Payment details card showing method, status, and amount.
class OrderPaymentCard extends StatelessWidget {
  const OrderPaymentCard({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OrderDetailCard(
        title: 'Payment details',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _stat(
                    'Method',
                    order.partialCod
                        ? 'Advance + COD'
                        : order.paymentMethod == 'CASHFREE'
                            ? 'Online Payment'
                            : 'Cash on Delivery',
                  ),
                ),
                Expanded(
                  child: _stat(
                    'Status',
                    order.paymentStatus == 'PAID'
                        ? 'Paid'
                        : order.paymentStatus == 'ADVANCE_PAID'
                            ? 'Advance Paid'
                            : order.paymentStatus == 'FAILED'
                                ? 'Failed'
                                : order.paymentMethod == 'COD'
                                    ? 'Pending'
                                    : (order.paymentStatus ?? 'Pending'),
                    color: (order.paymentStatus == 'PAID' ||
                            order.paymentStatus == 'ADVANCE_PAID')
                        ? AppColors.primary
                        : order.paymentStatus == 'FAILED'
                            ? AppColors.error
                            : AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _stat('Amount', formatPrice(order.totalAmount)),
                ),
              ],
            ),
            if (order.partialCod) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Advance ${order.onlinePaidAmount != null || order.paymentStatus == 'ADVANCE_PAID' ? "paid" : "due"}: ${formatPrice(order.onlinePaidAmount ?? order.advanceAmount ?? 0)} · On delivery: ${formatPrice(order.codDueAmount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Shipment tracking timeline section.
class OrderTrackingSection extends ConsumerWidget {
  const OrderTrackingSection({
    super.key,
    required this.order,
    required this.orderId,
  });

  final Order order;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(orderTrackingProvider(orderId));
    return trackingAsync.maybeWhen(
      data: (tracking) {
        final shipped = tracking['shipped'] == true;
        final awb = tracking['awbNumber']?.toString() ?? order.awbNumber;
        if (!shipped || awb == null) return const SizedBox.shrink();

        final events = (tracking['events'] as List?) ?? const [];
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
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
                const Text(
                  'Tracking information',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tracking number',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            awb,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tracking['courierName'] != null ||
                        order.courierName != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Courier',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${tracking['courierName'] ?? order.courierName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (tracking['trackingStatus'] != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${tracking['trackingStatus']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (events.isNotEmpty) ...[
                  const Divider(height: 24),
                  ...events.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    final status = e is Map
                        ? (e['status'] ?? e['description'] ?? 'Update')
                            .toString()
                        : '$e';
                    final location =
                        e is Map ? (e['location'] ?? '').toString() : '';
                    final time = e is Map
                        ? (e['timestamp'] ?? e['updatedAt'] ?? '').toString()
                        : '';
                    final isLast = i == events.length - 1;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == 0
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 1.5,
                                    color: AppColors.border,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (location.isNotEmpty || time.isNotEmpty)
                                    Text(
                                      [location, time]
                                          .where((s) => s.isNotEmpty)
                                          .join(' · '),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Inline retry for an order whose online payment never completed — mirrors
/// the website's "Complete online payment" alert in the order summary aside.
class OrderPaymentRetryBanner extends ConsumerStatefulWidget {
  const OrderPaymentRetryBanner({super.key, required this.order});
  final Order order;

  @override
  ConsumerState<OrderPaymentRetryBanner> createState() =>
      _OrderPaymentRetryBannerState();
}

class _OrderPaymentRetryBannerState
    extends ConsumerState<OrderPaymentRetryBanner> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      final session = await ref
          .read(orderServiceProvider)
          .createCashfreeOrder(widget.order.id);
      if (!mounted) return;

      final returned = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CashfreeCheckoutScreen(
            paymentSessionId: session['paymentSessionId'] as String,
            orderId: widget.order.id,
            mode: session['mode'] as String? ?? 'production',
          ),
        ),
      );
      if (!mounted || returned != true) return;

      final merchantOrderId =
          (session['orderId'] as String?)?.isNotEmpty == true
              ? session['orderId'] as String
              : (widget.order.cashfreeMerchantOrderId?.isNotEmpty == true
                  ? widget.order.cashfreeMerchantOrderId!
                  : widget.order.orderNumber);

      final result = await ref
          .read(orderServiceProvider)
          .verifyCashfreePayment(merchantOrderId);
      if (!mounted) return;
      final isPaid = result['paid'] == true ||
          result['confirmed'] == true ||
          result['status'] == 'PAID' ||
          result['status'] == 'ADVANCE_PAID' ||
          result['status'] == 'SUCCESS';
      if (isPaid) {
        final partial = widget.order.paymentMethod == 'PARTIAL_COD';
        AnalyticsService.instance.logPurchase(orderId: widget.order.id, value: partial ? (widget.order.advanceAmount ?? 0) : widget.order.totalAmount, paymentMethod: partial ? 'advance' : 'prepaid');
        showToast('Payment confirmed');
      } else {
        showToast('Payment not confirmed yet', isError: true);
      }
      ref.invalidate(orderDetailProvider(widget.order.id));
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = widget.order.paymentStatus == 'FAILED' ||
        widget.order.paymentStatus == 'USER_DROPPED';
    final color = failed ? AppColors.error : AppColors.orderPending;
    final bg = failed ? AppColors.errorBg : AppColors.orderPendingBg;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              failed ? Icons.error_outline : Icons.hourglass_bottom,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                failed
                    ? "Payment wasn't completed for this order"
                    : 'Payment is still pending for this order',
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : _retry,
              child: _busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.order.paymentMethod == 'PARTIAL_COD' ? 'Pay advance' : 'Complete payment',
                      style: TextStyle(fontSize: 12.5),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
