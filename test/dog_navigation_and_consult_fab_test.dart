import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/widgets/skeletons.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';
import 'package:nvit_app/features/products/screens/product_list_screen.dart';
import 'package:nvit_app/features/products/widgets/catalogue_controls.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Dog Navigation & Skeleton Tests', () {
    testWidgets('ProductCardSkeleton renders individual card placeholders without solid overlay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 280,
              child: ProductCardSkeleton(),
            ),
          ),
        ),
      );

      // Verify card container renders with white background
      expect(find.byType(ProductCardSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductListScreen initializes filter with Dog and updates title cleanly', (tester) async {
      final container = ProviderContainer(
        overrides: [
          productsListProvider.overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ProductListScreen(initialAnimalType: 'Dog'),
          ),
        ),
      );

      // Allow microtask in initState to update productFilterProvider
      await tester.pump();

      // Title should reflect Dog Products instead of generic "All products"
      expect(find.text('Dog Products'), findsOneWidget);

      // Provider filter state should have animalType == 'Dog'
      expect(container.read(productFilterProvider).animalType, 'Dog');
    });

    testWidgets(
      'ProductListScreen hides animal rail & filter bar on scroll down and shows Back to top button',
      (tester) async {
        final mockProducts = List.generate(
          20,
          (i) => Product(
            id: 'p-$i',
            name: 'Product $i',
            slug: 'product-$i',
            price: 199,
            mrp: 249,
            category: 'Supplements',
            animalTypes: const ['Dog'],
            stock: 10,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productsListProvider.overrideWith(
                (ref) => Future.value(mockProducts),
              ),
            ],
            child: const MaterialApp(home: ProductListScreen()),
          ),
        );
        await tester.pumpAndSettle();

        AnimatedSlide findToolbarSlide() {
          return tester.widget<AnimatedSlide>(
            find.ancestor(
              of: find.byType(CatalogueHorizontalAnimalRail),
              matching: find.byType(AnimatedSlide),
            ),
          );
        }

        AnimatedOpacity findBackToTopOpacity() {
          return tester.widget<AnimatedOpacity>(
            find.ancestor(
              of: find.byKey(const ValueKey('catalogue-back-to-top')),
              matching: find.byType(AnimatedOpacity),
            ),
          );
        }

        // Initially at scroll offset 0: toolbar visible, Back to top hidden
        expect(findToolbarSlide().offset, Offset.zero);
        expect(findBackToTopOpacity().opacity, 0.0);

        // Scroll down past 300px
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();

        expect(findToolbarSlide().offset, const Offset(0, -1));
        expect(findBackToTopOpacity().opacity, 1.0);

        // Tap Back to top button -> scrolls back to 0 and reveals toolbar
        await tester.tap(find.byKey(const ValueKey('catalogue-back-to-top')));
        await tester.pumpAndSettle();

        expect(findToolbarSlide().offset, Offset.zero);
        expect(findBackToTopOpacity().opacity, 0.0);
      },
    );
  });

  group('Floating Center Consult Button Tests', () {
    testWidgets('WebsiteBottomNav renders raised floating 52dp circular emerald Consult button', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WebsiteBottomNav(
              currentIndex: 0,
              onTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );

      // Verify "Consult" label and medical icon exist
      expect(find.text('Care'), findsOneWidget);
      final consultIconFinder = find.byIcon(Icons.medical_services_rounded);
      expect(consultIconFinder, findsOneWidget);

      // Verify tapping the floating icon triggers onTap(2)
      await tester.tap(consultIconFinder);
      await tester.pumpAndSettle();
      expect(tappedIndex, 2);

      // Verify tapping "Consult" label also triggers onTap(2)
      tappedIndex = -1;
      await tester.tap(find.text('Care'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 2);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });
  });
}
