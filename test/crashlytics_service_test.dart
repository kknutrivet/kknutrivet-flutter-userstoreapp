import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/crashlytics/crashlytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashlyticsService Tests', () {
    test('init handles firebaseAvailable: false safely without throwing', () async {
      final service = CrashlyticsService.instance;
      expect(() async => await service.init(firebaseAvailable: false), returnsNormally);
      expect(service.isInitialized, isFalse);
    });

    test('init with enableInDebug defaults safely when uninitialized', () async {
      final service = CrashlyticsService.instance;
      expect(() async => await service.init(firebaseAvailable: false, enableInDebug: true), returnsNormally);
      expect(service.isInitialized, isFalse);
    });

    test('recordError is non-throwing when uninitialized', () async {
      final service = CrashlyticsService.instance;
      expect(
        () async => await service.recordError(
          Exception('Test error'),
          StackTrace.current,
          reason: 'Test non-fatal error',
        ),
        returnsNormally,
      );
    });

    test('log, setUserId, and setCustomKey are safe and non-throwing', () async {
      final service = CrashlyticsService.instance;
      expect(() async => await service.log('user navigated to test'), returnsNormally);
      expect(() async => await service.setUserId('user-12345'), returnsNormally);
      expect(() async => await service.setUserId(null), returnsNormally);
      expect(() async => await service.setCustomKey('test_key', 'test_value'), returnsNormally);
      expect(() async => await service.setCustomKey('cart_count', 4), returnsNormally);
    });
  });
}
