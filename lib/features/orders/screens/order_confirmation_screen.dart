import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../widgets/order_tracking_and_status.dart';
import '../widgets/reorder_reminder_card.dart';

/// Dedicated `/orders/:id/confirmation` screen mirroring
/// `src/app/orders/[id]/confirmation/page.tsx` on mobile web:
/// Order confirmed banner, Order # / Total / Payment Method / Partial COD split,
/// above-the-fold Scratch & Win card, 30-day Refill Reminder, and Track / Shop / WhatsApp actions.
class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: const Color(0xFF07583F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Order Confirmed',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: orderAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'Could not load your order confirmation.',
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (order) {
          final isPartialCod = order.partialCod;
          final paymentLabel = isPartialCod
              ? 'Advance + COD'
              : order.paymentMethod == 'COD'
              ? 'Cash on Delivery'
              : 'Online Payment';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
            children: [
              // Celebratory banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order confirmed',
                      style: AppTheme.serif(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF064E3B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "We're getting everything ready for your animal.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Summary metrics card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _metricTile(
                            'ORDER NUMBER',
                            '#${order.orderNumber}',
                          ),
                        ),
                        Expanded(
                          child: _metricTile(
                            'ORDER TOTAL',
                            '₹${formatInr(order.totalAmount)}',
                            highlight: true,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _metricTile('PAYMENT METHOD', paymentLabel),
                        ),
                        if (isPartialCod && order.advanceAmount != null)
                          Expanded(
                            child: _metricTile(
                              'ADVANCE / ON DELIVERY',
                              '₹${formatInr(order.advanceAmount!)} / ₹${formatInr((order.totalAmount - order.advanceAmount!).clamp(0, order.totalAmount).toDouble())}',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Above-the-fold Scratch & Win card
              OrderScratchToWinCard(order: order),
              const SizedBox(height: 12),

              // 30-day Refill Reminder
              if (!order.isCancelled) ...[
                ReorderReminderCard(orderId: order.id),
                const SizedBox(height: 14),
              ],

              // Primary CTA: Track your order
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Haptics.tap();
                    context.go('/order/${order.id}');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF07583F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.location_on_outlined, size: 18),
                  label: Text(
                    strings.trackYourOrder,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Haptics.tap();
                          context.go('/home');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          strings.continueShopping,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Haptics.tap();
                          final msg = Uri.encodeComponent(
                            'Hi KK Nutrivet! Need help with my order #${order.orderNumber}.',
                          );
                          await launchUrl(
                            Uri.parse('https://wa.me/917846932453?text=$msg'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF15803D),
                          side: const BorderSide(color: Color(0xFF86EFAC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 15),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricTile(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primaryDeep : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
