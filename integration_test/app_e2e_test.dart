/// On-device end-to-end automation.
///
/// Run on a connected emulator/device:
///   `flutter test integration_test -d <device-id>`
///
/// These flows exercise the same router, providers and screens as the widget
/// journeys, but with real rendering, gestures and platform channels.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/app_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureTestEnvironment();

  testWidgets('cold start lands on the home shell', (tester) async {
    final app = await pumpTestApp(
      tester,
      user: testUser(),
      onboardingComplete: true,
      route: '/splash',
    );

    await tester.pump(const Duration(milliseconds: 1200));
    await settle(tester);

    expect(app.location, '/home');
    expect(find.text('Shop'), findsWidgets);
  });

  testWidgets('guest can browse, open a product and reach checkout',
      (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/products');
    expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);

    await tester.tap(find.text('GranLiv Tonic 500ml'));
    await settle(tester);
    expect(app.location, '/product/granliv-tonic-500ml');

    await tester.tap(find.text('Add to Cart'));
    await settle(tester);

    await app.go('/cart');
    expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await settle(tester);
    expect(app.location, '/checkout');
    expect(find.text('Delivery address'), findsOneWidget);
  });

  testWidgets('protected routes send guests to sign-in', (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/orders');

    expect(app.location, '/login');
    expect(find.text('Continue with mobile'), findsOneWidget);
  });
}
