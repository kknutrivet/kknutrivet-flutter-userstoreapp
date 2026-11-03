import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Push notifications on the same Firebase project as the website
/// (`kk-nutrivet-web`, which already sends order/consultation pushes).
///
/// Website contract mirrored here:
/// - Token register: POST /api/user/push-subscriptions
///   {token, previousToken?, timezone?, userAgent?} (Bearer when signed in;
///   the backend accepts guest upserts with `userId: null`).
/// - Tap target: `data.notificationUrl` (e.g.
///   `https://www.kknutrivet.in/orders/<id>`), or direct data fields
///   `bookingId`, `orderId`, mapped to app routes below.
/// - Foreground: the OS does not show a banner, so we surface a SnackBar
///   with the same tap behavior.
///
/// Firebase-console setup (same project as the website):
/// 1. `google-services.json` → `android/app/`,
///    `GoogleService-Info.plist` → `ios/Runner/`
///    (register `com.nvit.nvit_app` / `com.nvit.nvitApp` + SHA fingerprints).
/// 2. iOS: Push Notifications capability + APNs Auth Key uploaded to the
///    Firebase project. Android uses channel `urgent_alerts_v3`.
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
  PushTokenRegistrar? _registeredRegistrar;

  bool get _ready => Firebase.apps.isNotEmpty && _listenersAttached;

  /// Requests permission, registers the FCM token, and attaches
  /// foreground/tap handlers. Safe to call on every app start.
  Future<void> init({
    required PushTokenRegistrar register,
    required void Function(String appRoute) onTapRoute,
    required void Function(String title, String body, String appRoute)
        onForeground,
  }) async {
    _registeredRegistrar = register;
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
        debugPrint('[PushService] Received foreground message: ${message.messageId}');
        final route = mapMessageToAppRoute(message) ?? '/home';
        final title = message.notification?.title ??
            message.data['title']?.toString() ??
            'KK Nutrivet';
        final body = message.notification?.body ??
            message.data['body']?.toString() ??
            '';
        onForeground(title, body, route);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[PushService] User tapped notification from background: ${message.messageId}');
        final route = mapMessageToAppRoute(message);
        if (route != null) onTapRoute(route);
      });

      // Cold start from a terminated-state notification tap.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        debugPrint('[PushService] Launched from terminated notification: ${initial.messageId}');
        final initialRoute = mapMessageToAppRoute(initial);
        if (initialRoute != null) onTapRoute(initialRoute);
      }

      _listenersAttached = true;
    } catch (e, stack) {
      debugPrint('[PushService] init error: $e\n$stack');
      // Push is best-effort; auth/browse must never break because of it.
    }
  }

  /// Re-registers the current FCM token (e.g. after sign-in, so the
  /// backend links the token to the account instead of the guest row).
  Future<void> resyncToken([PushTokenRegistrar? register]) async {
    if (Firebase.apps.isEmpty) return;
    final targetRegistrar = register ?? _registeredRegistrar;
    if (targetRegistrar == null) return;
    await _registerCurrentToken(targetRegistrar);
  }

  Future<void> _registerCurrentToken(PushTokenRegistrar register) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token, register);
      }
    } catch (e) {
      debugPrint('[PushService] _registerCurrentToken failed: $e');
    }
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
      debugPrint('[PushService] FCM token registered successfully');
    } catch (e) {
      debugPrint('[PushService] _registerToken failed: $e');
    }
  }

  /// Extracts app navigation route directly from a [RemoteMessage].
  /// Checks explicit data keys (bookingId, orderId, productId) and notificationUrl.
  static String? mapMessageToAppRoute(RemoteMessage message) {
    final data = message.data;

    // 1. Direct consultation / care chat ID
    final bookingId = data['bookingId']?.toString() ??
        data['booking_id']?.toString() ??
        data['chatId']?.toString();
    if (bookingId != null && bookingId.trim().isNotEmpty) {
      return '/consultations/${bookingId.trim()}';
    }

    // 2. Direct order ID
    final orderId = data['orderId']?.toString() ?? data['order_id']?.toString();
    if (orderId != null && orderId.trim().isNotEmpty) {
      return '/order/${orderId.trim()}';
    }

    // 3. Direct product ID or slug
    final productId = data['productId']?.toString() ??
        data['product_id']?.toString() ??
        data['slug']?.toString();
    if (productId != null && productId.trim().isNotEmpty) {
      return '/product/${productId.trim()}';
    }

    // 4. Fallback to notificationUrl / url / link
    final rawUrl = data['notificationUrl']?.toString() ??
        data['url']?.toString() ??
        data['link']?.toString();
    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      final mapped = mapUrlToAppRoute(rawUrl.trim());
      if (mapped != null) return mapped;
    }

    return null;
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
    final query = uri.queryParameters;

    if (path.isEmpty || path == '/') return '/home';

    // Orders: /orders/<id>, /orders/<id>/confirmation, /orders/<id>/pay, or /orders?order_id=<id>
    var m = RegExp(r'^/orders?/([^/]+)(?:/(?:confirmation|pay|payment-return))?$')
        .firstMatch(path);
    if (m != null) return '/order/${m.group(1)}';

    final orderParam = query['order_id'] ?? query['orderId'] ?? query['id'];
    if (path == '/orders') {
      if (orderParam != null && orderParam.isNotEmpty) {
        return '/order/$orderParam';
      }
      return '/orders';
    }

    // Products: /products/<slug> or /product/<slug>
    m = RegExp(r'^/products?/([^/]+)$').firstMatch(path);
    if (m != null) return '/product/${m.group(1)}';
    if (path == '/products' || path.startsWith('/products?')) {
      return uri.query.isEmpty ? '/products' : '/products?${uri.query}';
    }
    if (path.startsWith('/combos')) return '/products?category=Combos';

    // Consultations & Care Chat:
    // /care-chat?chat=<id>, /consultations/<id>, /care-chat/<id>, /video-room/<id>, /consultations/room/<id>
    final chatParam = query['chat'] ??
        query['booking_id'] ??
        query['bookingId'] ??
        query['id'];

    m = RegExp(r'^/(?:consultations|care-chat|video-room)/([^/]+)$')
        .firstMatch(path);
    if (m != null && m.group(1) != 'my' && m.group(1) != 'book') {
      return '/consultations/${m.group(1)}';
    }

    if (path == '/care-chat' ||
        path == '/consultations' ||
        path == '/consultations/my' ||
        path.startsWith('/care-chat/')) {
      if (chatParam != null && chatParam.isNotEmpty) {
        return '/consultations/$chatParam';
      }
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
