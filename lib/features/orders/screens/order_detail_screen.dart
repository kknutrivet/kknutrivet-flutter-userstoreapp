import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../widgets/order_items_and_summary.dart';
import '../widgets/order_tracking_and_status.dart';

export '../widgets/order_items_and_summary.dart';
export '../widgets/order_tracking_and_status.dart';

/// Order details orchestrator screen: displays hero status header, delivery
/// journey or cancellation banner, payment details & retry banner, shipment
/// tracking timeline, grouped Care Bundle & item cards, bill summary, delivery
/// address, and pinned WhatsApp/shop support actions at bottom.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(id));

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/orders');
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Order details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: handleBack,
          ),
        ),
        body: SafeArea(
          top: false,
          child: orderAsync.when(
            data: (order) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(orderDetailProvider(id));
                ref.invalidate(orderTrackingProvider(id));
                await ref.read(orderDetailProvider(id).future);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  OrderHeroCard(order: order),
                  const SizedBox(height: 16),
                  if (order.isCancelled)
                    const OrderCancelledBanner()
                  else
                    OrderJourneyTracker(order: order),
                  const SizedBox(height: 16),
                  OrderPaymentCard(order: order),
                  if (order.paymentMethod == 'CASHFREE' &&
                      order.paymentStatus != 'PAID' &&
                      !order.isCancelled)
                    OrderPaymentRetryBanner(order: order),
                  OrderTrackingSection(order: order, orderId: id),
                  const SizedBox(height: 16),
                  OrderItemsCard(order: order),
                  const SizedBox(height: 16),
                  OrderBillSummaryCard(order: order),
                  const SizedBox(height: 16),
                  OrderDeliveryAddressCard(order: order),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(orderDetailProvider(id)),
            ),
          ),
        ),
        bottomNavigationBar: orderAsync.maybeWhen(
          data: (order) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: OrderSupportSection(order: order),
                  ),
                ),
              ),
            ],
          ),
          orElse: () => null,
        ),
      ),
    );
  }
}
