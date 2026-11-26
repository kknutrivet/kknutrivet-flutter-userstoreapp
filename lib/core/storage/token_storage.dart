import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user.dart';
import '../database/local_database.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'auth_token';
  static const _fallbackTokenKey = 'kk_auth_token_persist';
  static const _cachedUserKey = 'kk_auth_user_cache';

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Some Android emulators / Keystore states throw on write; backup below ensures persistence.
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fallbackTokenKey, token);
    } catch (_) {}
  }

  Future<String?> readToken() async {
    String? token;
    try {
      token = await _storage.read(key: _tokenKey);
    } catch (_) {
      token = null;
    }
    if (token != null && token.trim().isNotEmpty) return token;
    try {
      final prefs = await SharedPreferences.getInstance();
      final backup = prefs.getString(_fallbackTokenKey);
      if (backup != null && backup.trim().isNotEmpty) {
        // Re-hydrate secure storage best-effort
        try {
          await _storage.write(key: _tokenKey, value: backup);
        } catch (_) {}
        return backup;
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<AppUser?> readUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedUserKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fallbackTokenKey);
      await prefs.remove(_cachedUserKey);
    } catch (_) {}
    await LocalDatabase.instance.clearUserScoped();
  }
}
