import 'package:shared_preferences/shared_preferences.dart';

/// No wishlist endpoint exists on the backend, so favorites are kept
/// on-device (per install) rather than synced to the account.
class WishlistStorage {
  WishlistStorage._();
  static final WishlistStorage instance = WishlistStorage._();

  static const _key = 'wishlist_product_ids';

  Future<Set<String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<void> saveAll(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList());
  }
}
