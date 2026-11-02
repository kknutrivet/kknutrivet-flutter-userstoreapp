import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/widgets/compact_product_card.dart';
import 'package:nvit_app/features/health/screens/disease_detail_screen.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';
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

  final testConcern = HealthConcern(
    id: 'hc-1',
    name: 'Ticks & Fleas',
    slug: 'tick-flea-infestations',
    description: 'Protection and remedies for ticks and fleas.',
  );

  final testProduct = Product(
    id: 'p-1',
    name: 'Fiprofort Plus Spot On Dog',
    slug: 'fiprofort-plus',
    price: 450.0,
    mrp: 520.0,
    animalTypes: ['Dog'],
    stock: 10,
  );

  group('DiseaseDetailScreen Tests', () {
    testWidgets('renders CompactProductCard with ADD button on disease page list', (tester) async {
      tester.view.physicalSize = const Size(800 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(_FakeApiClient()),
            concernByNameProvider('tick-flea-infestations').overrideWith((ref) => Future.value(testConcern)),
            diseaseProductsProvider('Ticks & Fleas').overrideWith((ref) => Future.value([testProduct])),
          ],
          child: const MaterialApp(
            home: DiseaseDetailScreen(slug: 'tick-flea-infestations'),
          ),
        ),
      );

      // Settle async providers
      await tester.pumpAndSettle();

      // Check disease header and product title
      expect(find.text('Ticks & Fleas'), findsWidgets);
      expect(find.text('Fiprofort Plus Spot On Dog'), findsOneWidget);

      // Check that CompactProductCard is rendered in the list
      expect(find.byType(CompactProductCard), findsOneWidget);

      // Check that the Add button with text 'ADD' is present
      expect(find.text('ADD'), findsOneWidget);

      // Tap ADD button
      await tester.tap(find.text('ADD'));
      await tester.pumpAndSettle();

      // After adding, the quantity stepper in CompactProductCard should show 1
      expect(
        find.descendant(
          of: find.byType(CompactProductCard),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      // Cart badge in AppBar should also show 1
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      // Floating cart bar should also be visible
      expect(find.byType(CartFloatingBar), findsOneWidget);
    });
  });
}
