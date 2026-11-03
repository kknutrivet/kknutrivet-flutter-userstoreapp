import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/local_database.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await LocalDatabase.instance.clearUserScoped();
  }
}
