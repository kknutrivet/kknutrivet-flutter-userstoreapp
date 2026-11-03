import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/utils/customer_error.dart';
import 'package:nvit_app/features/checkout/widgets/checkout_payment_and_review.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  test('customer errors never expose server exception details', () {
    expect(
      customerError(ApiException('SQL internal secret', statusCode: 500)),
      'Could not save your changes. Check your connection and try again.',
    );
    expect(
      customerError(ApiException('expired', statusCode: 401)),
      'Please sign in again, then retry.',
    );
  });

  test('zero variant stock does not fall back to parent stock', () {
    final item = CartItem(
      id: 'item',
      productId: 'product',
      quantity: 2,
      product: Product(
        id: 'product',
        name: 'Product',
        slug: 'product',
        price: 100,
        stock: 20,
      ),
      variant: ProductVariant(
        id: 'variant',
        name: 'Small',
        price: 100,
        stock: 0,
      ),
    );
    expect(item.hasStockIssue, isTrue);
    expect(item.maxStock, 0);
  });

  testWidgets(
    'checkout recovery remains actionable at 200% text on a small phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var resolved = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              bottomNavigationBar: CheckoutStickyPlaceOrderBar(
                canPlace: false,
                submitting: false,
                paymentMethod: 'PARTIAL_COD',
                total: 1000,
                advanceAmount: 200,
                disabledReason:
                    'Delivery is unavailable here. Choose another address.',
                resolveLabel: 'Choose address',
                onResolve: () => resolved = true,
                onPlaceOrder: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('800'), findsOneWidget);
      await tester.tap(find.text('Choose address'));
      expect(resolved, isTrue);
      final semantics = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );
}
