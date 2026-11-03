import '../database/local_database.dart';

/// No wishlist endpoint exists on the backend, so favorites are kept
/// on-device (per install) rather than synced to the account.
class WishlistStorage {
  WishlistStorage._();
  static final WishlistStorage instance = WishlistStorage._();

  static const _key = 'wishlist_product_ids';

  Future<Set<String>> readAll() async {
    final list = await LocalDatabase.instance.get<List>(_key);
    return list?.map((e) => e.toString()).toSet() ?? const {};
  }

  Future<void> saveAll(Set<String> ids) async {
    await LocalDatabase.instance.put(_key, ids.toList());
  }
}
