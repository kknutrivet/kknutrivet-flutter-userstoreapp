import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Push notifications on the same Firebase project as the website
/// (`kk-nutrivet-web`, which already sends order/consultation pushes).
///
/// Website contract mirrored here:
/// - Token register: POST /api/user/push-subscriptions
///   {token, previousToken?, timezone?, userAgent?} (Bearer when signed in;
///   the backend accepts guest upserts with `userId: null`).
/// - Tap target: `data.notificationUrl` (e.g.
///   `https://www.kknutrivet.in/orders/<id>`), mapped to app routes below.
/// - Foreground: the OS does not show a banner, so we surface a SnackBar
///   with the same tap behavior.
///
/// Firebase-console setup (same project as the website):
/// 1. `google-services.json` → `android/app/`,
///    `GoogleService-Info.plist` → `ios/Runner/`
///    (register `com.nvit.nvit_app` / `com.nvit.nvitApp` + SHA fingerprints).
/// 2. iOS: Push Notifications capability + APNs Auth Key uploaded to the
///    Firebase project. Android needs nothing extra.
/// Until then every method here no-ops safely (same pattern as auth).
typedef PushTokenRegistrar = Future<void> Function({
  required String token,
  String? previousToken,
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const _previousTokenKey = 'fcm_previous_token';

  bool _listenersAttached = false;

  bool get _ready => Firebase.apps.isNotEmpty && _listenersAttached;

  /// Requests permission, registers the FCM token, and attaches
  /// foreground/tap handlers. Safe to call on every app start.
  Future<void> init({
    required PushTokenRegistrar register,
    required void Function(String appRoute) onTapRoute,
    required void Function(String title, String body, String appRoute)
        onForeground,
  }) async {
    if (_ready) return;
    if (Firebase.apps.isEmpty) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
      await _registerCurrentToken(register);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _registerToken(token, register);
      });
      FirebaseMessaging.onMessage.listen((message) {
        final route = mapUrlToAppRoute(
          message.data['notificationUrl'],
        );
        if (route == null) return;
        onForeground(
          message.notification?.title ?? 'KK Nutrivet',
          message.notification?.body ?? '',
          route,
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final route = mapUrlToAppRoute(
          message.data['notificationUrl'],
        );
        if (route != null) onTapRoute(route);
      });
      // Cold start from a terminated-state notification tap.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      final initialRoute = mapUrlToAppRoute(
        initial?.data['notificationUrl'],
      );
      if (initialRoute != null) onTapRoute(initialRoute);
      _listenersAttached = true;
    } catch (_) {
      // Push is best-effort; auth/browse must never break because of it.
    }
  }

  /// Re-registers the current FCM token (e.g. after sign-in, so the
  /// backend links the token to the account instead of the guest row).
  Future<void> resyncToken(PushTokenRegistrar register) async {
    if (Firebase.apps.isEmpty) return;
    await _registerCurrentToken(register);
  }

  Future<void> _registerCurrentToken(PushTokenRegistrar register) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token, register);
      }
    } catch (_) {}
  }

  Future<void> _registerToken(
    String token,
    PushTokenRegistrar register,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getString(_previousTokenKey);
      await register(token: token, previousToken: previous);
      await prefs.setString(_previousTokenKey, token);
    } catch (_) {}
  }

  /// Maps a website `notificationUrl` to an in-app go_router location.
  /// Returns null when the URL has no app equivalent (caller ignores it).
  static String? mapUrlToAppRoute(Object? url) {
    if (url is! String || url.isEmpty) return null;
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return null;
    }
    final path = uri.path;
    if (path.isEmpty || path == '/') return '/home';

    var m = RegExp(r'^/orders/([^/]+)/confirmation$').firstMatch(path);
    if (m != null) return '/order/${m.group(1)}';
    m = RegExp(r'^/orders/([^/]+)(?:/(?:pay|payment-return))?$')
        .firstMatch(path);
    if (m != null) return '/order/${m.group(1)}';
    if (path == '/orders') return '/orders';

    m = RegExp(r'^/products/([^/]+)$').firstMatch(path);
    if (m != null) return '/product/${m.group(1)}';
    if (path == '/products' || path.startsWith('/products?')) {
      return uri.query.isEmpty ? '/products' : '/products?${uri.query}';
    }
    if (path.startsWith('/combos')) return '/products?category=Combos';

    m = RegExp(r'^/consultations/([^/]+)$').firstMatch(path);
    if (m != null) return '/consultations/${m.group(1)}';
    if (path == '/consultations' ||
        path == '/consultations/my' ||
        path == '/care-chat' ||
        path.startsWith('/care-chat/')) {
      return '/consultations';
    }

    if (path == '/prescriptions' || path.startsWith('/rx/')) {
      return '/prescriptions';
    }
    if (path == '/pets' || path.startsWith('/pets')) return '/pets';
    if (path == '/referral') return '/referral';
    if (path.startsWith('/blog/')) return path;
    if (path == '/blog') return '/blog';
    if (path.startsWith('/diseases')) return path;
    if (path == '/cart') return '/cart';
    if (path == '/checkout') return '/checkout';
    if (path == '/profile' || path.startsWith('/profile')) {
      return '/profile';
    }
    if (path == '/vet') return '/vet';
    return '/home';
  }

  /// Platform UA string the backend stores beside the token.
  static String get userAgent =>
      Platform.isIOS ? 'kknutrivet-app-ios' : 'kknutrivet-app-android';
}
