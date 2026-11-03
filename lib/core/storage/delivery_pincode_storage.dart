import '../database/local_database.dart';

class DeliveryPincodeStorage {
  DeliveryPincodeStorage._();
  static final DeliveryPincodeStorage instance = DeliveryPincodeStorage._();

  static const _key = 'delivery_pincode';

  Future<String?> read() => LocalDatabase.instance.get<String>(_key);

  Future<void> save(String pincode) =>
      LocalDatabase.instance.put<String>(_key, pincode);
}
