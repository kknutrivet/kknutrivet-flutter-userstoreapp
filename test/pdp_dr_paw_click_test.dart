import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/products/screens/product_detail_screen.dart';
import 'package:nvit_app/features/vet/widgets/dr_paw_companion_sheet.dart';
import 'package:nvit_app/models/chat.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/ai_service.dart';
import 'package:nvit_app/providers/app_providers.dart';

class MockAiService implements AiService {
  @override
  Future<ChatMessage> ask({
    required String question,
    String? animalType,
    String? language,
    String? petProfileId,
    Product? currentProduct,
    List<Map<String, dynamic>>? history,
  }) async {
    return ChatMessage(
      role: 'assistant',
      content: 'Dosage guidance for ${currentProduct?.name ?? "your pet"}: 5ml twice daily.',
      suggestedQuestions: ['Can I mix with food?'],
    );
  }

  @override
  Future<List<Product>> findAlternativesByText(String query) async => [];

  @override
  Future<List<Product>> findAlternativesByImage(String imageUrl) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleProduct = Product(
    id: 'prod-200',
    name: 'Bravecto Chewable Tablet for Dogs',
    slug: 'bravecto-chewable',
    price: 1850.0,
    mrp: 2100.0,
    brand: 'MSD Animal Health',
    category: 'Flea & Tick',
    animalTypes: ['Dog'],
    description: 'Extended 12-week flea and tick protection chew for dogs.',
  );

  group('Product Detail Screen Dr. Paw Click Tests', () {
    testWidgets('tapping prompt chip on PDP opens Dr. Paw sheet and pre-sends question with product context', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockAiService()),
            productDetailProvider(sampleProduct.id).overrideWith((ref) => sampleProduct),
            relatedProductsProvider(sampleProduct.id).overrideWith((ref) => []),
          ],
          child: MaterialApp(
            home: ProductDetailScreen(id: sampleProduct.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll the companion card into the center of the viewport
      final promptFinder = find.text('💬 How to use Bravecto Chewable Tablet for Dogs?');
      await tester.scrollUntilVisible(
        promptFinder,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      // Bring it nicely into the middle of the screen
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 120));
      await tester.pumpAndSettle();
      expect(promptFinder, findsOneWidget);

      // Tap the prompt chip
      await tester.tap(promptFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Dr. Paw sheet should be displayed with product context and answer
      expect(find.byType(DrPawCompanionSheet), findsOneWidget);
      expect(find.text('Bravecto Chewable Tablet for Dogs'), findsWidgets);
      expect(find.textContaining('Dosage guidance for Bravecto Chewable Tablet for Dogs', findRichText: true), findsOneWidget);

      // Close the companion sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // User remains on the PDP
      expect(find.byType(DrPawCompanionSheet), findsNothing);
      expect(find.text('Bravecto Chewable Tablet for Dogs'), findsWidgets);
    });

    testWidgets('tapping top AI CHAT pill on PDP opens Dr. Paw companion sheet', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockAiService()),
            productDetailProvider(sampleProduct.id).overrideWith((ref) => sampleProduct),
            relatedProductsProvider(sampleProduct.id).overrideWith((ref) => []),
          ],
          child: MaterialApp(
            home: ProductDetailScreen(id: sampleProduct.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final topPillFinder = find.text('Ask Dr Paw about this product');
      await tester.scrollUntilVisible(
        topPillFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(topPillFinder, findsOneWidget);

      await tester.tap(topPillFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(DrPawCompanionSheet), findsOneWidget);
    });
  });
}
