import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/features/health/screens/disease_detail_screen.dart';
import 'package:nvit_app/features/products/screens/product_detail_screen.dart';
import 'package:nvit_app/features/products/screens/product_list_screen.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';

class _FakeApiClient implements ApiClient {
  @override
  void updateBaseUrl(String newBaseUrl) {}

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async => [];

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async => {};

  @override
  Future<dynamic> upload(
    String path,
    String filePath, {
    String fileField = 'file',
    Map<String, dynamic>? fields,
  }) async =>
      {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleProduct = Product(
    id: 'prod-gap-1',
    name: 'Bravecto Chewable Tablet for Dogs',
    slug: 'bravecto-chewable',
    price: 1850.0,
    mrp: 2100.0,
    brand: 'MSD Animal Health',
    category: 'Flea & Tick',
    animalTypes: ['Dog'],
    description: 'Extended 12-week flea and tick protection chew for dogs.',
  );

  final relatedProduct = Product(
    id: 'prod-gap-2',
    name: 'Simparica Trio Chewable',
    slug: 'simparica-trio',
    price: 1450.0,
    mrp: 1600.0,
    category: 'Flea & Tick',
    animalTypes: ['Dog'],
  );

  final testConcern = HealthConcern(
    id: 'hc-gap-1',
    name: 'Ticks & Fleas',
    slug: 'tick-flea-infestations',
    description: 'Protection and remedies for ticks and fleas.',
  );

  group('Grid Sections Spacing and Gap Tests', () {
    testWidgets(
        'PDP similar section (You may also need) gap to product grid is compact on notch devices',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const notchMediaQuery = MediaQueryData(
        size: Size(390, 1200),
        padding: EdgeInsets.only(top: 44, bottom: 34),
        devicePixelRatio: 3.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProvider(sampleProduct.id)
                .overrideWith((ref) => sampleProduct),
            relatedProductsProvider(sampleProduct.id)
                .overrideWith((ref) => [relatedProduct]),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: notchMediaQuery,
              child: Scaffold(
                body: ProductDetailScreen(id: sampleProduct.id),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final headingFinder = find.text('You may also need');
      await tester.scrollUntilVisible(
        headingFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(headingFinder, findsOneWidget);

      final relatedCardFinder = find.widgetWithText(
        CompactProductCard,
        'Simparica Trio Chewable',
      );
      expect(relatedCardFinder, findsOneWidget);

      final headingBottom = tester.getBottomLeft(headingFinder).dy;
      final relatedCardTop = tester.getTopLeft(relatedCardFinder).dy;

      final gap = relatedCardTop - headingBottom;
      // Gap should be compact (< 30px) and not inflated by 44px notch status-bar padding
      expect(gap, lessThan(30.0));
      expect(gap, greaterThan(0.0));
    });

    testWidgets(
        'Product list screen gap from product count heading to grid is compact',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productsListProvider
                .overrideWith((ref) => [sampleProduct, relatedProduct]),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProductListScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final headingFinder = find.text('2 products');
      expect(headingFinder, findsOneWidget);

      final firstCardFinder = find.byType(CompactProductCard).first;
      expect(firstCardFinder, findsOneWidget);

      final headingBottom = tester.getBottomLeft(headingFinder).dy;
      final cardTop = tester.getTopLeft(firstCardFinder).dy;

      final gap = cardTop - headingBottom;
      // Gap should be compact (< 20px)
      expect(gap, lessThan(20.0));
      expect(gap, greaterThan(0.0));
    });

    testWidgets(
        'Disease detail screen gap from filter chips to product grid is compact',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient()),
            concernByNameProvider(testConcern.slug)
                .overrideWith((ref) => Future.value(testConcern)),
            diseaseProductsProvider(testConcern.name)
                .overrideWith((ref) => Future.value([sampleProduct, relatedProduct])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DiseaseDetailScreen(slug: testConcern.slug),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final chipFinder = find.widgetWithText(ChoiceChip, 'All (2)');
      expect(chipFinder, findsOneWidget);

      final firstCardFinder = find.byType(CompactProductCard).first;
      expect(firstCardFinder, findsOneWidget);

      final chipBottom = tester.getBottomLeft(chipFinder).dy;
      final cardTop = tester.getTopLeft(firstCardFinder).dy;

      final gap = cardTop - chipBottom;
      // Gap should be compact (< 25px)
      expect(gap, lessThan(25.0));
      expect(gap, greaterThan(0.0));
    });
  });
}
