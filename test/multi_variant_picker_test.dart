import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/theme/app_theme.dart';
import 'package:nvit_app/core/widgets/product_card.dart';
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
  Future<dynamic> upload(String path, String filePath,
      {String fileField = 'file', Map<String, dynamic>? fields}) async =>
      {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final multiVariantProduct = Product(
    id: 'prod-multi-1',
    name: 'GranLiv - Livestock Liver Tonic',
    slug: 'granliv-livestock',
    price: 320.0,
    mrp: 380.0,
    variants: [
      ProductVariant(id: 'v-1l', name: '1 L', price: 580.0, mrp: 650.0, stock: 10),
      ProductVariant(id: 'v-500ml', name: '500 mL', price: 320.0, mrp: 380.0, stock: 15),
      ProductVariant(id: 'v-200ml', name: '200 mL', price: 160.0, mrp: 190.0, stock: 8),
    ],
  );

  group('Multi-Variant Product Options Dialog Tests', () {
    testWidgets('tapping ADD on multi-variant CompactProductCard opens variant picker dialog with other options', (tester) async {
      tester.view.physicalSize = const Size(800 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 180,
                  height: 400,
                  child: CompactProductCard(
                    product: multiVariantProduct,
                    variant: CompactCardVariant.catalogue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify ADD button is rendered
      expect(find.text('ADD'), findsOneWidget);
      // Verify dropdown arrow icon is rendered indicating multiple options
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap ADD button
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();

      // Verify the VariantPickerSheet dialog opened
      expect(find.byType(VariantPickerSheet), findsOneWidget);
      expect(find.text('CHOOSE PACK SIZE'), findsOneWidget);
      expect(find.text('3 options'), findsOneWidget);

      // Verify all options are visible in the dialog
      expect(find.text('1 L'), findsWidgets);
      expect(find.text('500 mL'), findsOneWidget);
      expect(find.text('200 mL'), findsOneWidget);

      // Tap the "200 mL" option to select it
      await tester.tap(find.text('200 mL'));
      await tester.pumpAndSettle();

      // Tap "Add to Cart" in the dialog footer
      expect(find.text('Add to Cart'), findsOneWidget);
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      // The dialog should close and the card should update with the selected option in cart
      expect(find.byType(VariantPickerSheet), findsNothing);
      expect(find.text('1'), findsOneWidget); // 1 in cart
    });

    testWidgets('tapping ADD on multi-variant ProductCard also opens variant options dialog', (tester) async {
      tester.view.physicalSize = const Size(800 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 340,
                  child: ProductCard(
                    product: multiVariantProduct,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ADD'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap ADD button on standard ProductCard
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();

      // Verify the VariantPickerSheet dialog opens
      expect(find.byType(VariantPickerSheet), findsOneWidget);
      expect(find.text('1 L'), findsWidgets);
      expect(find.text('500 mL'), findsOneWidget);
      expect(find.text('200 mL'), findsOneWidget);
    });

    testWidgets('tapping pack size label on CompactProductCard opens variant picker dialog', (tester) async {
      tester.view.physicalSize = const Size(800 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 180,
                  height: 400,
                  child: CompactProductCard(
                    product: multiVariantProduct,
                    variant: CompactCardVariant.catalogue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the pack label text is present
      final packFinder = find.text('Pack: 1 L · 3 sizes ▾');
      expect(packFinder, findsOneWidget);

      // Tap directly on the pack label
      await tester.tap(packFinder);
      await tester.pumpAndSettle();

      // Verify the sheet opened
      expect(find.byType(VariantPickerSheet), findsOneWidget);
      expect(find.text('CHOOSE PACK SIZE'), findsOneWidget);

      // Pick another variant (500 mL)
      await tester.tap(find.text('500 mL'));
      await tester.pumpAndSettle();

      // Tap close button on sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.byType(VariantPickerSheet), findsNothing);
    });

    testWidgets('tapping pack badge on ProductCard opens variant picker dialog', (tester) async {
      tester.view.physicalSize = const Size(800 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 340,
                  child: ProductCard(
                    product: multiVariantProduct,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final badgeFinder = find.text('1 L · 3 packs ▾');
      expect(badgeFinder, findsOneWidget);

      // Tap directly on the pack badge
      await tester.tap(badgeFinder);
      await tester.pumpAndSettle();

      // Verify sheet opened
      expect(find.byType(VariantPickerSheet), findsOneWidget);
      expect(find.text('CHOOSE PACK SIZE'), findsOneWidget);
    });
  });
}
