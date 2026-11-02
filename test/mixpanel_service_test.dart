import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/analytics/analytics_service.dart';
import 'package:nvit_app/core/analytics/mixpanel_service.dart';
import 'package:nvit_app/core/device/device_info_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio mockDio;
  final capturedRequests = <RequestOptions>[];

  setUp(() async {
    capturedRequests.clear();
    mockDio = Dio(BaseOptions(baseUrl: 'https://api.mixpanel.com'));
    mockDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequests.add(options);
          handler.resolve(Response(
            requestOptions: options,
            data: {'status': 1},
            statusCode: 200,
          ));
        },
      ),
    );

    MixpanelService.instance.testHttpClient = mockDio;
    await DeviceInfoService.instance.init();
    await MixpanelService.instance.init();
  });

  group('MixpanelService Core Tests', () {
    test('track sends event with required super properties', () async {
      await MixpanelService.instance.track('product_viewed', {
        'product_id': 'prod-123',
        'price': 450.0,
      });

      expect(capturedRequests, isNotEmpty);
      final req = capturedRequests.last;
      expect(req.path, '/track');

      final data = req.data as List;
      expect(data, isNotEmpty);
      final event = data.first as Map<String, dynamic>;

      expect(event['event'], 'product_viewed');
      final props = event['properties'] as Map<String, dynamic>;
      expect(props['product_id'], 'prod-123');
      expect(props['price'], 450.0);
      expect(props['platform'], 'app');
      expect(props['token'], isNotEmpty);
      expect(props['distinct_id'], isNotEmpty);
      expect(props['\$os'], isNotNull);
      expect(props['\$model'], isNotNull);
    });

    test('identify creates alias and updates distinctId', () async {
      final initialId = MixpanelService.instance.distinctId;
      await MixpanelService.instance.identify('user-999');

      expect(MixpanelService.instance.distinctId, 'user-999');
      expect(MixpanelService.instance.isIdentified, isTrue);

      expect(capturedRequests, isNotEmpty);
      final aliasReq = capturedRequests.last;
      final data = aliasReq.data as List;
      final event = data.first as Map<String, dynamic>;
      expect(event['event'], '\$create_alias');
      final props = event['properties'] as Map<String, dynamic>;
      expect(props['alias'], 'user-999');
      expect(props['distinct_id'], initialId);
    });

    test('reset clears identified user and sets new anonymous distinctId', () async {
      await MixpanelService.instance.identify('user-777');
      expect(MixpanelService.instance.distinctId, 'user-777');

      await MixpanelService.instance.reset();
      expect(MixpanelService.instance.distinctId, isNot('user-777'));
      expect(MixpanelService.instance.distinctId, startsWith('mp_'));
      expect(MixpanelService.instance.isIdentified, isFalse);
    });

    test('setUserProfile sends people engage payload', () async {
      await MixpanelService.instance.setUserProfile(
        name: 'Dr. Paw Test',
        email: 'test@example.com',
      );

      expect(capturedRequests, isNotEmpty);
      final req = capturedRequests.last;
      expect(req.path, '/engage#profile-set');

      final data = req.data as List;
      final payload = data.first as Map<String, dynamic>;
      final setProps = payload['\$set'] as Map<String, dynamic>;

      expect(setProps['\$name'], 'Dr. Paw Test');
      expect(setProps['\$email'], 'test@example.com');
      expect(setProps['platform'], 'app');
    });

    test('sanitizePagePath masks IDs and preserves public catalog slugs', () {
      expect(MixpanelService.sanitizePagePath('/products'), '/products');
      expect(MixpanelService.sanitizePagePath('/products/deworming-syrup'), '/products/deworming-syrup');
      expect(MixpanelService.sanitizePagePath('/combos/combo-123'), '/combos/combo-123');
      expect(MixpanelService.sanitizePagePath('/orders/0123456789abcdef0123'), '/orders/{id}');
      expect(MixpanelService.sanitizePagePath('/cart'), '/cart');
      expect(MixpanelService.sanitizePagePath('/checkout'), '/checkout');
    });

    test('pageNameForRoute maps path to friendly page name', () {
      expect(MixpanelService.pageNameForRoute('/home'), 'Home');
      expect(MixpanelService.pageNameForRoute('/products'), 'Products');
      expect(MixpanelService.pageNameForRoute('/product/granliv'), 'Product Details');
      expect(MixpanelService.pageNameForRoute('/combos/1'), 'Combo Details');
      expect(MixpanelService.pageNameForRoute('/cart'), 'Cart');
      expect(MixpanelService.pageNameForRoute('/checkout'), 'Checkout');
      expect(MixpanelService.pageNameForRoute('/orders'), 'Orders');
      expect(MixpanelService.pageNameForRoute('/orders/confirmation'), 'Order Confirmation');
      expect(MixpanelService.pageNameForRoute('/vet'), 'Ask Dr. Paw');
      expect(MixpanelService.pageNameForRoute('/consultations'), 'Consultations');
    });
  });

  group('AnalyticsService & Mixpanel Integration Tests', () {
    test('logAddToCart triggers Mixpanel product_added_to_cart', () async {
      capturedRequests.clear();
      await AnalyticsService.instance.logAddToCart(
        itemId: 'prod-10',
        itemName: 'Calcium Feed',
        price: 250.0,
        quantity: 2,
        itemCategory: 'Supplements',
        animalType: 'Cattle',
      );

      final trackReqs = capturedRequests.where((r) => r.path == '/track').toList();
      expect(trackReqs, isNotEmpty);
      final payload = (trackReqs.last.data as List).first as Map<String, dynamic>;
      expect(payload['event'], 'product_added_to_cart');
      final props = payload['properties'] as Map<String, dynamic>;
      expect(props['product_id'], 'prod-10');
      expect(props['price'], 250.0);
      expect(props['quantity'], 2);
      expect(props['animal_type'], 'Cattle');
    });

    test('logPurchase triggers purchase_completed or cod_order_placed', () async {
      capturedRequests.clear();
      await AnalyticsService.instance.logPurchase(
        orderId: 'ORD-9988',
        value: 1200.0,
        paymentMethod: 'COD',
        itemCount: 3,
        productIds: ['prod-1', 'prod-2'],
      );

      final trackReqs = capturedRequests.where((r) => r.path == '/track').toList();
      expect(trackReqs, isNotEmpty);
      final payload = (trackReqs.last.data as List).first as Map<String, dynamic>;
      expect(payload['event'], 'cod_order_placed');
      final props = payload['properties'] as Map<String, dynamic>;
      expect(props['order_id'], 'ORD-9988');
      expect(props['value'], 1200.0);
      expect(props['item_count'], 3);
      expect(props['product_ids'], ['prod-1', 'prod-2']);
    });

    test('logLogin and logLogout trigger auth events and manage identity', () async {
      capturedRequests.clear();
      await AnalyticsService.instance.logLogin(method: 'phone_otp');

      var trackReqs = capturedRequests.where((r) => r.path == '/track').toList();
      expect(trackReqs, isNotEmpty);
      var payload = (trackReqs.last.data as List).first as Map<String, dynamic>;
      expect(payload['event'], 'login_completed');
      expect(payload['properties']['login_method'], 'phone_otp');

      capturedRequests.clear();
      await AnalyticsService.instance.logLogout();
      trackReqs = capturedRequests.where((r) => r.path == '/track').toList();
      expect(trackReqs, isNotEmpty);
      payload = (trackReqs.last.data as List).first as Map<String, dynamic>;
      expect(payload['event'], 'logout_completed');
      expect(MixpanelService.instance.isIdentified, isFalse);
    });

    test('init handles firebaseAvailable: false safely without throwing', () async {
      expect(
        () async => await AnalyticsService.instance.init(firebaseAvailable: false),
        returnsNormally,
      );
      expect(AnalyticsService.instance.isInitialized, isFalse);
    });
  });
}
