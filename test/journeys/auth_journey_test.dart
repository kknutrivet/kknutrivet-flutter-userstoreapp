import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  configureTestEnvironment();

  testWidgets('guest is redirected from a protected route to login',
      (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/orders');

    expect(app.location, '/login');
    expect(find.text('Secure sign-in'), findsOneWidget);
    expect(find.text('Continue with mobile'), findsOneWidget);
  });

  testWidgets('phone OTP sign-in returns the user to the intercepted route',
      (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/orders');
    expect(app.location, '/login');

    // Step 1: request an OTP.
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await settle(tester);
    await tester.tap(find.text('Continue with mobile'));
    await settle(tester);

    // Step 2: verify it. MockAuthNotifier signs the user in without a network
    // round-trip, so this exercises the screen + router redirect only.
    await tester.enterText(find.byType(TextField).first, '123456');
    await settle(tester);
    await tester.tap(find.text('Verify & Continue'));
    await settle(tester);
    await settle(tester);

    expect(app.auth.currentUser, isNotNull);
    expect(app.location, '/orders');
    expect(find.textContaining('KKNV-1001'), findsWidgets);
  });

  testWidgets('logout from the profile returns to a signed-out shell',
      (tester) async {
    final app = await pumpTestApp(tester, user: testUser());

    await app.go('/profile');
    expect(app.location, '/profile');

    await tester.scrollUntilVisible(
      find.text('Log out'),
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await settle(tester);
    await tester.tap(find.text('Log out'));
    await settle(tester);

    // Confirmation dialog.
    await tester.tap(find.text('Log out').last);
    await settle(tester);

    expect(app.auth.currentUser, isNull);
    expect(app.auth.logoutCount, 1);

    await app.go('/orders');
    expect(app.location, '/login');
  });
}
