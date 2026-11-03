import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/router/app_router.dart';
import 'package:nvit_app/core/services/app_update_service.dart';
import 'package:nvit_app/features/consultations/widgets/care_chat_thread_widgets.dart';
import 'package:nvit_app/features/system/screens/force_update_screen.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  group('AppUpdateConfig version & build comparisons', () {
    test('isOutdated returns true when current build number is lower than minimum', () {
      const config = AppUpdateConfig(
        forceUpdateEnabled: true,
        minBuildNumber: 5,
        minAppVersion: '1.0.0',
      );

      expect(config.isOutdated(currentBuildNumber: 4, currentVersion: '1.0.0'), isTrue);
      expect(config.isOutdated(currentBuildNumber: 5, currentVersion: '1.0.0'), isFalse);
      expect(config.isOutdated(currentBuildNumber: 6, currentVersion: '1.0.0'), isFalse);
    });

    test('isOutdated returns true when semantic version is lower than minimum', () {
      const config = AppUpdateConfig(
        forceUpdateEnabled: true,
        minBuildNumber: 1,
        minAppVersion: '1.2.0',
      );

      expect(config.isOutdated(currentBuildNumber: 1, currentVersion: '1.1.9'), isTrue);
      expect(config.isOutdated(currentBuildNumber: 1, currentVersion: '1.0.5'), isTrue);
      expect(config.isOutdated(currentBuildNumber: 1, currentVersion: '1.2.0'), isFalse);
      expect(config.isOutdated(currentBuildNumber: 1, currentVersion: '2.0.0'), isFalse);
    });
  });

  group('ForceUpdateScreen widget tests', () {
    testWidgets('renders Update Required screen when forceUpdateEnabled is active', (tester) async {
      final checkResult = AppUpdateCheckResult(
        status: AppUpdateStatus.updateRequired,
        config: const AppUpdateConfig(
          forceUpdateEnabled: true,
          minBuildNumber: 2,
          minAppVersion: '1.0.1',
          latestVersion: '1.0.2',
          forceUpdateTitle: 'Mandatory Update',
          forceUpdateMessage: 'A critical update is required to continue using KK Nutrivet.',
        ),
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateCheckProvider.overrideWith((ref) async => checkResult),
          ],
          child: const MaterialApp(
            home: ForceUpdateScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mandatory Update'), findsOneWidget);
      expect(find.text('A critical update is required to continue using KK Nutrivet.'), findsOneWidget);
      expect(find.text('Update from Google Play'), findsOneWidget);
      expect(find.textContaining('v1.0.0 (Build 1)'), findsOneWidget);
      expect(find.textContaining('v1.0.1 (Build 2)'), findsOneWidget);
    });

    testWidgets('renders Scheduled Maintenance screen when maintenanceMode is true', (tester) async {
      final checkResult = AppUpdateCheckResult(
        status: AppUpdateStatus.maintenance,
        config: const AppUpdateConfig(
          maintenanceMode: true,
          maintenanceMessage: 'Undergoing server maintenance. Back in 30 minutes.',
        ),
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateCheckProvider.overrideWith((ref) async => checkResult),
          ],
          child: const MaterialApp(
            home: ForceUpdateScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Scheduled Maintenance'), findsOneWidget);
      expect(find.text('Undergoing server maintenance. Back in 30 minutes.'), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
    });

    testWidgets('appRouter redirects to /update when StoreSettings maintenanceMode is active', (tester) async {
      final maintenanceSettings = StoreSettings.defaults();
      final settingsWithMaintenance = StoreSettings(
        freeDeliveryThreshold: maintenanceSettings.freeDeliveryThreshold,
        deliveryCharge: maintenanceSettings.deliveryCharge,
        appUpdate: const AppUpdateConfig(
          maintenanceMode: true,
          maintenanceMessage: 'Emergency server maintenance in progress.',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeSettingsProvider.overrideWith((ref) async => settingsWithMaintenance),
            onboardingProvider.overrideWith(() => _MockOnboardingDone()),
            authProvider.overrideWith(() => _MockAuthNull()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();

      expect(find.text('Scheduled Maintenance'), findsOneWidget);
      expect(find.text('Emergency server maintenance in progress.'), findsOneWidget);
    });
  });

  group('CareChat Media Picker Sheet test', () {
    testWidgets('shows live photo, live video, gallery photo, and gallery video options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showCareChatMediaPickerSheet(context),
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Attach Photo or Video'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Record Video'), findsOneWidget);
      expect(find.text('Photo Gallery'), findsOneWidget);
      expect(find.text('Video Gallery'), findsOneWidget);
    });
  });
}

class _MockOnboardingDone extends OnboardingNotifier {
  @override
  Future<bool> build() async => true;
}

class _MockAuthNull extends AuthNotifier {
  @override
  Future<AppUser?> build() async => null;
}
