import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/store_settings.dart';
import '../../providers/app_providers.dart';

enum AppUpdateStatus {
  upToDate,
  updateRequired,
  maintenance,
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.status,
    required this.config,
    required this.currentVersion,
    required this.currentBuildNumber,
  });

  final AppUpdateStatus status;
  final AppUpdateConfig config;
  final String currentVersion;
  final int currentBuildNumber;

  bool get isBlocked =>
      status == AppUpdateStatus.updateRequired ||
      status == AppUpdateStatus.maintenance;

  bool get isMaintenance => status == AppUpdateStatus.maintenance;
  bool get isUpdateRequired => status == AppUpdateStatus.updateRequired;
}

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return PackageInfo(
      appName: 'KK Nutrivet',
      packageName: 'com.kknutrivet.shop',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  }
});

final appUpdateCheckProvider = FutureProvider<AppUpdateCheckResult>((ref) async {
  final settings = ref.watch(storeSettingsProvider).valueOrNull ??
      await ref.watch(storeSettingsProvider.future).catchError((_) => StoreSettings.defaults());
  PackageInfo packageInfo;
  try {
    packageInfo = ref.watch(packageInfoProvider).valueOrNull ??
        PackageInfo(
          appName: 'KK Nutrivet',
          packageName: 'com.kknutrivet.shop',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
          installerStore: null,
        );
  } catch (_) {
    packageInfo = PackageInfo(
      appName: 'KK Nutrivet',
      packageName: 'com.kknutrivet.shop',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  }

  final currentVersion = packageInfo.version.trim();
  final currentBuildNumber = int.tryParse(packageInfo.buildNumber.trim()) ?? 1;

  final config = settings.appUpdate;

  if (config.maintenanceMode) {
    return AppUpdateCheckResult(
      status: AppUpdateStatus.maintenance,
      config: config,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
    );
  }

  if (config.forceUpdateEnabled &&
      config.isOutdated(
        currentBuildNumber: currentBuildNumber,
        currentVersion: currentVersion,
      )) {
    return AppUpdateCheckResult(
      status: AppUpdateStatus.updateRequired,
      config: config,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
    );
  }

  return AppUpdateCheckResult(
    status: AppUpdateStatus.upToDate,
    config: config,
    currentVersion: currentVersion,
    currentBuildNumber: currentBuildNumber,
  );
});

/// Opens the app in Google Play Store, trying the market:// URI first before web fallback.
Future<bool> launchPlayStore({String? overrideUrl}) async {
  final marketUri = Uri.parse('market://details?id=com.kknutrivet.shop');
  final webUri = Uri.parse(
    overrideUrl != null && overrideUrl.isNotEmpty
        ? overrideUrl
        : 'https://play.google.com/store/apps/details?id=com.kknutrivet.shop',
  );

  try {
    if (await canLaunchUrl(marketUri)) {
      return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}

  return await launchUrl(webUri, mode: LaunchMode.externalApplication);
}
