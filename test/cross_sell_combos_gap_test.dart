import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/cart/widgets/cart_coupons_and_coins.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleCombo = ComboBundle(
    id: 'combo-deworm-1',
    name: 'Cattle Deworming (Herbal Syrup) & Liver Support Combo',
    description: 'Complete routine care for cattle health.',
    originalPrice: 1810,
    comboPrice: 1449,
    isActive: true,
    items: [],
  );

  group('CrossSellCombosRail Gap Tests', () {
    testWidgets('gap between product title and price is compact (< 25px)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CrossSellCombosRail(
                  combos: [sampleCombo],
                  cartItems: const [],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Heading and card components exist
      expect(
        find.text('Care Combos · Complete the routine'),
        findsOneWidget,
      );
      expect(
        find.text('Cattle Deworming (Herbal Syrup) & Liver Support Combo'),
        findsOneWidget,
      );
      expect(find.text('₹1449'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      // Measure gap between bottom of title and top of price
      final titleFinder = find.text(
        'Cattle Deworming (Herbal Syrup) & Liver Support Combo',
      );
      final priceFinder = find.text('₹1449');

      final titleBottom = tester.getBottomLeft(titleFinder).dy;
      final priceTop = tester.getTopLeft(priceFinder).dy;

      final gap = priceTop - titleBottom;
      // Gap must be snug (< 25px) and not inflated to ~50px
      expect(gap, lessThan(25.0));
      expect(gap, greaterThan(0.0));
    });
  });
}
