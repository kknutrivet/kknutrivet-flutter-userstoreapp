import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/app_routes.dart';

void main() {
  configureTestEnvironment();

  for (final route in appRoutes) {
    testWidgets('route ${route.path} renders without crashing', (tester) async {
      final app = await pumpTestApp(tester, user: testUser());

      await app.go(route.path);

      expect(
        app.location,
        route.location,
        reason: 'route ${route.path} landed on ${app.location}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'route ${route.path} threw during render',
      );
    });
  }

  testWidgets('unknown deep links land on a safe, renderable screen',
      (tester) async {
    final app = await pumpTestApp(tester, user: testUser());

    await app.go('/this-route-does-not-exist');

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
