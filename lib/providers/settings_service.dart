import '../core/network/api_client.dart';
import '../models/store_settings.dart';

class SettingsService {
  SettingsService(this._client);
  final ApiClient _client;

  Future<StoreSettings> fetchSettings() async {
    final data = await _client.get('/settings');
    return StoreSettings.fromJson(data);
  }
}
