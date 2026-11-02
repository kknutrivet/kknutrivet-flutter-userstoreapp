import '../core/network/api_client.dart';

/// Mirrors the website's push-subscription client
/// (`FirebaseNotificationButton.tsx` → POST /api/user/push-subscriptions).
class NotificationService {
  NotificationService(this._client);
  final ApiClient _client;

  Future<void> registerPushToken({
    required String token,
    String? previousToken,
    String? userAgent,
  }) {
    return _client.post('/user/push-subscriptions', data: {
      'token': token,
      ?(previousToken?.isNotEmpty == true ? 'previousToken' : null):
          previousToken,
      'timezone': 'Asia/Kolkata',
      ?(userAgent != null ? 'userAgent' : null): userAgent,
    });
  }
}
