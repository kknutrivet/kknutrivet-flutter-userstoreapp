import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._client);
  final ApiClient _client;

  Future<AppUser> login(String email, String password) async {
    final data = await _client.post('/auth/login', data: {'email': email, 'password': password});
    await TokenStorage.instance.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? referralCode,
  }) async {
    final data = await _client.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    });
    await TokenStorage.instance.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<void> sendOtp(String phone, String name) =>
      _client.post('/auth/send-otp', data: {'phone': phone, 'name': name});

  Future<AppUser> verifyOtp(String phone, String code, {String? name, String? referralCode}) async {
    final data = await _client.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
      if (name != null && name.isNotEmpty) 'name': name,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    });
    await TokenStorage.instance.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<void> forgotPassword(String email) => _client.post('/auth/forgot-password', data: {'email': email});

  Future<void> resetPassword(String token, String password) =>
      _client.post('/auth/reset-password', data: {'token': token, 'password': password});

  Future<AppUser> continueAsGuest() async {
    final data = await _client.post('/auth/guest', data: {});
    await TokenStorage.instance.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  /// Same Firebase project as the website: POST /api/auth/firebase
  /// {idToken, referralCode?} → {token, user}.
  Future<AppUser> loginWithFirebaseGoogle(
    String idToken, {
    String? referralCode,
  }) async {
    final data = await _client.post('/auth/firebase', data: {
      'idToken': idToken,
      if (referralCode != null && referralCode.isNotEmpty)
        'referralCode': referralCode,
    });
    await TokenStorage.instance.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  /// POST /api/auth/firebase-phone {idToken, name?, referralCode?}.
  Future<AppUser> loginWithFirebasePhone(
    String idToken, {
    String? name,
    String? referralCode,
  }) async {
    final data = await _client.post('/auth/firebase-phone', data: {
      'idToken': idToken,
      if (name != null && name.isNotEmpty) 'name': name,
      if (referralCode != null && referralCode.isNotEmpty)
        'referralCode': referralCode,
    });
    await TokenStorage.instance.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  /// POST /api/auth/firebase-anonymous {idToken} — the website's
  /// "Continue as guest" path.
  Future<AppUser> continueAsFirebaseGuest(String idToken) async {
    final data = await _client.post('/auth/firebase-anonymous', data: {
      'idToken': idToken,
    });
    await TokenStorage.instance.saveToken(data['token']);
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> fetchProfile() async {
    final data = await _client.get('/auth/profile');
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateProfile({String? name, String? phone, String? email}) async {
    final data = await _client.put('/auth/profile', data: {
      'name': ?name,
      'phone': ?phone,
      'email': ?email,
    });
    return AppUser.fromJson(data);
  }

  Future<void> logout() => TokenStorage.instance.clearToken();
}
