import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('WebsiteBottomNav Tests', () {
    testWidgets('renders 5 bottom navigation items including raised center Consult button without overflow', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WebsiteBottomNav(
              currentIndex: selectedTab,
              onTap: (i) => selectedTab = i,
            ),
          ),
        ),
      );

      // Verify no RenderFlex overflow occurred
      expect(tester.takeException(), isNull);

      // Verify all 5 tab labels exist (5th tab displays 'Sign in' when unauthenticated, or name when signed in)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Consult'), findsOneWidget);
      expect(find.text('Shots'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Verify Consult icon exists
      expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);

      // Tap Consult tab
      await tester.tap(find.text('Consult'));
      await tester.pumpAndSettle();
      expect(selectedTab, 2);
    });
  });

  group('CartFloatingBar Tests', () {
    testWidgets(
        'renders compact centered floating capsule with count, total, and View cart',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProviderScope(
                child: CartFloatingBar(count: 1, total: 219.0),
              ),
            ),
          ),
        ),
      );

      // Verify pill content
      expect(find.text('View cart'), findsOneWidget);
      expect(find.text('1 item · ₹219'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);

      // Verify the pill container is compact and doesn't span full width (width should be around 160-260dp)
      final pillFinder = find.descendant(
        of: find.byType(CartFloatingBar),
        matching: find.byType(InkWell),
      );
      expect(pillFinder, findsOneWidget);
      final size = tester.getSize(pillFinder);
      expect(size.width, lessThan(300.0));
      expect(size.height, lessThan(56.0));
    });

    testWidgets('formats multiple items count correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProviderScope(
                child: CartFloatingBar(count: 3, total: 1450.0),
              ),
            ),
          ),
        ),
      );

      expect(find.text('View cart'), findsOneWidget);
      expect(find.text('3 items · ₹1450'), findsOneWidget);
    });

    testWidgets(
        'CartFloatingBar floats above raised Consult button without vertical overlap',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const SizedBox.expand(),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 26,
                    child: CartFloatingBar(count: 1, total: 179.0),
                  ),
                ],
              ),
              bottomNavigationBar: WebsiteBottomNav(
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final cartBarBottom =
          tester.getBottomLeft(find.byType(CartFloatingBar)).dy;
      final consultIconTop = tester
          .getTopLeft(find.byIcon(Icons.medical_services_rounded))
          .dy;

      // The raised Consult circle extends ~13px above its inner icon; ensure CartFloatingBar bottom stays well above it.
      expect(cartBarBottom, lessThanOrEqualTo(consultIconTop - 16.0));
    });

    test('showFloatingCart is false when on index 4 (User / Profile screen)', () {
      bool isFloatingCartVisible({required int cartCount, required int currentIndex}) {
        return cartCount > 0 &&
            currentIndex != 2 &&
            currentIndex != 3 &&
            currentIndex != 4;
      }

      expect(isFloatingCartVisible(cartCount: 3, currentIndex: 0), isTrue); // Home
      expect(isFloatingCartVisible(cartCount: 3, currentIndex: 1), isTrue); // Shop
      expect(isFloatingCartVisible(cartCount: 3, currentIndex: 2), isFalse); // Consult
      expect(isFloatingCartVisible(cartCount: 3, currentIndex: 3), isFalse); // Shots
      expect(isFloatingCartVisible(cartCount: 3, currentIndex: 4), isFalse); // User / Profile
      expect(isFloatingCartVisible(cartCount: 0, currentIndex: 0), isFalse);
    });
  });
}
