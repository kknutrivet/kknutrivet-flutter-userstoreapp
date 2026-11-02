import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/products/widgets/product_description_renderer.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  group('Product Description Section Parsing & Web Parity', () {
    test('splits markdown headings and aliases into structured sections', () {
      const description = '''
## Product Details
Premium nutritional supplement for dogs and cats. Formulated with essential vitamins.

## Key Features
• Boosts immune system naturally
• Promotes healthy skin and shiny coat
• Highly palatable easy to feed syrup

## Composition
Each 10 ml contains:
Vitamin A 5000 IU
Vitamin D3 400 IU
Zinc 15 mg

## Dosage
Administer 5ml per 10kg body weight once daily.
''';

      final product = Product(
        id: 'p-1',
        name: 'NutriPet Syrup',
        slug: 'nutripet-syrup',
        brand: 'NutriVet',
        category: 'Supplements',
        price: 450,
        mrp: 500,
        description: description,
        stock: 10,
      );

      final sections = buildProductDetailSections(product);

      // Verify sections are cleanly partitioned
      final titles = sections.map((s) => s.title).toList();
      expect(titles, contains('Product Details'));
      expect(titles, contains('Key Features'));
      expect(titles, contains('Composition & Active Ingredients'));
      expect(titles, contains('Directions & Dosage'));

      // Check that the body content does not have raw ## headers
      final detailsSection =
          sections.firstWhere((s) => s.id == 'product-details');
      expect(detailsSection.content, isNot(contains('## Product Details')));
      expect(detailsSection.content, isNot(contains('## Key Features')));
      expect(detailsSection.content,
          contains('Premium nutritional supplement for dogs and cats.'));

      final featuresSection =
          sections.firstWhere((s) => s.id == 'key-features');
      expect(featuresSection.content, isNot(contains('## Key Features')));
      expect(featuresSection.content,
          contains('• Boosts immune system naturally'));
    });

    test('deduplicates and prioritizes authoritative product composition field',
        () {
      const description = '''
## Product Details
Overview text.

## Composition
Old composition from description.
''';

      final product = Product(
        id: 'p-2',
        name: 'NutriPet Syrup',
        slug: 'nutripet-syrup-2',
        brand: 'NutriVet',
        category: 'Supplements',
        price: 450,
        mrp: 500,
        description: description,
        composition: 'Pure elemental iron 100mg, Folic acid 1.5mg',
        stock: 10,
      );

      final sections = buildProductDetailSections(product);
      final compSection = sections.firstWhere((s) => s.id == 'composition');
      expect(compSection.content,
          equals('Pure elemental iron 100mg, Folic acid 1.5mg'));
    });
  });

  group('ProductDescriptionRenderer Widget Tests', () {
    testWidgets('renders bullet points with checkmark icons and clean text',
        (tester) async {
      const markdown = '''
• Boosts immune system naturally
• Promotes healthy skin and shiny coat
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductDescriptionRenderer(text: markdown),
          ),
        ),
      );

      // Should find checkmark icons for bullets
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.textContaining('Boosts immune system naturally'), findsOneWidget);
      expect(find.textContaining('Promotes healthy skin and shiny coat'),
          findsOneWidget);
      // Raw bullet symbols should not be in the output text
      expect(find.textContaining('• Boosts'), findsNothing);
    });

    testWidgets('renders composition check list when isComposition is true',
        (tester) async {
      const compositionText = '''
Vitamin A 5000 IU
Vitamin D3 400 IU
Zinc 15 mg
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductDescriptionRenderer(
              text: compositionText,
              isComposition: true,
            ),
          ),
        ),
      );

      // Each ingredient row has a check icon
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
      expect(find.textContaining('Vitamin A 5000 IU'), findsOneWidget);
    });

    testWidgets('renders inline bold text styling with parseInlineSpans',
        (tester) async {
      const text = 'Contains **essential** nutrients for **rapid recovery**.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductDescriptionRenderer(text: text),
          ),
        ),
      );

      // Raw asterisks should be stripped from display
      expect(find.textContaining('**essential**'), findsNothing);
      expect(find.textContaining('Contains essential nutrients for rapid recovery.'),
          findsOneWidget);
    });
  });
}
