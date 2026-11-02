import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/router/app_router.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/features/combos/screens/combo_detail_screen.dart';
import 'package:nvit_app/features/products/widgets/catalogue_controls.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleCombo = ComboBundle(
    id: 'combo-liv-deworm',
    name: 'Cattle Deworming & Liver Support Duo',
    description: 'Everyday care essentials for your cattle.',
    originalPrice: 1810,
    comboPrice: 1449,
    isActive: true,
    items: const [],
  );

  final sampleMultiVariantProduct = Product(
    id: 'prod-test-overflow',
    name: 'Long Product Name That Wraps to Two Full Lines in Small Cards',
    slug: 'long-product-name',
    price: 349.0,
    mrp: 399.0,
    variants: [
      ProductVariant(
        id: 'var-1',
        name: '500 ml',
        price: 349.0,
        mrp: 399.0,
        stock: 12,
      ),
      ProductVariant(
        id: 'var-2',
        name: '1 Litre',
        price: 649.0,
        mrp: 750.0,
        stock: 5,
      ),
    ],
  );

  group('Combo Unauthenticated Route Tests', () {
    testWidgets('guest user opening /combos/:id lands on ComboDetailScreen without /login redirect',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          homeCombosProvider.overrideWith((ref) => Future.value([sampleCombo])),
          comboDetailProvider(sampleCombo.id)
              .overrideWith((ref) => Future.value(sampleCombo)),
          comboCartQuantityProvider(sampleCombo.id).overrideWithValue(0),
          cartCountProvider.overrideWithValue(0),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Splash settling
      await tester.pump(const Duration(milliseconds: 800));

      // Navigate to combo details
      router.go('/combos/${sampleCombo.id}');
      await tester.pumpAndSettle();

      // Verify route is /combos/:id and not /login
      expect(router.state.matchedLocation, '/combos/combo-liv-deworm');
      expect(find.byType(ComboDetailScreen), findsOneWidget);
    });

    testWidgets('/combos route redirects to /products?category=Combos',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeCombosProvider.overrideWith((ref) => Future.value([sampleCombo])),
          productsListProvider.overrideWith((ref) => Future.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 800));

      router.go('/combos');
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/products');
      expect(router.state.uri.queryParameters['category'], 'Combos');
    });
  });

  group('CompactProductCard Overflow Tests', () {
    testWidgets('renders on tight constraints without 0.634px RenderFlex overflow',
        (tester) async {
      // Simulate exact narrow tile constraints where the 0.634px overflow was thrown
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 150,
                  height: 223.88, // 150 / 0.67
                  child: CompactProductCard(
                    product: sampleMultiVariantProduct,
                    variant: CompactCardVariant.homeGrid,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no exception was caught by the tester
      expect(tester.takeException(), isNull);
      expect(find.byType(CompactProductCard), findsOneWidget);
      expect(find.text('Pack: 500 ml · 2 sizes ▾'), findsOneWidget);
      expect(find.text('₹349'), findsOneWidget);
    });

    testWidgets(
        'renders catalogue card with 2-line title and pack size without 2.2px overflow on tight PDP related tile',
        (tester) async {
      final fishwizProduct = Product(
        id: 'fishwiz-bsf',
        name: 'Fishwiz BSF Larva Mini (35g × 2 Packs | 70g Total)',
        slug: 'fishwiz-bsf-larva-mini',
        price: 338.0,
        mrp: 440.0,
        stock: 10,
        size: '35 g x 2 packets (70 g Total)',
        variants: const [],
      );

      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 152,
                  height: 220, // narrow tile constraint where 2.2px overflow occurred
                  child: CompactProductCard(
                    product: fishwizProduct,
                    variant: CompactCardVariant.catalogue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompactProductCard), findsOneWidget);
      expect(find.text('Fishwiz BSF Larva Mini (35g × 2 Packs | 70g Total)'),
          findsOneWidget);
      expect(find.text('35 g x 2 packets (70 g Total)'), findsOneWidget);
      expect(find.text('₹338'), findsOneWidget);
      expect(find.text('₹440'), findsOneWidget);
      expect(find.text('ADD'), findsOneWidget);
    });
  });
}
