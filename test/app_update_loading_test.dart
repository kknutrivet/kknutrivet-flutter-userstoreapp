import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nvit_app/core/services/app_update_service.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  for (final outdated in [false, true]) {
    test('waits for package metadata before reporting outdated=$outdated', () async {
      final metadata = Completer<PackageInfo>();
      final container = ProviderContainer(overrides: [
        storeSettingsProvider.overrideWith((ref) async => StoreSettings(
          freeDeliveryThreshold: 500, deliveryCharge: 49,
          appUpdate: const AppUpdateConfig(
            forceUpdateEnabled: true,
            minAppVersion: '2.0.0',
            minBuildNumber: 20,
          ),
        )),
        packageInfoProvider.overrideWith((ref) => metadata.future),
      ]);
      addTearDown(container.dispose);
      final published = <AppUpdateStatus>[];
      container.listen(appUpdateCheckProvider, (_, next) {
        if (next.hasValue) published.add(next.requireValue.status);
      }, fireImmediately: true);
      await container.read(storeSettingsProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(appUpdateCheckProvider).isLoading, isTrue);
      expect(published, isEmpty);

      metadata.complete(PackageInfo(
        appName: 'KK Nutrivet', packageName: 'com.kknutrivet.shop',
        version: outdated ? '1.5.0' : '2.0.0',
        buildNumber: outdated ? '15' : '20', buildSignature: '',
      ));
      final result = await container.read(appUpdateCheckProvider.future);
      expect(result.isUpdateRequired, outdated);
      expect(published, [outdated ? AppUpdateStatus.updateRequired : AppUpdateStatus.upToDate]);
      expect(result.currentBuildNumber, outdated ? 15 : 20);
    });
  }
}
