import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/splash/screens/splash_screen.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'SplashScreen places tagline beneath the logo and only the loader at the bottom',
    (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 780 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('Home Page')),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) =>
                const Scaffold(body: Text('Onboarding Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingProvider.overrideWith(
              () => _MockOnboardingNotifier(true),
            ),
            authProvider.overrideWith(() => _MockAuthNotifier()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Initial frame
      await tester.pump(const Duration(milliseconds: 100));

      // Verify brand assets and typography
      expect(find.text('KK NUTRIVET'), findsNothing);
      expect(find.text('KK Nutrivet'), findsNothing);
      expect(
        find.text('Nutrition. Wellness. Veterinary care.'),
        findsOneWidget,
      );
      expect(find.text('Care for every animal.'), findsNothing);

      // Verify company logo is displayed and not dr-paw mascot
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(imageFinder);
      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/logo.png');
      expect(assetImage.assetName, isNot(contains('dr-paw')));

      // Verify horizontal centering on 360dp screen (center = 180dp)
      final brandCenter = tester.getCenter(imageFinder);
      expect(brandCenter.dx, closeTo(180.0, 1.0));

      final tagline = find.text('Nutrition. Wellness. Veterinary care.');
      final gap =
          tester.getTopLeft(tagline).dy - tester.getBottomLeft(imageFinder).dy;
      expect(gap, inInclusiveRange(16.0, 30.0));
      expect(
        tester.getTopLeft(find.byType(CircularProgressIndicator)).dy,
        greaterThan(tester.getBottomLeft(tagline).dy),
      );

      // Clean timer resolution
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verify router navigation
      expect(find.text('Home Page'), findsOneWidget);
    },
  );
}

class _MockOnboardingNotifier extends OnboardingNotifier {
  _MockOnboardingNotifier(this._val);
  final bool _val;
  @override
  Future<bool> build() async => _val;
}

class _MockAuthNotifier extends AuthNotifier {
  @override
  Future<AppUser?> build() async => null;
}
