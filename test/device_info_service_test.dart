import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/device/device_info_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceInfoService Tests', () {
    setUp(() async {
      await DeviceInfoService.instance.init();
    });

    test('initializes metadata and provides valid device headers', () {
      final info = DeviceInfoService.instance;
      expect(info.platform, isNotEmpty);
      expect(info.osVersion, isNotEmpty);
      expect(info.model, isNotEmpty);
      expect(info.brand, isNotEmpty);
      expect(info.appVersion, isNotEmpty);
      expect(info.buildNumber, isNotEmpty);
      expect(info.deviceId, startsWith('dev_'));
      expect(info.userAgent, contains('KKNutrivet-App/'));
    });

    test('getApiHeaders contains all required device and OS headers', () {
      final headers = DeviceInfoService.instance.getApiHeaders();

      expect(headers['User-Agent'], contains('KKNutrivet-App/'));
      expect(headers['X-Device-Platform'], isNotNull);
      expect(headers['X-Device-OS'], isNotNull);
      expect(headers['X-Device-Model'], isNotNull);
      expect(headers['X-Device-Brand'], isNotNull);
      expect(headers['X-Device-Id'], startsWith('dev_'));
      expect(headers['X-App-Version'], contains('+'));
    });

    test('ApiClient interceptor attaches device headers to requests', () async {
      final dio = Dio();
      final headersMap = <String, dynamic>{};

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final deviceHeaders = DeviceInfoService.instance.getApiHeaders();
            options.headers.addAll(deviceHeaders);
            headersMap.addAll(options.headers);
            // Complete without sending over real network in test
            handler.resolve(Response(
              requestOptions: options,
              data: {'ok': true},
              statusCode: 200,
            ));
          },
        ),
      );

      final response = await dio.get('https://example.com/test');
      expect(response.statusCode, 200);
      expect(headersMap['User-Agent'], contains('KKNutrivet-App/'));
      expect(headersMap['X-Device-Platform'], isNotNull);
      expect(headersMap['X-Device-OS'], isNotNull);
      expect(headersMap['X-Device-Model'], isNotNull);
      expect(headersMap['X-Device-Id'], startsWith('dev_'));
    });
  });
}
