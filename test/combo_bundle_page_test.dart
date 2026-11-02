import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/router/app_router.dart';
import 'package:nvit_app/features/combos/screens/combo_detail_screen.dart';
import 'package:nvit_app/features/products/screens/product_list_screen.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleCombo = ComboBundle(
    id: 'combo-1',
    name: 'Cattle Vitality Care Kit',
    description: 'Everyday cattle wellness kit',
    originalPrice: 1200,
    comboPrice: 950,
    isActive: true,
    items: [
      ComboItem(
        id: 'ci-1',
        productId: 'prod-1',
        quantity: 1,
        product: Product(
          id: 'prod-1',
          name: 'CalciMax Gold 1L',
          slug: 'calcimax-gold-1l',
          price: 600,
          mrp: 700,
          animalTypes: ['Cattle'],
        ),
      ),
      ComboItem(
        id: 'ci-2',
        productId: 'prod-2',
        quantity: 1,
        product: Product(
          id: 'prod-2',
          name: 'GranLiv Tonic 500ml',
          slug: 'granliv-tonic-500ml',
          price: 350,
          mrp: 400,
          animalTypes: ['Cattle'],
        ),
      ),
    ],
  );

  group('Combo / Bundle Tests', () {
    testWidgets('ComboDetailScreen renders full web-styled sections',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            comboDetailProvider('combo-1')
                .overrideWith((ref) => Future.value(sampleCombo)),
            comboCartQuantityProvider('combo-1').overrideWithValue(0),
            cartCountProvider.overrideWithValue(0),
          ],
          child: const MaterialApp(
            home: ComboDetailScreen(comboId: 'combo-1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Heading and Subtitle
      expect(find.text('Cattle Vitality Care Kit'), findsWidgets);
      expect(find.text('Everyday cattle wellness kit'), findsOneWidget);

      // Care Combo and Savings badges
      expect(find.text('CARE COMBO'), findsOneWidget);
      expect(find.text('Save 21%'), findsWidgets);

      // What's in this combo section
      expect(find.text("What's in this combo"), findsOneWidget);
      expect(find.text('CalciMax Gold 1L'), findsOneWidget);
      expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);

      // Why this combo works
      expect(find.text('Why this combo works'), findsOneWidget);

      // Care tip
      expect(find.text('Care tip'), findsOneWidget);

      // Sticky Bottom Add to Cart CTA
      expect(find.text('Add to Cart'), findsOneWidget);
    });

    testWidgets(
        'ProductListScreen displays care combos when filter category is Combos without exception',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productFilterProvider.overrideWith(
              (ref) => ProductFilter(category: 'Combos'),
            ),
            homeCombosProvider.overrideWith(
              (ref) => Future.value([sampleCombo]),
            ),
            comboCartQuantityProvider('combo-1').overrideWithValue(0),
          ],
          child: const MaterialApp(
            home: ProductListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify combos list rendered cleanly
      expect(find.text('1 care combos'), findsOneWidget);
      expect(find.text('Bundle & Save'), findsOneWidget);
      expect(find.text('Cattle Vitality Care Kit'), findsOneWidget);
    });

    testWidgets(
        'appRouter builds /products?category=Combos route without throwing Riverpod build error',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          productsListProvider.overrideWith((ref) => Future.value([])),
          homeCombosProvider.overrideWith((ref) => Future.value([sampleCombo])),
        ],
      );
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Advance past SplashScreen timer
      await tester.pump(const Duration(milliseconds: 800));

      // Navigate to /products?category=Combos
      router.go('/products?category=Combos');
      await tester.pump(const Duration(milliseconds: 200));

      // If there was a Riverpod build-phase mutation exception, tester.takeException() would catch it
      expect(tester.takeException(), isNull);
    });
  });
}
