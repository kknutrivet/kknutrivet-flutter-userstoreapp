import '../core/network/api_client.dart';
import '../models/referral.dart';

class ReferralService {
  ReferralService(this._client);
  final ApiClient _client;

  Future<ReferralSummary> fetchSummary() async {
    final data = await _client.get('/referral');
    return ReferralSummary.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Mirrors `redeemPoints` (lib/referral-client.ts): POST /api/referral
  /// {action: "redeem_points", pointsToRedeem} → {discountAmount,
  /// remainingPoints}. 1 point = ₹1, capped per order by
  /// `getMaxRedeemablePoints` (30% of subtotal) on the caller side.
  Future<Map<String, dynamic>> redeemPoints(int pointsToRedeem) async {
    final data = await _client.post('/referral', data: {
      'action': 'redeem_points',
      'pointsToRedeem': pointsToRedeem,
    });
    return Map<String, dynamic>.from(data as Map);
  }
}
