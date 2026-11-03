import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/widgets/home_combos_and_rx.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('HomePrescriptionCard Responsiveness & Overflow Tests', () {
    for (final width in [280.0, 300.0, 320.0, 360.0, 390.0, 412.0, 480.0]) {
      testWidgets('renders HomePrescriptionCard on ${width}px screen without horizontal overflow', (tester) async {
        tester.view.physicalSize = Size(width * 3, 700 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FlutterErrorDetails? caughtDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeSettingsProvider.overrideWith(
                (ref) => Future.value(
                  StoreSettings(freeDeliveryThreshold: 500, deliveryCharge: 49),
                ),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HomePrescriptionCard(),
                ),
              ),
            ),
          ),
        );

        FlutterError.onError = originalOnError;

        if (caughtDetails != null) {
          debugPrint('FULL FLUTTER ERROR on ${width}px:\n${caughtDetails.toString()}');
        }
        expect(caughtDetails, isNull);

        expect(find.text('Upload care slip'), findsOneWidget);
        expect(find.text('Free review · Camera or gallery photo'), findsOneWidget);
      });
    }

    testWidgets('renders HomePrescriptionCard with 1.3x accessibility text scale without horizontal overflow', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeSettingsProvider.overrideWith(
              (ref) => Future.value(
                StoreSettings(freeDeliveryThreshold: 500, deliveryCharge: 49),
              ),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: HomePrescriptionCard(),
                ),
              ),
            ),
          ),
        ),
      );

      FlutterError.onError = originalOnError;

      if (caughtDetails != null) {
        debugPrint('FULL FLUTTER ERROR on 1.3x text scale:\n${caughtDetails.toString()}');
      }
      expect(caughtDetails, isNull);
    });
  });
}
