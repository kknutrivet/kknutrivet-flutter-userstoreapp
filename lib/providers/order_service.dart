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

  Future<Map<String, dynamic>> fetchTracking(
    String orderId, {
    String? parcelId,
  }) async {
    final data = await _client.get(
      '/orders/tracking',
      query: {
        'orderId': orderId,
        if (parcelId != null && parcelId.isNotEmpty) 'parcelId': parcelId,
      },
    );
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

  Future<Map<String, dynamic>> createCashfreeOrder(
    String orderId, {
    String? paymentPreference,
  }) async {
    final data = await _client.post('/payments/cashfree/create', data: {
      'orderId': orderId,
      if (paymentPreference != null && paymentPreference.isNotEmpty)
        'paymentPreference': paymentPreference,
    });
    return Map<String, dynamic>.from(data);
  }

  /// Silently releases an unpaid PENDING online order when the customer exits
  /// Cashfree without paying, restoring stock and any redeemed KK Coins.
  Future<Map<String, dynamic>> abandonPendingOrder(String orderId) async {
    final data = await _client.post('/orders/$orderId/abandon-pending');
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  Future<Map<String, dynamic>> verifyCashfreePayment(String orderIdOrNumber) async {
    final data = await _client.get('/payments/cashfree/verify', query: {'order_id': orderIdOrNumber});
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> fetchScratchReward(String orderId) async {
    final data = await _client.get('/orders/$orderId/scratch-reward');
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  Future<Map<String, dynamic>> claimScratchReward(String orderId) async {
    final data = await _client.post('/orders/$orderId/scratch-reward');
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  /// Fetches the user's scratch cards and coupons (`GET /api/profile/coupons`).
  Future<Map<String, dynamic>> fetchProfileCoupons() async {
    final data = await _client.get('/profile/coupons');
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  /// Fetches 30-day reorder reminder opt-in status (`GET /api/orders/:id/reorder-reminder`).
  Future<Map<String, dynamic>> fetchReorderReminder(String orderId) async {
    final data = await _client.get('/orders/$orderId/reorder-reminder');
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  /// Toggles 30-day reorder reminder (`POST /api/orders/:id/reorder-reminder`).
  Future<Map<String, dynamic>> setReorderReminder(
    String orderId, {
    required bool enabled,
    int intervalDays = 30,
  }) async {
    final data = await _client.post(
      '/orders/$orderId/reorder-reminder',
      data: {'enabled': enabled, 'intervalDays': intervalDays},
    );
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }
}
