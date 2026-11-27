import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/models/store_settings.dart';

void main() {
  test('StoreSettings reads DB codMaxOrderAmount directly and evaluates cap accurately', () {
    final fromDb = StoreSettings.fromJson({
      'freeDeliveryThreshold': 1499,
      'deliveryCharge': 49,
      'codMaxOrderAmount': 1500,
    });
    expect(fromDb.codMaxOrderAmount, 1500.0);
    expect(fromDb.exceedsCodMaxOrderAmount(1499.0), isFalse);
    expect(fromDb.exceedsCodMaxOrderAmount(1500.0), isFalse);
    expect(fromDb.exceedsCodMaxOrderAmount(1500.01), isTrue);

    final updatedDb = StoreSettings.fromJson({
      'freeDeliveryThreshold': 1499,
      'deliveryCharge': 49,
      'codMaxOrderAmount': 2000,
    });
    expect(updatedDb.codMaxOrderAmount, 2000.0);
    expect(updatedDb.exceedsCodMaxOrderAmount(1800.0), isFalse);
    expect(updatedDb.exceedsCodMaxOrderAmount(2001.0), isTrue);

    final unlimited = StoreSettings.fromJson({
      'freeDeliveryThreshold': 1499,
      'deliveryCharge': 49,
      'codMaxOrderAmount': 0,
    });
    expect(unlimited.codMaxOrderAmount, 0.0);
    expect(unlimited.exceedsCodMaxOrderAmount(9999.0), isFalse);
  });
}
