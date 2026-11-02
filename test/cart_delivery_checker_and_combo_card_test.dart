import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/cart/screens/cart_screen.dart';
import 'package:nvit_app/features/home/widgets/home_combos_and_rx.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';

class _MockCartNotifier extends CartNotifier {
  _MockCartNotifier(this._items);
  final List<CartItem> _items;

  @override
  Future<List<CartItem>> build() async => _items;
}

class _MockPincodeNotifier extends DeliveryPincodeNotifier {
  _MockPincodeNotifier(this._pin);
  final String _pin;

  @override
  Future<String?> build() async => _pin;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleCombo = ComboBundle(
    id: 'combo-liv-deworm',
    name: 'Cattle Deworming (Herbal Syrup) & Liver Support Combo',
    description: 'Everyday care essentials for your cattle.',
    originalPrice: 1810,
    comboPrice: 1449,
    isActive: true,
    items: const [
      ComboItem(id: 'ci-1', productId: 'p1', quantity: 1),
      ComboItem(id: 'ci-2', productId: 'p2', quantity: 1),
      ComboItem(id: 'ci-3', productId: 'p3', quantity: 1),
    ],
  );

  group('Cart Delivery Checker Placement Tests', () {
    testWidgets('CartScreen places CartDeliveryCheckerCard above CartSummaryCard',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dummyProduct = Product(
        id: 'p1',
        name: 'Product 1',
        slug: 'prod-1',
        price: 500,
        mrp: 600,
        stock: 10,
      );
      final dummyItem = CartItem(
        id: 'ci-1',
        productId: 'p1',
        quantity: 1,
        product: dummyProduct,
      );

      final container = ProviderContainer(
        overrides: [
          cartProvider.overrideWith(() => _MockCartNotifier([dummyItem])),
          homeCombosProvider.overrideWith((ref) => Future.value(const [])),
          deliveryPincodeProvider.overrideWith(() => _MockPincodeNotifier('760004')),
          deliveryEtaProvider.overrideWith((ref) => Future.value(null)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deliveryCheckerFinder = find.byType(CartDeliveryCheckerCard);
      final summaryCardFinder = find.byType(CartSummaryCard);

      expect(deliveryCheckerFinder, findsOneWidget);
      expect(summaryCardFinder, findsOneWidget);

      // Verify CartDeliveryCheckerCard is visually rendered above CartSummaryCard (smaller dy)
      final deliveryTop = tester.getTopLeft(deliveryCheckerFinder).dy;
      final summaryTop = tester.getTopLeft(summaryCardFinder).dy;
      expect(deliveryTop, lessThan(summaryTop),
          reason: 'Delivery checker card must be positioned above Order Summary');

      // Verify CartSummaryCard itself does not contain an inline delivery checker
      expect(
        find.descendant(
          of: summaryCardFinder,
          matching: find.byType(CartDeliveryCheckerCard),
        ),
        findsNothing,
      );
    });
  });

  group('HomeComboCard Webapp-Style Matching Tests', () {
    testWidgets('HomeComboCard renders Save % badge, product count, title, strikethrough, and Add button',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          comboCartQuantityProvider(sampleCombo.id).overrideWithValue(0),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 210,
                  child: HomeComboCard(combo: sampleCombo),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge: Save 20%
      expect(find.text('Save 20%'), findsOneWidget);
      // Item count: 3 products
      expect(find.text('3 products'), findsOneWidget);
      // Title
      expect(
        find.text('Cattle Deworming (Herbal Syrup) & Liver Support Combo'),
        findsOneWidget,
      );
      // Price: ₹1,449
      expect(find.text('₹1,449'), findsOneWidget);
      // Strikethrough original price: ₹1,810
      expect(find.text('₹1,810'), findsOneWidget);
      // Add button
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('Cart Stepper & Delete Button Layout Tests', () {
    testWidgets(
        'CartComboBundleCard and CartItemTile keep + and - below and delete button on the right side',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dummyProduct = Product(
        id: 'p1',
        name: 'Single Product 1',
        slug: 'single-prod-1',
        price: 500,
        mrp: 600,
        stock: 10,
      );
      final singleItem = CartItem(
        id: 'ci-single',
        productId: 'p1',
        quantity: 1,
        product: dummyProduct,
      );
      final comboCartItem = CartItem(
        id: 'ci-combo',
        productId: 'p1',
        comboId: sampleCombo.id,
        comboName: sampleCombo.name,
        comboPrice: sampleCombo.comboPrice,
        quantity: 1,
        comboQuantity: 1,
        product: dummyProduct,
      );

      final container = ProviderContainer(
        overrides: [
          cartProvider.overrideWith(() => _MockCartNotifier([singleItem, comboCartItem])),
          homeCombosProvider.overrideWith((ref) => Future.value([sampleCombo])),
          comboCartQuantityProvider(sampleCombo.id).overrideWithValue(1),
          deliveryPincodeProvider.overrideWith(() => _MockPincodeNotifier('760004')),
          deliveryEtaProvider.overrideWith((ref) => Future.value(null)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In the stepper below, both cards should show Icons.remove and Icons.add
      // Even when quantity is 1, it should NOT replace Icons.remove with a delete trash can
      expect(find.byIcon(Icons.remove), findsNWidgets(2));
      expect(find.byIcon(Icons.add), findsNWidgets(2));

      // The delete action should be on the right side (IconButton with Icons.delete_outline_rounded)
      final deleteButtons = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.delete_outline_rounded,
      );
      expect(deleteButtons, findsNWidgets(2));
    });
  });
}
