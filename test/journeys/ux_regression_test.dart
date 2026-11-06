/// Regression tests for UI/UX issues found while reviewing the visual suite.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/widgets/markdown_view.dart';

import '../support/app_harness.dart';
import '../support/fake_api_client.dart';

void main() {
  configureTestEnvironment();

  testWidgets('blog article renders CMS HTML as readable text', (tester) async {
    final app = await pumpTestApp(
      tester,
      user: testUser(),
      route: '/blog/pet-nutrition-basics',
    );

    expect(app.location, '/blog/pet-nutrition-basics');
    expect(find.byType(MarkdownView), findsOneWidget);
    expect(
      find.text('Balanced meals keep pets active and healthy.'),
      findsOneWidget,
    );
    expect(find.textContaining('<p>'), findsNothing);
  });

  testWidgets('unknown deep link shows a friendly page, not a GoException',
      (tester) async {
    final app = await pumpTestApp(tester, user: testUser());

    await app.go('/this-route-does-not-exist');

    expect(find.text('We couldn’t find that page'), findsOneWidget);
    expect(find.textContaining('GoException'), findsNothing);
    expect(find.text('Go to home'), findsOneWidget);
  });

  testWidgets('empty Dr. Paw reply shows a fallback instead of a blank bubble',
      (tester) async {
    await pumpTestApp(
      tester,
      user: testUser(),
      route: '/vet?question=food&animalType=Dog',
    );

    expect(
      find.text(
        'I could not generate a response just now. Please try asking again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('pet load failure asks to load, not to save changes',
      (tester) async {
    final api = FakeApiClient()
      ..failOn(
        RegExp(r'^/pets/pet-1$'),
        ApiException('Server unavailable', statusCode: 500),
      );

    await pumpTestApp(
      tester,
      user: testUser(),
      api: api,
      route: '/pets/pet-1',
    );

    expect(find.text('Unable to load profile'), findsOneWidget);
    expect(
      find.textContaining('Could not load this profile'),
      findsOneWidget,
    );
    expect(find.textContaining('save your changes'), findsNothing);
  });
}
