import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/models/store_settings.dart';

void main() {
  test('StoreSettings defaults codMaxOrderAmount to 1500 and evaluates cap accurately', () {
    final defaults = StoreSettings.defaults();
    expect(defaults.codMaxOrderAmount, 1500.0);
    expect(defaults.exceedsCodMaxOrderAmount(1499.0), isFalse);
    expect(defaults.exceedsCodMaxOrderAmount(1500.0), isFalse);
    expect(defaults.exceedsCodMaxOrderAmount(1500.01), isTrue);

    final fromBusinessRules = StoreSettings.fromJson({
      'freeDeliveryThreshold': 1499,
      'deliveryCharge': 49,
      'businessRules': {
        'codPolicy': {'maxOrderAmount': 2000},
      },
    });
    expect(fromBusinessRules.codMaxOrderAmount, 2000.0);
    expect(fromBusinessRules.exceedsCodMaxOrderAmount(1800.0), isFalse);
    expect(fromBusinessRules.exceedsCodMaxOrderAmount(2001.0), isTrue);

    final unlimited = StoreSettings.fromJson({
      'freeDeliveryThreshold': 1499,
      'deliveryCharge': 49,
      'codMaxOrderAmount': 0,
    });
    expect(unlimited.codMaxOrderAmount, 0.0);
    expect(unlimited.exceedsCodMaxOrderAmount(9999.0), isFalse);
  });
}
