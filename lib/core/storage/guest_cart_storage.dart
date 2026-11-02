import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cart_item.dart';

/// Persists guest (and offline fallback) cart items on-device across app restarts,
/// mirroring the website's `localStorage.getItem('kknutrivet_guest_cart')`.
class GuestCartStorage {
  GuestCartStorage._();
  static final GuestCartStorage instance = GuestCartStorage._();

  static const _key = 'guest_cart_items_v1';

  Future<List<CartItem>> readAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (items.isEmpty) {
        await prefs.remove(_key);
      } else {
        final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
        await prefs.setString(_key, encoded);
      }
    } catch (_) {
      // Best-effort persistence (e.g. unit tests without SharedPreferences mock).
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Best-effort clear.
    }
  }
}
