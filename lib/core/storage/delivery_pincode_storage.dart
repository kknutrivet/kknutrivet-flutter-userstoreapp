import 'package:shared_preferences/shared_preferences.dart';

class DeliveryPincodeStorage {
  DeliveryPincodeStorage._();
  static final DeliveryPincodeStorage instance = DeliveryPincodeStorage._();

  static const _key = 'delivery_pincode';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> save(String pincode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, pincode);
  }
}
