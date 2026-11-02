import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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
      content: 'Here is dosage guidance for ${currentProduct?.name ?? "your pet"}. Give 5ml daily with meals.',
      suggestedQuestions: ['What are the side effects?', 'Can I give with food?'],
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
    id: 'prod-101',
    name: 'Pet Kal Forte Calcium Syrup',
    slug: 'pet-kal-forte',
    price: 350.0,
    mrp: 420.0,
    brand: 'Vivaldis',
    category: 'Supplements',
    animalTypes: ['Dog', 'Cat'],
    description: 'High absorption calcium and phosphorus supplement for dogs and cats.',
  );

  group('Dr. Paw PDP Pet Companion Bottom Sheet Tests', () {
    testWidgets('renders DrPawCompanionSheet with product context and prompt chips when opened without initial question', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockAiService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DrPawCompanionSheet(product: sampleProduct),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Header
      expect(find.text('Dr. Paw'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Pet Kal Forte Calcium Syrup'), findsOneWidget);

      // Verify the 4 quick prompt chips
      expect(find.text('💬 How to use Pet Kal Forte Calcium Syrup?'), findsOneWidget);
      expect(find.text('💬 Is this safe for Dog?'), findsOneWidget);
      expect(find.text('💬 Active ingredients & clinical benefits'), findsOneWidget);
      expect(find.text('💬 Are there equivalent alternatives?'), findsOneWidget);

      // Verify input bar placeholder
      expect(find.text('Ask anything about Pet Kal Forte Calcium Syrup...'), findsOneWidget);
    });

    testWidgets('renders DrPawCompanionSheet with initial user question when passed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockAiService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DrPawCompanionSheet(
                product: sampleProduct,
                initialQuestion: 'How to use Pet Kal Forte Calcium Syrup?',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The question should be prefilled as a user message
      expect(find.text('How to use Pet Kal Forte Calcium Syrup?'), findsOneWidget);
      expect(find.text('Pet Kal Forte Calcium Syrup'), findsOneWidget);

      // Reply from MockAiService should arrive
      await tester.pumpAndSettle();
      expect(find.textContaining('Give 5ml daily with meals', findRichText: true), findsOneWidget);
      expect(find.text('What are the side effects?'), findsOneWidget);
    });

    testWidgets('showDrPawCompanionSheet opens modal bottom sheet and closes cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(MockAiService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDrPawCompanionSheet(
                    context,
                    product: sampleProduct,
                    initialQuestion: 'Is this safe for Dog?',
                  ),
                  child: const Text('Open Dr Paw'),
                ),
              ),
            ),
          ),
        ),
      );

      // Initially sheet is not open
      expect(find.byType(DrPawCompanionSheet), findsNothing);

      // Tap button to open sheet
      await tester.tap(find.text('Open Dr Paw'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Sheet is open with product context
      expect(find.byType(DrPawCompanionSheet), findsOneWidget);
      expect(find.text('Is this safe for Dog?'), findsOneWidget);

      // Close the sheet by tapping close icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.byType(DrPawCompanionSheet), findsNothing);
    });
  });
}
