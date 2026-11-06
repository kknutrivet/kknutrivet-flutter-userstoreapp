import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';

import '../support/app_harness.dart';

void main() {
  configureTestEnvironment();

  group('Cold start', () {
    testWidgets('signed-in returning user lands on home', (tester) async {
      final app = await pumpTestApp(
        tester,
        user: testUser(),
        onboardingComplete: true,
        route: '/splash',
      );

      // Splash holds for ~1s while auth/onboarding resolve.
      await tester.pump(const Duration(milliseconds: 1200));
      await settle(tester);

      expect(app.location, '/home');
      expect(find.byType(WebsiteBottomNav), findsOneWidget);
    });

    testWidgets('first install is routed through onboarding', (tester) async {
      final app = await pumpTestApp(
        tester,
        user: null,
        onboardingComplete: false,
        route: '/splash',
      );

      await tester.pump(const Duration(milliseconds: 1200));
      await settle(tester);

      expect(app.location, '/onboarding');
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await settle(tester);

      expect(app.location, '/home');
      expect(app.onboarding.completed, isTrue);
    });
  });

  group('Bottom navigation', () {
    testWidgets('each tab opens its branch', (tester) async {
      final app = await pumpTestApp(tester, user: testUser());

      Future<void> tapTab(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await settle(tester);
      }

      await tapTab('Shop');
      expect(app.location, '/products');
      expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);

      await tapTab('Care');
      expect(app.location, '/consultations');

      await tapTab('Shots');
      expect(app.location, '/shots');

      await tapTab('Account');
      expect(app.location, '/profile');

      await tapTab('Home');
      expect(app.location, '/home');
    });
  });

  testWidgets('guest can browse the storefront', (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/products');

    expect(app.location, '/products');
    expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);
    expect(find.text('PetCalm Calming Spray 100ml'), findsOneWidget);
  });
}
