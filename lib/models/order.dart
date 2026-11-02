import 'product.dart';

class OrderItem {
  OrderItem({
    required this.id,
    required this.quantity,
    required this.price,
    this.product,
    this.variant,
  });

  final String id;
  final int quantity;
  final double price;
  final Product? product;
  final ProductVariant? variant;

  double get lineTotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'].toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        product: json['product'] != null ? Product.fromJson(json['product']) : null,
        variant: json['variant'] != null ? ProductVariant.fromJson(json['variant']) : null,
      );
}

class Order {
  Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    this.subtotal,
    this.discountAmount,
    this.deliveryCharge,
    required this.status,
    this.recipientName,
    this.shippingAddress,
    this.phone,
    this.paymentMethod,
    this.paymentStatus,
    this.partialCod = false,
    this.advanceAmount,
    this.onlinePaidAmount,
    this.couponCode,
    this.prescriptionId,
    this.awbNumber,
    this.courierName,
    this.trackingStatus,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final double totalAmount;
  final double? subtotal;
  final double? discountAmount;
  final double? deliveryCharge;
  final String status;
  final String? recipientName;
  final String? shippingAddress;
  final String? phone;
  final String? paymentMethod;
  final String? paymentStatus;
  final bool partialCod;
  final double? advanceAmount;
  final double? onlinePaidAmount;
  final String? couponCode;
  final String? prescriptionId;
  final String? awbNumber;
  final String? courierName;
  final String? trackingStatus;
  final DateTime createdAt;
  final List<OrderItem> items;

  bool get isCancelled => status == 'CANCELLED';
  bool get isPaidOnline =>
      (paymentMethod == 'CASHFREE' && paymentStatus == 'PAID') ||
      (partialCod && paymentStatus == 'ADVANCE_PAID');

  double get codDueAmount {
    if (!partialCod) return paymentMethod == 'COD' ? totalAmount : 0.0;
    final paid = onlinePaidAmount ?? advanceAmount ?? 0.0;
    return (totalAmount - paid).clamp(0.0, double.infinity);
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'].toString(),
        orderNumber: json['orderNumber'] ?? json['id'].toString(),
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        subtotal: (json['subtotal'] as num?)?.toDouble(),
        discountAmount: (json['discountAmount'] as num?)?.toDouble(),
        deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble(),
        status: json['status'] ?? 'PENDING',
        recipientName: json['recipientName'],
        shippingAddress: json['shippingAddress'],
        phone: json['phone'],
        paymentMethod: json['paymentMethod'],
        paymentStatus: json['paymentStatus'],
        partialCod: json['partialCod'] == true,
        advanceAmount: (json['advanceAmount'] as num?)?.toDouble(),
        onlinePaidAmount: (json['onlinePaidAmount'] as num?)?.toDouble(),
        couponCode: json['couponCode'],
        prescriptionId: json['prescriptionId']?.toString(),
        awbNumber: json['awbNumber'],
        courierName: json['courierName'],
        trackingStatus: json['trackingStatus'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        items: (json['items'] as List?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
