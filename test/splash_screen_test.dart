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

  testWidgets('SplashScreen renders premium brand header and trust badge without overflow',
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
          builder: (context, state) => const Scaffold(body: Text('Home Page')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding Page')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(() => _MockOnboardingNotifier(true)),
          authProvider.overrideWith(() => _MockAuthNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Initial frame
    await tester.pump(const Duration(milliseconds: 100));

    // Verify brand assets and typography
    expect(find.text('KK NUTRIVET'), findsOneWidget);
    expect(find.text('HEALTH  •  CARE  •  TRUST'), findsOneWidget);
    expect(find.text('Veterinary Medicine & Animal Healthcare'), findsOneWidget);
    expect(find.text('100% Genuine Veterinary Care'), findsOneWidget);

    // Verify horizontal centering on 360dp screen (center = 180dp)
    final brandCenter = tester.getCenter(find.text('KK NUTRIVET'));
    expect(brandCenter.dx, closeTo(180.0, 1.0));

    final trustBadgeRowCenter = tester.getCenter(find.byType(Row).last);
    expect(trustBadgeRowCenter.dx, closeTo(180.0, 1.0));

    // Clean timer resolution
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify router navigation
    expect(find.text('Home Page'), findsOneWidget);
  });
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
