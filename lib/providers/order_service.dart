import '../core/network/api_client.dart';
import '../models/coupon.dart';
import '../models/order.dart';

class OrderService {
  OrderService(this._client);
  final ApiClient _client;

  Future<List<Order>> fetchOrders() async {
    final data = await _client.get('/orders');
    return (data as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> fetchOrder(String id) async {
    final data = await _client.get('/orders/$id');
    return Order.fromJson(data);
  }

  Future<Map<String, dynamic>> fetchTracking(String orderId) async {
    final data = await _client.get('/orders/tracking', query: {'orderId': orderId});
    return Map<String, dynamic>.from(data);
  }

  Future<Order> placeOrder({
    required String recipientName,
    required String shippingAddress,
    required String phone,
    String? pincode,
    String? couponCode,
    String? prescriptionId,
    int pointsToRedeem = 0,
    String paymentMethod = 'COD',
    List<Map<String, dynamic>>? items,
  }) async {
    final data = await _client.post('/orders', data: {
      'recipientName': recipientName,
      'shippingAddress': shippingAddress,
      'phone': phone,
      'pincode': ?pincode,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
      'prescriptionId': ?prescriptionId,
      if (pointsToRedeem > 0) 'pointsToRedeem': pointsToRedeem,
      'paymentMethod': paymentMethod,
      if (items != null && items.isNotEmpty) 'items': items,
    });
    return Order.fromJson(data);
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal) async {
    final data = await _client.post('/coupons/validate', data: {'code': code, 'subtotal': subtotal});
    return Map<String, dynamic>.from(data);
  }

  /// Public coupon list for the cart offers sheet — mirrors
  /// `fetchPublicCoupons` (lib/coupons-client.ts): GET /api/coupons.
  Future<List<CouponOffer>> fetchPublicCoupons() async {
    final raw = await _client.get('/coupons');
    final list = raw is List
        ? raw
        : (raw is Map && raw['data'] is List
            ? raw['data'] as List
            : (raw is Map && raw['coupons'] is List
                ? raw['coupons'] as List
                : null));
    if (list != null) {
      return list
          .whereType<Map>()
          .map((e) => CouponOffer.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> cashfreeAvailability() async {
    final data = await _client.get('/payments/cashfree/availability');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> createCashfreeOrder(String orderId) async {
    final data = await _client.post('/payments/cashfree/create', data: {'orderId': orderId});
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> verifyCashfreePayment(String orderIdOrNumber) async {
    final data = await _client.get('/payments/cashfree/verify', query: {'order_id': orderIdOrNumber});
    return Map<String, dynamic>.from(data);
  }
}
