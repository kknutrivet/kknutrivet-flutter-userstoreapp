import 'dart:io';

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
    final platform = Platform.isIOS ? 'ios' : 'android';
    return _client.post('/user/push-subscriptions', data: {
      'token': token,
      'platform': platform,
      ?(previousToken?.isNotEmpty == true ? 'previousToken' : null):
          previousToken,
      'timezone': 'Asia/Kolkata',
      ?(userAgent != null ? 'userAgent' : null): userAgent,
    });
  }

  /// Unlinks `userId` from this device's push token on logout while keeping the
  /// guest subscription row alive for anonymous alerts.
  Future<void> detachPushToken(String token) {
    return _client.post('/user/push-subscriptions', data: {
      'token': token,
      'detach': true,
    });
  }
}
