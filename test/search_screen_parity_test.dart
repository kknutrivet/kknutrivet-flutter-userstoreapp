import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nvit_app/core/network/api_client.dart';
import 'package:nvit_app/core/theme/app_theme.dart';
import 'package:nvit_app/features/search/screens/search_screen.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/providers/catalog_service.dart';

class _FakeSearchCatalogService extends CatalogService {
  _FakeSearchCatalogService(this.mockSuggestions) : super(ApiClient.instance);

  final List<SearchSuggestion> mockSuggestions;

  @override
  Future<List<SearchSuggestion>> fetchSuggestions(String query) async {
    return mockSuggestions;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
      'SearchScreen renders visible dark back arrow, webapp pre-search sections, and rich suggestion pricing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeSuggestions = [
      SearchSuggestion(
        id: 'prod-1',
        slug: 'optipet-liver-tonic',
        name: 'OptiPet Liver Tonic',
        brand: 'Petvet',
        category: 'Supplement & Nutrition',
        price: 179,
        mrp: 195,
      ),
      SearchSuggestion(
        id: 'combo-1',
        name: 'Dog Health & Care Combo',
        category: 'Combos',
        isCombo: true,
        price: 999,
        mrp: 1243,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogServiceProvider.overrideWithValue(
            _FakeSearchCatalogService(fakeSuggestions),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SearchScreen(),
        ),
      ),
    );
    await tester.pump();

    // 1. Back arrow is present and has dark foreground color (not white-on-white)
    final backIconFinder = find.byIcon(Icons.arrow_back_rounded);
    expect(backIconFinder, findsOneWidget);
    final backIcon = tester.widget<Icon>(backIconFinder);
    expect(backIcon.color, AppColors.textPrimary);

    // 2. Submit arrow is present inside solid emerald button
    expect(find.byIcon(Icons.arrow_forward_rounded), findsWidgets);

    // 3. Pre-search state matches webapp SearchClient.tsx
    expect(find.text('POPULAR SEARCHES'), findsOneWidget);
    expect(find.text('Tick & Flea'), findsOneWidget);
    expect(find.text('BROWSE BY ANIMAL'), findsOneWidget);
    expect(find.text('Upload Vet Prescription'), findsOneWidget);

    // 4. Typing >=2 chars triggers live suggestions with price, MRP, % OFF, and COMBO badge
    await tester.enterText(find.byType(TextField), 'op');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.pump();

    expect(find.text('SUGGESTED PRODUCTS (2)'), findsOneWidget);
    expect(find.text('OptiPet Liver Tonic'), findsOneWidget);
    expect(find.text('₹179'), findsOneWidget);
    expect(find.text('8% OFF'), findsOneWidget);
    expect(find.text('COMBO'), findsOneWidget);
    expect(find.text('View all results for "op"'), findsOneWidget);
  });
}
