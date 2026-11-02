import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

enum AppEnvironment {
  prod(
    name: 'Production',
    baseUrl: 'https://kknutrivet.in',
    description: 'Live production server (kknutrivet.in)',
  ),
  test(
    name: 'Test Server',
    baseUrl: 'https://test.kknutrivet.in',
    description: 'Testing server (test.kknutrivet.in)',
  );

  const AppEnvironment({
    required this.name,
    required this.baseUrl,
    required this.description,
  });

  final String name;
  final String baseUrl;
  final String description;
}

class AppConfig {
  AppConfig._();

  static const String _envKey = 'app_selected_environment';

  // Point this at the deployed nvit-frontend API.
  // Override at build time with: --dart-define=API_BASE_URL=https://your-domain.com
  static const String _buildTimeApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kknutrivet.in',
  );

  static AppEnvironment _currentEnv = AppEnvironment.prod;
  static String _activeBaseUrl = _buildTimeApiBaseUrl;

  /// Currently active server environment
  static AppEnvironment get environment => _currentEnv;

  /// Active base URL (dynamic, can be switched at runtime)
  static String get apiBaseUrl => _activeBaseUrl;

  static bool get isProduction => _currentEnv == AppEnvironment.prod;
  static bool get isTest => _currentEnv == AppEnvironment.test;

  /// Load persisted server environment from SharedPreferences on app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEnv = prefs.getString(_envKey);
      if (savedEnv != null) {
        if (savedEnv == AppEnvironment.test.name || savedEnv == 'test') {
          _currentEnv = AppEnvironment.test;
          _activeBaseUrl = AppEnvironment.test.baseUrl;
        } else {
          _currentEnv = AppEnvironment.prod;
          _activeBaseUrl = AppEnvironment.prod.baseUrl;
        }
      } else {
        if (_buildTimeApiBaseUrl.contains('test.')) {
          _currentEnv = AppEnvironment.test;
          _activeBaseUrl = AppEnvironment.test.baseUrl;
        } else {
          _currentEnv = AppEnvironment.prod;
          _activeBaseUrl = _buildTimeApiBaseUrl;
        }
      }
      ApiClient.instance.updateBaseUrl(_activeBaseUrl);
    } catch (e) {
      debugPrint('Failed to initialize AppConfig environment: $e');
    }
  }

  /// Switch the active environment at runtime and persist the choice
  static Future<void> setEnvironment(AppEnvironment env) async {
    _currentEnv = env;
    _activeBaseUrl = env.baseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_envKey, env.name);
    } catch (e) {
      debugPrint('Failed to persist AppConfig environment: $e');
    }
    ApiClient.instance.updateBaseUrl(_activeBaseUrl);
  }

  static const String mixpanelToken = String.fromEnvironment(
    'MIXPANEL_TOKEN',
    defaultValue: 'af1124926e227683d3693b7038b9dc0f',
  );

  static const String appName = 'KK Nutrivet';
}
