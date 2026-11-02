import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nvit_app/core/widgets/product_card.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('ProductImageCover Tests', () {
    testWidgets('renders dual-layer cover with backdrop blur and contain foreground', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 160,
              child: ProductImageCover(
                imageUrl: 'https://example.com/test-product.jpg',
                blurSigma: 14.0,
                backdropOpacity: 0.42,
              ),
            ),
          ),
        ),
      );

      // Verify ProductImageCover renders
      expect(find.byType(ProductImageCover), findsOneWidget);

      // Verify the blurred backdrop ImageFiltered widget is present
      final imageFilteredFinder = find.byType(ImageFiltered);
      expect(imageFilteredFinder, findsOneWidget);

      final imageFiltered = tester.widget<ImageFiltered>(imageFilteredFinder);
      expect(
        imageFiltered.imageFilter,
        isA<ImageFilter>(),
      );

      // Verify two CachedNetworkImage widgets exist: 1 backdrop (fit: cover) + 1 foreground (fit: contain)
      final cachedImages = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage)).toList();
      expect(cachedImages.length, 2);
      expect(cachedImages[0].fit, BoxFit.cover);
      expect(cachedImages[1].fit, BoxFit.contain);
    });

    testWidgets('renders fallback icon gracefully when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 160,
              child: ProductImageCover(
                imageUrl: null,
              ),
            ),
          ),
        ),
      );

      // Verify fallback icon is shown and no ImageFiltered backdrop is rendered
      expect(find.byType(ProductImageCover), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('integrates seamlessly into CompactProductCard without error', (tester) async {
      final product = Product(
        id: 'test-p1',
        name: 'Nutri-Vet Multi-Vitamins for Dogs',
        slug: 'nutri-vet-multi-vitamins',
        price: 499.0,
        mrp: 599.0,
        image: 'https://example.com/product.jpg',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 180,
                height: 280,
                child: CompactProductCard(
                  product: product,
                  variant: CompactCardVariant.catalogue,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageCover), findsOneWidget);
      expect(find.text('Nutri-Vet Multi-Vitamins for Dogs'), findsOneWidget);
    });

    testWidgets('integrates seamlessly into ProductCard without error', (tester) async {
      final product = Product(
        id: 'test-p2',
        name: 'Himalaya HimCal Calcium Supplement',
        slug: 'himalaya-himcal',
        price: 250.0,
        mrp: 300.0,
        image: 'https://example.com/himcal.jpg',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 320,
                child: ProductCard(
                  product: product,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageCover), findsOneWidget);
      expect(find.text('Himalaya HimCal Calcium Supplement'), findsOneWidget);
    });
  });
}
