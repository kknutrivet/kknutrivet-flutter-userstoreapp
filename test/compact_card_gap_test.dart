import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final testProduct = Product(
    id: 'prod-granliv-1',
    name: 'Granliv Pet (Liver Tonic)',
    slug: 'granliv-pet-liver-tonic',
    price: 179.0,
    mrp: 195.0,
    size: '200 ml',
    category: 'Supplements',
    animalTypes: ['Dog'],
    image: 'assets/images/animal-dog.png',
  );

  group('CompactProductCard Gap Tests', () {
    testWidgets('gap between product size/name and price is tight and compact on 390px phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 390 < 350 ? 0.61 : 0.67,
                  ),
                  itemCount: 2,
                  itemBuilder: (context, i) => CompactProductCard(
                    product: testProduct,
                    variant: CompactCardVariant.homeGrid,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final sizeFinder = find.text('200 ml').first;
      final priceFinder = find.text('₹179').first;
      expect(sizeFinder, findsOneWidget);
      expect(priceFinder, findsOneWidget);

      final sizeBottom = tester.getBottomLeft(sizeFinder).dy;
      final priceTop = tester.getTopLeft(priceFinder).dy;
      final gap = priceTop - sizeBottom;

      // Gap should be natural and compact (< 30px), NOT the previous 65-80px empty void
      expect(gap, lessThan(30.0));
      expect(gap, greaterThan(0.0));
    });
  });
}
