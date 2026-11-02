import '../core/network/api_client.dart';
import '../models/store_settings.dart';

class SettingsService {
  SettingsService(this._client);
  final ApiClient _client;

  Future<StoreSettings> fetchSettings() async {
    final data = await _client.get('/settings');
    if (data is Map) {
      final map = data.containsKey('data') && data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : Map<String, dynamic>.from(data);
      return StoreSettings.fromJson(map);
    }
    return StoreSettings.defaults();
  }
}
