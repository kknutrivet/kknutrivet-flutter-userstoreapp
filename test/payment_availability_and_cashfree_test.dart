import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/checkout/widgets/checkout_payment_and_review.dart';
import 'package:nvit_app/models/store_settings.dart';

void main() {
  group('Payment Availability & Partial COD Tests', () {
    test('StoreSettings defaults include partial COD configuration', () {
      final defaults = StoreSettings.defaults();
      expect(defaults.partialCodEnabled, true);
      expect(defaults.partialCodPercent, 15.0);
      expect(defaults.partialCodMinimum, 50.0);
    });

    test('StoreSettings quote computes partial COD advance and balance', () {
      final settings = StoreSettings.defaults();
      final quote = settings.partialCodQuote(387.0);
      // 15% of 387 is 58.05 -> rounded to 58
      expect(quote.advance, 58.0);
      expect(quote.balance, 329.0);
    });

    test('PaymentAvailabilityStatus parses direct and nested data correctly', () {
      final responseMap = {
        'codEnabled': false,
        'userCodAllowed': true,
        'partialCodEnabled': true,
        'codDisabledReason': 'Cash on Delivery is currently unavailable. Please pay online or choose Partial COD.',
        'userCodDisabledReason': null,
        'isTrustedCustomer': false,
        'deliveredOrdersCount': 0,
        'enabled': true,
        'access': 'standard',
      };

      // Direct map
      final Map<String, dynamic> data1 = (responseMap['data'] is Map)
          ? Map<String, dynamic>.from(responseMap['data'] as Map)
          : responseMap;
      final status1 = PaymentAvailabilityStatus(
        onlineEnabled: (data1['enabled'] as bool?) ?? true,
        codEnabled: (data1['codEnabled'] as bool?) ?? false,
        userCodAllowed: (data1['userCodAllowed'] as bool?) ?? true,
        partialCodEnabled: (data1['partialCodEnabled'] as bool?) ?? false,
        codDisabledReason: data1['codDisabledReason'] as String?,
      );

      expect(status1.onlineEnabled, true);
      expect(status1.partialCodEnabled, true);
      expect(status1.codEnabled, false);
      expect(status1.codDisabledReason, contains('Partial COD'));

      // Wrapped map: { code: 'OK', data: { ... } }
      final wrapped = {
        'code': 'OK',
        'data': responseMap,
      };
      final Map<String, dynamic> data2 = (wrapped['data'] is Map)
          ? Map<String, dynamic>.from(wrapped['data'] as Map)
          : wrapped;
      final status2 = PaymentAvailabilityStatus(
        onlineEnabled: (data2['enabled'] as bool?) ?? true,
        codEnabled: (data2['codEnabled'] as bool?) ?? false,
        userCodAllowed: (data2['userCodAllowed'] as bool?) ?? true,
        partialCodEnabled: (data2['partialCodEnabled'] as bool?) ?? false,
        codDisabledReason: data2['codDisabledReason'] as String?,
      );

      expect(status2.onlineEnabled, true);
      expect(status2.partialCodEnabled, true);
      expect(status2.codEnabled, false);
      expect(status2.codDisabledReason, contains('Partial COD'));
    });
  });
}
