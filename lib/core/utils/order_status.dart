import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Mirrors nvit-frontend's STATUS_STYLES/STATUS_ICONS/STATUS_DETAILS maps
/// so order status badges/colors/copy match the website exactly.
class OrderStatusInfo {
  const OrderStatusInfo(this.emoji, this.label, this.description, this.color, this.bgColor);
  final String emoji;
  final String label;
  final String description;
  final Color color;
  final Color bgColor;
}

const orderStatusInfo = <String, OrderStatusInfo>{
  'PENDING': OrderStatusInfo(
    '⏳',
    'Pending',
    'Your order has been received and is awaiting confirmation.',
    AppColors.orderPending,
    AppColors.orderPendingBg,
  ),
  'CONFIRMED': OrderStatusInfo(
    '✓',
    'Confirmed',
    'Your order has been confirmed and will be processed soon.',
    AppColors.orderConfirmed,
    AppColors.orderConfirmedBg,
  ),
  'PROCESSING': OrderStatusInfo(
    '📦',
    'Processing',
    'Your order is being packed and prepared for shipment.',
    AppColors.orderPacked,
    AppColors.orderPackedBg,
  ),
  'SHIPPED': OrderStatusInfo(
    '🚚',
    'Shipped',
    'Your order is on the way to you.',
    AppColors.orderShipped,
    AppColors.orderShippedBg,
  ),
  'OUT_FOR_DELIVERY': OrderStatusInfo(
    '🛵',
    'Out for delivery',
    'Your order will be delivered today.',
    AppColors.orderOutForDelivery,
    AppColors.orderOutForDeliveryBg,
  ),
  'DELIVERED': OrderStatusInfo(
    '✅',
    'Delivered',
    'Your order has been delivered successfully.',
    AppColors.orderDelivered,
    AppColors.orderDeliveredBg,
  ),
  'RETURNED': OrderStatusInfo(
    '↩',
    'Returned',
    'This order has been returned.',
    AppColors.orderReturned,
    AppColors.orderReturnedBg,
  ),
  'CANCELLED': OrderStatusInfo(
    '✕',
    'Cancelled',
    'This order has been cancelled.',
    AppColors.orderCancelled,
    AppColors.orderCancelledBg,
  ),
};

OrderStatusInfo statusInfoFor(String status) =>
    orderStatusInfo[status] ??
    const OrderStatusInfo(
      '•',
      'Unknown',
      '',
      AppColors.textTertiary,
      AppColors.surfaceAlt,
    );

/// The linear delivery-journey tracker steps, in order — matches
/// nvit-frontend's STATUS_STEPS. CANCELLED/RETURNED aren't part of this
/// timeline; the order detail screen swaps in a banner for those instead.
const orderTrackerSteps = [
  ('PENDING', 'Order received', 'Received'),
  ('CONFIRMED', 'Confirmed', 'Confirmed'),
  ('PROCESSING', 'Being packed', 'Packed'),
  ('SHIPPED', 'On the way', 'Shipped'),
  ('OUT_FOR_DELIVERY', 'Out for delivery', 'Out for delivery'),
  ('DELIVERED', 'Delivered', 'Delivered'),
];
