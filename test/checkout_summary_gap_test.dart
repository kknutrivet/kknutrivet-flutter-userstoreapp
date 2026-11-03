import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/checkout/screens/checkout_screen.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';

class MockCartNotifier extends CartNotifier {
  MockCartNotifier(this._items);
  final List<CartItem> _items;

  @override
  Future<List<CartItem>> build() async => _items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleProduct = Product(
    id: 'prod-chk-1',
    name: 'Ondapet Syrup 30ml',
    slug: 'ondapet-syrup',
    price: 219.0,
    mrp: 240.0,
  );

  final sampleCartItem = CartItem(
    id: 'ci-chk-1',
    productId: 'prod-chk-1',
    quantity: 1,
    product: sampleProduct,
  );

  group('CheckoutScreen Gap Tests', () {
    testWidgets(
      'checkout explains missing address above the disabled payment action',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              cartProvider.overrideWith(
                () => MockCartNotifier([sampleCartItem]),
              ),
              cartTotalProvider.overrideWithValue(219.0),
              cartCountProvider.overrideWithValue(1),
              addressesProvider.overrideWith((ref) => Future.value([])),
              homeCombosProvider.overrideWith((ref) => Future.value([])),
            ],
            child: const MaterialApp(home: CheckoutScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll to bottom of checkout list
        final orderTotalFinder = find.text('Order total');
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -1200),
        );
        await tester.pumpAndSettle();

        expect(orderTotalFinder, findsOneWidget);
        final payButtonFinder = find.byType(ElevatedButton);
        expect(payButtonFinder, findsOneWidget);

        final summaryCardFinder = find.byType(CheckoutSummaryCard);
        expect(summaryCardFinder, findsOneWidget);

        expect(
          find.text('Add a delivery address to continue.'),
          findsOneWidget,
        );
        expect(
          tester.widget<ElevatedButton>(payButtonFinder).onPressed,
          isNull,
        );
        expect(find.text('Choose address'), findsOneWidget);
      },
    );
  });
}
