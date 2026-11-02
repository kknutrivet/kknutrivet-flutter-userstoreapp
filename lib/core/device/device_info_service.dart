import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service to inspect device and application metadata.
/// Supplies headers to ApiClient and super-properties to MixpanelService.
class DeviceInfoService {
  DeviceInfoService._();
  static final DeviceInfoService instance = DeviceInfoService._();

  bool _initialized = false;
  String _platform = 'unknown';
  String _osVersion = 'unknown';
  String _model = 'unknown';
  String _brand = 'unknown';
  String _appVersion = '1.0.0';
  String _buildNumber = '1';
  String _deviceId = '';

  String get platform => _platform;
  String get osVersion => _osVersion;
  String get model => _model;
  String get brand => _brand;
  String get appVersion => _appVersion;
  String get buildNumber => _buildNumber;
  String get deviceId => _deviceId;

  /// User-Agent formatted for standard HTTP parsing:
  /// e.g. "KKNutrivet-App/1.0.0 (Linux; Android 14; Mobile; Pixel 8)"
  String get userAgent {
    final osPrefix = _platform == 'android'
        ? 'Linux; Android $_osVersion'
        : _platform == 'ios'
            ? 'iPhone; CPU iPhone OS $_osVersion like Mac OS X'
            : _platform;
    return 'KKNutrivet-App/$_appVersion ($osPrefix; Mobile; $_brand $_model)';
  }

  /// Initialize metadata asynchronously during app startup.
  Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      var storedId = prefs.getString('app_device_id');
      if (storedId == null || storedId.isEmpty) {
        final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
        storedId = 'dev_${DateTime.now().millisecondsSinceEpoch}_$rand';
        await prefs.setString('app_device_id', storedId);
      }
      _deviceId = storedId;
    } catch (_) {
      _deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
      _buildNumber = packageInfo.buildNumber.isNotEmpty ? packageInfo.buildNumber : '1';
    } catch (_) {
      _appVersion = '1.0.0';
      _buildNumber = '1';
    }

    if (kIsWeb) {
      _platform = 'web';
      _osVersion = 'Web';
      _model = 'Browser';
      _brand = 'Generic';
      _initialized = true;
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        _platform = 'android';
        final android = await deviceInfo.androidInfo;
        _osVersion = android.version.release.isNotEmpty
            ? android.version.release
            : '${android.version.sdkInt}';
        _model = android.model.isNotEmpty ? android.model : 'Android Device';
        _brand = android.brand.isNotEmpty
            ? android.brand
            : (android.manufacturer.isNotEmpty ? android.manufacturer : 'Android');
      } else if (Platform.isIOS) {
        _platform = 'ios';
        final ios = await deviceInfo.iosInfo;
        _osVersion = ios.systemVersion.isNotEmpty ? ios.systemVersion : 'iOS';
        _model = ios.utsname.machine.isNotEmpty ? ios.utsname.machine : ios.model;
        _brand = 'Apple';
      } else if (Platform.isMacOS) {
        _platform = 'macos';
        final mac = await deviceInfo.macOsInfo;
        _osVersion = mac.osRelease.isNotEmpty ? mac.osRelease : Platform.operatingSystemVersion;
        _model = mac.model.isNotEmpty ? mac.model : 'Macintosh';
        _brand = 'Apple';
      } else {
        _platform = Platform.operatingSystem;
        _osVersion = Platform.operatingSystemVersion;
        _model = 'Desktop';
        _brand = 'Generic';
      }
    } catch (e) {
      // Safe fallback on Platform object if device_info fails
      try {
        _platform = Platform.operatingSystem;
        _osVersion = Platform.operatingSystemVersion;
        _model = 'Mobile';
        _brand = 'Generic';
      } catch (_) {
        _platform = 'mobile';
        _osVersion = 'unknown';
        _model = 'unknown';
        _brand = 'unknown';
      }
    }

    _initialized = true;
  }

  /// Headers to attach to every outgoing ApiClient Dio request.
  Map<String, String> getApiHeaders() {
    return {
      'User-Agent': userAgent,
      'X-Device-Platform': _platform,
      'X-Device-OS': _osVersion,
      'X-Device-Model': _model,
      'X-Device-Brand': _brand,
      'X-Device-Id': _deviceId,
      'X-App-Version': '$_appVersion+$_buildNumber',
    };
  }
}
