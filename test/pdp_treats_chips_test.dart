import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/features/products/screens/product_detail_screen.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/providers/catalog_service.dart';

class MockCatalogService extends CatalogService {
  MockCatalogService() : super(ApiClient.withDio(Dio()));

  @override
  Future<Product> fetchProduct(String idOrSlug) async {
    return Product(
      id: 'prod-electrolytes',
      name: 'Electral Pet Energy & Hydration Powder',
      slug: 'electral-pet-powder',
      price: 180.0,
      mrp: 220.0,
      stock: 25,
      category: 'Healthcare',
      diseases: const ['vitamin-deficiency', 'dehydration'],
    );
  }

  @override
  Future<List<Product>> fetchProducts({
    String? category,
    String? subCategory,
    String? animalType,
    String? disease,
    String? search,
    String? sort,
    int? limit,
    String? relatedTo,
    bool forceRefresh = false,
  }) async =>
      const [];

  @override
  Future<List<HealthConcern>> fetchHealthConcerns() async {
    return [
      HealthConcern(
        id: 'hc-1',
        name: 'Vitamin & Mineral Deficiencies',
        slug: 'vitamin-deficiency',
        description: 'Vitamins and essentials',
      ),
      HealthConcern(
        id: 'hc-2',
        name: 'Dehydration',
        slug: 'dehydration',
        description: 'Fluid balance and electrolytes',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleProduct = Product(
    id: 'prod-electrolytes',
    name: 'Electral Pet Energy & Hydration Powder',
    slug: 'electral-pet-powder',
    price: 180.0,
    mrp: 220.0,
    stock: 25,
    category: 'Healthcare',
    diseases: const ['vitamin-deficiency', 'dehydration'],
  );

  testWidgets(
      'PDP HELPS WITH section renders inline chips in a Wrap with natural intrinsic width',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1400 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogServiceProvider.overrideWithValue(MockCatalogService()),
          productDetailProvider(sampleProduct.id)
              .overrideWith((ref) => sampleProduct),
          relatedProductsProvider(sampleProduct.id)
              .overrideWith((ref) => const []),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProductDetailScreen(id: sampleProduct.id),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final helpsWithFinder = find.text('HELPS WITH');
    await tester.scrollUntilVisible(
      helpsWithFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(helpsWithFinder, findsOneWidget);

    // Verify chips render with text and arrow
    expect(find.text('Vitamin & Mineral Deficiencies'), findsOneWidget);
    expect(find.text('Dehydration'), findsOneWidget);
    expect(find.text('↗'), findsNWidgets(2));

    // Verify chips are placed inside a Wrap widget
    final wrapFinder = find.ancestor(
      of: find.text('Dehydration'),
      matching: find.byType(Wrap),
    );
    expect(wrapFinder, findsOneWidget);

    // Verify Dehydration chip is NOT stretched full-width (less than 200px width, while card is > 350px)
    final dehydrationCard = find.ancestor(
      of: find.text('Dehydration'),
      matching: find.byType(Ink),
    );
    expect(dehydrationCard, findsOneWidget);

    final chipWidth = tester.getSize(dehydrationCard).width;
    expect(chipWidth, lessThan(200.0),
        reason: 'Chip should wrap intrinsically, not stretch across full card');
  });
}
