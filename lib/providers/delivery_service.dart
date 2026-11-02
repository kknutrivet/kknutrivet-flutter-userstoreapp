import '../core/network/api_client.dart';
import '../models/delivery.dart';

class DeliveryService {
  DeliveryService(this._client);
  final ApiClient _client;

  Future<DeliveryInfo> checkPincode(String pincode) async {
    final data = await _client.get('/delivery', query: {'pincode': pincode});
    return DeliveryInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Mirrors `registerDeliveryInterest` (lib/delivery-client.ts):
  /// POST /api/delivery-interest {pincode, phone, name?} for the
  /// not-deliverable waitlist.
  Future<void> registerInterest({
    required String pincode,
    required String phone,
    String? name,
  }) =>
      _client.post('/delivery-interest', data: {
        'pincode': pincode,
        'phone': phone,
        if (name != null && name.isNotEmpty) 'name': name,
      });
}
