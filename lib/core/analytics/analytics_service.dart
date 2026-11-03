import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../crashlytics/crashlytics_service.dart';
import 'mixpanel_service.dart';

/// Centralized analytics service mirroring the website tracking system.
/// Keeps Firebase Analytics and Mixpanel Analytics synchronized across all user flows:
/// 1. Screen & Navigation (page_viewed with sanitized path and page name)
/// 2. E-commerce Orders (browse → cart → checkout → purchase_completed / cod_order_placed)
/// 3. Auth & Identity (login_completed, sign_up_completed, logout_completed, identify)
/// 4. Pet Section (pet_profile_created, pet_profile_updated)
/// 5. Dr. Paw AI Chat & Consultations (vet_coach_started, care_chat_message_sent, consultation_booked)
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  String? _lastScreenName;
  String? _lastScreenPath;

  FirebaseAnalytics? get _analytics {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Firebase Analytics collection and log initial app open.
  Future<void> init({required bool firebaseAvailable}) async {
    if (!firebaseAvailable || Firebase.apps.isEmpty) {
      debugPrint('[Analytics] Firebase not available, skipping Firebase Analytics setup.');
      return;
    }
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      await analytics.logAppOpen();
      _initialized = true;
      debugPrint('[Analytics] Firebase Analytics initialized successfully');
    } catch (e, st) {
      debugPrint('[Analytics] Failed to initialize Firebase Analytics: $e\n$st');
    }
  }

  /// Firebase GoRouter navigation observer
  FirebaseAnalyticsObserver? get observer {
    final a = _analytics;
    return a != null ? FirebaseAnalyticsObserver(analytics: a) : null;
  }

  /// App-wide navigator observer for unified Mixpanel & Firebase screen tracking
  NavigatorObserver get navigatorObserver => _AppAnalyticsNavigatorObserver();

  // ===========================================================================
  // 1. General & Screen Events
  // ===========================================================================

  Future<void> logScreenView({required String screenName, String? path}) async {
    if (_lastScreenName == screenName && _lastScreenPath == path) return;
    _lastScreenName = screenName;
    _lastScreenPath = path;

    try {
      await _analytics?.logScreenView(screenName: screenName);
      debugPrint('[Analytics] Screen: $screenName (${path ?? ''})');
    } catch (_) {}

    try {
      await MixpanelService.instance.trackPageView(
        pageName: screenName,
        path: path,
      );
    } catch (_) {}
  }

  Future<void> logSearch({required String searchTerm}) async {
    final term = searchTerm.trim();
    try {
      await _analytics?.logSearch(searchTerm: term);
    } catch (_) {}

    try {
      // Query length only sent to Mixpanel for privacy
      await MixpanelService.instance.track('search_performed', {
        'query_length': term.length,
      });
    } catch (_) {}
  }

  // ===========================================================================
  // 2. E-commerce & Orders Flow
  // ===========================================================================

  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    String? itemCategory,
    required double price,
  }) async {
    try {
      await _analytics?.logViewItem(
        currency: 'INR',
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            itemCategory: itemCategory,
            price: price,
          ),
        ],
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('product_viewed', {
        'product_id': itemId,
        'product_name': itemName,
        'price': price,
        'category': ?itemCategory,
      });
    } catch (_) {}
  }

  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    String? itemCategory,
    required double price,
    int quantity = 1,
    String? animalType,
  }) async {
    try {
      await _analytics?.logAddToCart(
        currency: 'INR',
        value: price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            itemCategory: itemCategory,
            price: price,
            quantity: quantity,
          ),
        ],
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('product_added_to_cart', {
        'product_id': itemId,
        'product_name': itemName,
        'price': price,
        'quantity': quantity,
        'category': ?itemCategory,
        'animal_type': ?animalType,
      });
    } catch (_) {}
  }

  Future<void> logRemoveFromCart({
    required String itemId,
    required String itemName,
    required double price,
    int quantity = 1,
  }) async {
    try {
      await _analytics?.logRemoveFromCart(
        currency: 'INR',
        value: price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            price: price,
            quantity: quantity,
          ),
        ],
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('product_removed_from_cart', {
        'product_id': itemId,
        'quantity': quantity,
      });
    } catch (_) {}
  }

  Future<void> logCartViewed({
    required int itemCount,
    required double totalValue,
    List<String>? productIds,
  }) async {
    try {
      await MixpanelService.instance.track('cart_viewed', {
        'item_count': itemCount,
        'value': totalValue,
        if (productIds != null && productIds.isNotEmpty)
          'product_ids': productIds.take(20).toList(),
      });
    } catch (_) {}
  }

  Future<void> logBeginCheckout({
    required double value,
    required int itemCount,
    String? coupon,
    List<String>? productIds,
  }) async {
    try {
      await _analytics?.logBeginCheckout(
        value: value,
        currency: 'INR',
        coupon: coupon,
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('checkout_started', {
        'value': value,
        'item_count': itemCount,
        if (coupon != null && coupon.isNotEmpty) 'coupon_applied': coupon,
        if (productIds != null && productIds.isNotEmpty)
          'product_ids': productIds.take(20).toList(),
      });
    } catch (_) {}
  }

  final Set<String> _reportedPayments = {};

  Future<void> logPurchase({
    required String orderId,
    required double value,
    double? shipping,
    double? tax,
    String? coupon,
    int itemCount = 1,
    List<String>? productIds,
    String paymentMethod = 'prepaid',
  }) async {
    final key = 'reported_payment_${orderId}_$paymentMethod';
    if (!_reportedPayments.add(key)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) == true) return;
      await prefs.setBool(key, true);
    } catch (_) {}
    try {
      if (paymentMethod == 'advance') {
        await _analytics?.logEvent(name: 'advance_paid', parameters: {'order_id': orderId, 'value': value, 'currency': 'INR'});
      } else {
      await _analytics?.logPurchase(
        transactionId: orderId,
        currency: 'INR',
        value: value,
        shipping: shipping,
        tax: tax,
        coupon: coupon,
      );
      }
    } catch (_) {}

    try {
      final isCod = paymentMethod.toLowerCase().contains('cod');
      final eventName = paymentMethod == 'advance' ? 'advance_paid' : isCod ? 'cod_order_placed' : 'purchase_completed';
      await MixpanelService.instance.track(eventName, {
        'order_id': orderId,
        'value': value,
        'currency': 'INR',
        'item_count': itemCount,
        'payment_method': paymentMethod,
        if (coupon != null && coupon.isNotEmpty) 'coupon': coupon,
        if (productIds != null && productIds.isNotEmpty)
          'product_ids': productIds.take(20).toList(),
      });
    } catch (_) {}
  }

  // ===========================================================================
  // 3. User & Auth Flow
  // ===========================================================================

  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
    } catch (_) {}

    try {
      await MixpanelService.instance.track('sign_up_completed', {
        'sign_up_method': method,
        'platform': 'app',
      });
    } catch (_) {}
  }

  Future<void> logLogin({required String method}) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
    } catch (_) {}

    try {
      await MixpanelService.instance.track('login_completed', {
        'login_method': method,
      });
    } catch (_) {}
  }

  Future<void> logLogout() async {
    try {
      await _analytics?.logEvent(name: 'logout_completed');
    } catch (_) {}

    try {
      await MixpanelService.instance.track('logout_completed');
      await MixpanelService.instance.reset();
    } catch (_) {}
  }

  // ===========================================================================
  // 4. Pet Section Flow
  // ===========================================================================

  Future<void> logPetCreated({
    required String animalType,
    String? breed,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'pet_profile_created',
        parameters: {
          'animal_type': animalType,
          if (breed != null && breed.isNotEmpty) 'breed': breed,
        },
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('pet_profile_created', {
        'animal_type': animalType,
        if (breed != null && breed.isNotEmpty) 'breed': breed,
      });
    } catch (_) {}
  }

  Future<void> logPetUpdated({
    required String animalType,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'pet_profile_updated',
        parameters: {
          'animal_type': animalType,
        },
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('pet_profile_updated', {
        'animal_type': animalType,
      });
    } catch (_) {}
  }

  // ===========================================================================
  // 5. Dr. Paw AI Chat Flow
  // ===========================================================================

  Future<void> logDrPawChatStarted() async {
    try {
      await _analytics?.logEvent(name: 'dr_paw_chat_started');
    } catch (_) {}

    try {
      await MixpanelService.instance.track('vet_coach_started', {
        'coach_type': 'dr_paw',
      });
    } catch (_) {}
  }

  Future<void> logDrPawMessageSent({required int messageCount}) async {
    try {
      await _analytics?.logEvent(
        name: 'dr_paw_message_sent',
        parameters: {'message_count': messageCount},
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('care_chat_message_sent', {
        'message_count': messageCount,
      });
    } catch (_) {}
  }

  // ===========================================================================
  // 6. Consultations Flow
  // ===========================================================================

  Future<void> logConsultationBookingStarted({
    String? animalType,
  }) async {
    try {
      final params = <String, Object>{};
      if (animalType != null) params['animal_type'] = animalType;
      await _analytics?.logEvent(
        name: 'consultation_booking_started',
        parameters: params.isNotEmpty ? params : null,
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('consultation_booking_started', {
        'animal_type': ?animalType,
      });
    } catch (_) {}
  }

  Future<void> logConsultationBooked({
    required String consultationId,
    double? amount,
  }) async {
    try {
      final params = <String, Object>{
        'consultation_id': consultationId,
        'currency': 'INR',
      };
      if (amount != null) params['value'] = amount;
      await _analytics?.logEvent(
        name: 'consultation_booked',
        parameters: params,
      );
    } catch (_) {}

    try {
      await MixpanelService.instance.track('consultation_booked', {
        'consultation_id': consultationId,
        'value': ?amount,
      });
    } catch (_) {}
  }

  // ===========================================================================
  // 7. Discovery & Filters
  // ===========================================================================

  Future<void> logFilterApplied({
    required String filterType,
    required String filterValue,
  }) async {
    try {
      await MixpanelService.instance.track('filter_applied', {
        'filter_type': filterType,
        'filter_value': filterValue,
      });
    } catch (_) {}
  }

  Future<void> logSortApplied({required String sortBy}) async {
    try {
      await MixpanelService.instance.track('sort_applied', {
        'sort_by': sortBy,
      });
    } catch (_) {}
  }

  Future<void> logAnimalSelected({required String animalType}) async {
    try {
      await MixpanelService.instance.track('animal_selected', {
        'animal_type': animalType,
      });
    } catch (_) {}
  }

  // ===========================================================================
  // 8. User Identification & Profile
  // ===========================================================================

  Future<void> setUserId(String? userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (_) {}

    try {
      await CrashlyticsService.instance.setUserId(userId);
    } catch (_) {}

    try {
      if (userId != null && userId.isNotEmpty) {
        await MixpanelService.instance.identify(userId);
      } else {
        await MixpanelService.instance.reset();
      }
    } catch (_) {}
  }

  Future<void> setUserProfile({
    String? name,
    String? email,
    Map<String, dynamic>? properties,
  }) async {
    try {
      if (name != null && name.trim().isNotEmpty) {
        await _analytics?.setUserProperty(name: 'display_name', value: name.trim());
      }
      if (email != null && email.trim().isNotEmpty) {
        await _analytics?.setUserProperty(name: 'user_email', value: email.trim());
      }
    } catch (_) {}

    try {
      await MixpanelService.instance.setUserProfile(
        name: name,
        email: email,
        properties: properties,
      );
    } catch (_) {}
  }
}

class _AppAnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _recordRoute(newRoute);
  }

  void _recordRoute(Route<dynamic> route) {
    final rawName = route.settings.name;
    if (rawName == null || rawName.isEmpty) return;

    final pageName = MixpanelService.pageNameForRoute(rawName);
    AnalyticsService.instance.logScreenView(
      screenName: pageName,
      path: rawName,
    );
  }
}
