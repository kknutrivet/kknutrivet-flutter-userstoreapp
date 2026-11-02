import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/features/home/widgets/home_animal_selector.dart';
import 'package:nvit_app/features/home/widgets/home_models_and_data.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final testProducts = [
    Product(
      id: 'p1',
      name: 'Granliv Pet (Liver Tonic)',
      slug: 'granliv-pet',
      price: 179.0,
      mrp: 195.0,
    ),
    Product(
      id: 'p2',
      name: 'Gratone Pet (Amino Syrup)',
      slug: 'gratone-pet',
      price: 199.0,
      mrp: 225.0,
    ),
  ];

  group('HomeAnimalProductRail Gap & Spacing Tests', () {
    testWidgets('gap between heading and product list is compact even on notch devices',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Simulate a notch device with 44px top padding from status bar/camera
      const notchMediaQuery = MediaQueryData(
        size: Size(390, 844),
        padding: EdgeInsets.only(top: 44, bottom: 34),
        devicePixelRatio: 3.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            animalTypeProductsProvider('Dog').overrideWith((ref) => testProducts),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: notchMediaQuery,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: HomeAnimalProductRail(entry: kHomeAnimals[0]),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Heading text
      final headingFinder = find.text('Dog care like a tail wag');
      expect(headingFinder, findsOneWidget);

      // First product card
      final productCardFinder = find.byType(CompactProductCard).first;
      expect(productCardFinder, findsOneWidget);

      final headingBottom = tester.getBottomLeft(headingFinder).dy;
      final productCardTop = tester.getTopLeft(productCardFinder).dy;

      // The distance between the heading line and product card should be compact (< 40px),
      // and NOT bloated by the 44px notch mediaQuery.padding.top.
      final gap = productCardTop - headingBottom;
      expect(gap, lessThan(35.0));
      expect(gap, greaterThan(0.0));
    });
  });
}
