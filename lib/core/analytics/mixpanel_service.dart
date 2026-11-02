import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../device/device_info_service.dart';

/// Mixpanel Analytics integration for the mobile app.
/// Matches the events and identity flow from `src/lib/mixpanel.ts` & `src/lib/mixpanel-flow.ts`.
class MixpanelService {
  MixpanelService._();
  static final MixpanelService instance = MixpanelService._();

  Dio? _httpClient;
  bool _initialized = false;
  String _distinctId = '';
  String? _identifiedUserId;
  final List<Map<String, dynamic>> _queue = [];
  bool _flushing = false;

  /// Visible for testing: inject custom Dio instance
  @visibleForTesting
  set testHttpClient(Dio client) => _httpClient = client;

  String get distinctId => _identifiedUserId ?? _distinctId;
  bool get isIdentified => _identifiedUserId != null;

  /// Initialize Mixpanel with persistent anonymous distinct ID and device super-properties.
  Future<void> init({String? token}) async {
    if (_initialized) return;

    _httpClient ??= Dio(
      BaseOptions(
        baseUrl: 'https://api.mixpanel.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      var stored = prefs.getString('mixpanel_distinct_id');
      if (stored == null || stored.isEmpty) {
        stored = 'mp_${DateTime.now().millisecondsSinceEpoch}_${DeviceInfoService.instance.deviceId}';
        await prefs.setString('mixpanel_distinct_id', stored);
      }
      _distinctId = stored;
      _identifiedUserId = prefs.getString('mixpanel_identified_user_id');
    } catch (_) {
      _distinctId = 'mp_${DateTime.now().millisecondsSinceEpoch}';
    }

    _initialized = true;
    _flushQueue();
  }

  /// Identify user on sign-in / app restore. Uses stable internal user ID.
  Future<void> identify(String userId) async {
    if (userId.trim().isEmpty) return;
    _identifiedUserId = userId.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mixpanel_identified_user_id', _identifiedUserId!);
    } catch (_) {}

    // Link original anonymous ID to user ID in Mixpanel
    await _sendTrackEvent('\$create_alias', {
      'alias': _identifiedUserId,
      'distinct_id': _distinctId,
    });
  }

  /// Reset identity on logout. Generates a fresh anonymous distinct ID.
  Future<void> reset() async {
    _identifiedUserId = null;
    _distinctId = 'mp_${DateTime.now().millisecondsSinceEpoch}_${DeviceInfoService.instance.deviceId}';

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mixpanel_identified_user_id');
      await prefs.setString('mixpanel_distinct_id', _distinctId);
    } catch (_) {}
  }

  /// Update user profile properties ($name, $email, platform, etc.)
  Future<void> setUserProfile({
    String? name,
    String? email,
    Map<String, dynamic>? properties,
  }) async {
    if (!_initialized) await init();

    final setProps = <String, dynamic>{
      'platform': 'app',
      'app_version': DeviceInfoService.instance.appVersion,
      'device_model': DeviceInfoService.instance.model,
      'os': DeviceInfoService.instance.platform,
      'os_version': DeviceInfoService.instance.osVersion,
      if (name != null && name.trim().isNotEmpty) '\$name': name.trim(),
      if (email != null && email.trim().isNotEmpty) '\$email': email.trim(),
      ...?properties,
    };

    final payload = [
      {
        '\$token': AppConfig.mixpanelToken,
        '\$distinct_id': distinctId,
        '\$set': setProps,
      }
    ];

    try {
      await _httpClient?.post(
        '/engage#profile-set',
        data: payload,
      );
    } catch (e) {
      debugPrint('[Mixpanel] Profile set error: $e');
    }
  }

  /// Track a curated event with super-properties.
  Future<void> track(String eventName, [Map<String, dynamic>? properties]) async {
    final sanitizedProps = <String, dynamic>{
      'platform': 'app',
      'app_version': DeviceInfoService.instance.appVersion,
      'app_build': DeviceInfoService.instance.buildNumber,
      'device_platform': DeviceInfoService.instance.platform,
      'device_model': DeviceInfoService.instance.model,
      'device_brand': DeviceInfoService.instance.brand,
      'device_os': DeviceInfoService.instance.osVersion,
      '\$os': DeviceInfoService.instance.platform == 'android'
          ? 'Android'
          : (DeviceInfoService.instance.platform == 'ios' ? 'iOS' : DeviceInfoService.instance.platform),
      '\$os_version': DeviceInfoService.instance.osVersion,
      '\$model': DeviceInfoService.instance.model,
      '\$manufacturer': DeviceInfoService.instance.brand,
      '\$app_version_string': DeviceInfoService.instance.appVersion,
      '\$app_build_number': DeviceInfoService.instance.buildNumber,
      ...?properties,
    };

    await _sendTrackEvent(eventName, sanitizedProps);
  }

  /// Helper to track sanitized page views matching web's `page_viewed` event.
  Future<void> trackPageView({required String pageName, String? path}) async {
    await track('page_viewed', {
      'page_name': pageName,
      if (path != null) 'page_path': sanitizePagePath(path),
    });
  }

  /// Sanitized page path hiding dynamic tokens and UUIDs (matches web's `sanitizedPagePath`).
  static String sanitizePagePath(String rawPath) {
    final clean = rawPath.split(RegExp(r'[?#]')).first;
    if (clean.isEmpty || clean == '/') return '/';

    final segments = clean.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/';

    const catalogRoutes = {'products', 'combos', 'blog', 'diseases', 'vet-insights'};
    const structuralSegments = {
      's', 'new', 'edit', 'history', 'my', 'chat', 'room', 'pay', 'confirmation',
      'login', 'register', 'dashboard', 'cart', 'checkout'
    };

    final first = segments.first;
    final rest = segments.skip(1).map((seg) {
      if (catalogRoutes.contains(first)) {
        // Keep friendly catalog slugs, mask UUIDs/hex tokens
        final isHexOrUuid = RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(seg);
        return isHexOrUuid ? '{id}' : seg;
      }
      return structuralSegments.contains(seg) ? seg : '{id}';
    }).toList();

    return '/${[first, ...rest].join('/')}';
  }

  /// Map route path to friendly human-readable Page Name.
  static String pageNameForRoute(String rawPath) {
    final clean = rawPath.split(RegExp(r'[?#]')).first;
    final segments = clean.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return 'Home';

    final first = segments.first;
    final second = segments.length > 1 ? segments[1] : null;

    switch (first) {
      case 'home':
        return 'Home';
      case 'products':
        return second != null ? 'Product Details' : 'Products';
      case 'product':
        return 'Product Details';
      case 'combos':
        return second != null ? 'Combo Details' : 'Care Combos';
      case 'combo':
        return 'Combo Details';
      case 'cart':
        return 'Cart';
      case 'checkout':
        return 'Checkout';
      case 'orders':
        if (second == null) return 'Orders';
        if (segments.contains('confirmation')) return 'Order Confirmation';
        return 'Order Details';
      case 'order':
        return 'Order Details';
      case 'login':
        return 'Login';
      case 'profile':
        return 'Profile';
      case 'addresses':
        return second == 'new' ? 'Add Address' : 'Addresses';
      case 'pets':
        return second == 'new' ? 'Add Pet' : 'My Pets';
      case 'consultations':
        if (segments.contains('chat')) return 'Consultation Chat';
        if (segments.contains('video')) return 'Video Room';
        return second != null ? 'Consultation Details' : 'Consultations';
      case 'care-chat':
        return 'Care Chat';
      case 'prescriptions':
        return 'Prescriptions';
      case 'search':
        return 'Search';
      case 'wishlist':
        return 'Wishlist';
      case 'vet':
        return 'Ask Dr. Paw';
      case 'blog':
        return second != null ? 'Blog Article' : 'Blog';
      case 'diseases':
        return second != null ? 'Disease Details' : 'Health Concerns';
      case 'pet-care':
        return 'Pet Care';
      case 'calculator':
        return 'Nutrition Calculator';
      case 'scan':
        return 'Prescription Scanner';
      default:
        return first.replaceAll('-', ' ').split(' ').map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1);
        }).join(' ');
    }
  }

  Future<void> _sendTrackEvent(String eventName, Map<String, dynamic> properties) async {
    final eventPayload = {
      'event': eventName,
      'properties': {
        'token': AppConfig.mixpanelToken,
        'distinct_id': distinctId,
        'time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ...properties,
      },
    };

    if (!_initialized) {
      _queue.add(eventPayload);
      return;
    }

    try {
      await _httpClient?.post(
        '/track',
        data: [eventPayload],
      );
      debugPrint('[Mixpanel] Event tracked: $eventName');
    } catch (e) {
      debugPrint('[Mixpanel] Track failed: $e');
      _queue.add(eventPayload);
    }
  }

  Future<void> _flushQueue() async {
    if (_flushing || _queue.isEmpty || _httpClient == null) return;
    _flushing = true;
    try {
      final batch = List<Map<String, dynamic>>.from(_queue);
      _queue.clear();
      await _httpClient?.post(
        '/track',
        data: batch,
      );
    } catch (_) {
      // Re-queue on failure
    } finally {
      _flushing = false;
    }
  }
}
