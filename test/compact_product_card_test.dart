import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final testProductWithVariants = Product(
    id: 'prod-1',
    name: 'Royal Canin Maxi Adult Dry Dog Food Premium Formula',
    slug: 'royal-canin-maxi-adult',
    price: 999.0,
    mrp: 1299.0,
    requiresPrescription: true,
    variants: [
      ProductVariant(id: 'v1', name: '4 kg', price: 999.0, mrp: 1299.0, stock: 10),
      ProductVariant(id: 'v2', name: '10 kg', price: 2199.0, mrp: 2699.0, stock: 5),
    ],
  );

  final testProductSingle = Product(
    id: 'prod-2',
    name: 'Fiprofort Plus Spot On for Dogs 20-40kg',
    slug: 'fiprofort-plus-spot-on',
    price: 450.0,
    mrp: 520.0,
    size: '1 Pipette',
    stock: 15,
  );

  group('CompactProductCard Overflow Tests', () {
    for (final width in [320.0, 360.0, 390.0, 412.0]) {
      testWidgets('renders CompactProductCard in catalogue grid at ${width}px without bottom overflow', (tester) async {
        tester.view.physicalSize = Size(width * 3, 700 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FlutterErrorDetails? caughtDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: width < 380 ? 0.58 : 0.62,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, i) => CompactProductCard(
                    product: i.isEven ? testProductWithVariants : testProductSingle,
                    variant: CompactCardVariant.catalogue,
                  ),
                ),
              ),
            ),
          ),
        );

        FlutterError.onError = originalOnError;

        if (caughtDetails != null) {
          debugPrint('FLUTTER ERROR CAUGHT IN COMPACT CARD (${width}px):\n${caughtDetails.toString()}');
        }
        expect(caughtDetails, isNull);
      });

      testWidgets('renders CompactProductCard in homeGrid at ${width}px without bottom overflow', (tester) async {
        tester.view.physicalSize = Size(width * 3, 700 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FlutterErrorDetails? caughtDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: width < 350 ? 0.61 : 0.67,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, i) => CompactProductCard(
                    product: i.isEven ? testProductWithVariants : testProductSingle,
                    variant: CompactCardVariant.homeGrid,
                  ),
                ),
              ),
            ),
          ),
        );

        FlutterError.onError = originalOnError;

        if (caughtDetails != null) {
          debugPrint('FLUTTER ERROR CAUGHT IN HOME GRID (${width}px):\n${caughtDetails.toString()}');
        }
        expect(caughtDetails, isNull);
      });
    }

    testWidgets('renders CompactProductCard with 1.25x accessibility text scale without bottom overflow', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
              child: Scaffold(
                body: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, i) => CompactProductCard(
                    product: testProductWithVariants,
                    variant: CompactCardVariant.catalogue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      FlutterError.onError = originalOnError;

      if (caughtDetails != null) {
        debugPrint('FLUTTER ERROR CAUGHT IN 1.25x SCALE:\n${caughtDetails.toString()}');
      }
      expect(caughtDetails, isNull);
    });

    testWidgets('stepper inside narrow homeGrid card does not overflow when item is added to cart', (tester) async {
      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 156,
                child: CompactProductCard(
                  product: testProductSingle,
                  variant: CompactCardVariant.homeGrid,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap ADD button to transition to stepper (quantity = 1)
      final addButton = find.byKey(const ValueKey('add_filled'));
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Stepper must be displayed without overflow
      final stepper = find.byKey(const ValueKey('stepper'));
      expect(stepper, findsOneWidget);

      FlutterError.onError = originalOnError;
      expect(caughtDetails, isNull);
    });
  });
}
