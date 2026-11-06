import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  configureTestEnvironment();

  testWidgets('guest browses, opens a product, adds to cart and checks out',
      (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/products');
    expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);

    // Open the product detail page by tapping the card.
    await tester.tap(find.text('GranLiv Tonic 500ml'));
    await settle(tester);

    expect(app.location, '/product/granliv-tonic-500ml');
    expect(find.text('Add to Cart'), findsOneWidget);

    await tester.tap(find.text('Add to Cart'));
    await settle(tester);

    // Cart now contains the product; the API client should not have been
    // asked to hit the server for a guest add.
    expect(app.api.callsTo('/cart'), isEmpty);

    await app.go('/cart');
    expect(app.location, '/cart');
    expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);

    await tester.tap(find.text('Checkout'));
    await settle(tester);

    expect(app.location, '/checkout');
    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.textContaining('Order review'), findsOneWidget);
  });

  testWidgets('out-of-stock products show a restock path instead of add',
      (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/product/dewormsure-tablet-strip');

    expect(app.location, '/product/dewormsure-tablet-strip');
    expect(
      find.textContaining(RegExp('out of stock', caseSensitive: false)),
      findsWidgets,
    );
    expect(find.text('Notify me when back in stock'), findsOneWidget);
  });

  testWidgets('search submits to the catalogue results route',
      (tester) async {
    final app = await pumpTestApp(tester, user: null);

    await app.go('/search');
    expect(app.location, '/search');

    await tester.enterText(find.byType(TextField).first, 'GranLiv');
    await settle(tester);

    // Suggestions are debounced through /api/search/suggestions.
    expect(
      app.api.calls.any((c) => c.path == '/search/suggestions'),
      isTrue,
    );

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);

    expect(app.location, '/products');
    expect(app.router.state.uri.queryParameters['search'], 'GranLiv');
  });
}
