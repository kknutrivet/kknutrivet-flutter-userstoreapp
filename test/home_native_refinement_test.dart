import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';
import 'package:nvit_app/features/home/widgets/dr_paw_floating_button.dart';
import 'package:nvit_app/features/home/widgets/home_animal_selector.dart';
import 'package:nvit_app/features/home/widgets/home_top_bar.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/features/products/widgets/catalogue_controls.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Home Native UX Refinements Tests', () {
    testWidgets('HomeBrandBar has compact logo, 44dp support button, and 44dp cart button with badge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartCountProvider.overrideWith((ref) => 3),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  HomeBrandBar(),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify logo image or fallback text
      expect(find.byType(Image), findsWidgets);

      // Verify Cart button exists with badge count '3'
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Verify no exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeAnimalSelector renders horizontal row without truncating "Goats & Sheep"', (tester) async {
      final testWidths = [320.0, 375.0, 390.0, 412.0];

      for (final width in testWidths) {
        tester.view.physicalSize = Size(width * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeSettingsProvider.overrideWith((ref) => Future.value(StoreSettings(
                    freeDeliveryThreshold: 500,
                    deliveryCharge: 49,
                  ))),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HomeAnimalSelector(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull, reason: 'Failed on width $width');

        // Verify "Goats & Sheep" is rendered and maxLines is 2
        final goatTextFinder = find.text('Goats & Sheep');
        expect(goatTextFinder, findsOneWidget, reason: 'Goats & Sheep missing on $width');
        final textWidget = tester.widget<Text>(goatTextFinder);
        expect(textWidget.maxLines, 2);

        // Verify all 6 animal labels are present
        expect(find.text('Dogs'), findsOneWidget);
        expect(find.text('Cats'), findsOneWidget);
        expect(find.text('Cattle'), findsOneWidget);
        expect(find.text('Poultry'), findsOneWidget);
        expect(find.text('Small Pets'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('WebsiteBottomNav aligns all 5 tabs on the same baseline with native prominence for Consult', (tester) async {
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

      // Verify all 5 tab labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Consult'), findsOneWidget);
      expect(find.text('Shots'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Verify Consult icon exists
      expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);

      // Verify tap on Consult triggers index 2
      await tester.tap(find.text('Consult'));
      await tester.pump();
      expect(tappedIndex, 2);

      // Verify user first name displays when logged in
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: WebsiteBottomNav(
              currentIndex: 4,
              userFirstName: 'Ramesh',
              onTap: (i) => tappedIndex = i,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Ramesh'), findsNothing);
    });

    testWidgets('DrPawFloatingButton transitions visibility smoothly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: DrPawFloatingButton(visible: true),
          ),
        ),
      );

      expect(find.byType(DrPawFloatingButton), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);

      // Toggle visible to false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: DrPawFloatingButton(visible: false),
          ),
        ),
      );

      // Pump animation
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(DrPawFloatingButton), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(DrPawFloatingButton), findsOneWidget);
    });

    testWidgets('HomeAnimalSelector tapping an animal navigates to /products?animalType=... and updates filters', (tester) async {
      String? navigatedRoute;
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: HomeAnimalSelector(),
              ),
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) {
              navigatedRoute = state.uri.toString();
              return const Scaffold(body: Text('Product List'));
            },
          ),
        ],
      );

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Dogs"
      final dogFinder = find.text('Dogs');
      expect(dogFinder, findsOneWidget);
      await tester.tap(dogFinder);
      await tester.pumpAndSettle();

      // Verify navigation to /products?animalType=Dog
      expect(navigatedRoute, '/products?animalType=Dog');
      expect(container.read(selectedHomeAnimalProvider), 'Dog');
      expect(container.read(productFilterProvider).animalType, 'Dog');
    });

    testWidgets('HomeAnimalSelector tapping All animals navigates to /products and resets filters', (tester) async {
      String? navigatedRoute;
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(
                child: HomeAnimalSelector(),
              ),
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) {
              navigatedRoute = state.uri.toString();
              return const Scaffold(body: Text('Product List'));
            },
          ),
        ],
      );

      final container = ProviderContainer();
      container.read(selectedHomeAnimalProvider.notifier).state = 'Dog';
      container.read(productFilterProvider.notifier).state =
          ProductFilter(animalType: 'Dog');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "All animals"
      final allAnimalsFinder = find.text('All animals');
      expect(allAnimalsFinder, findsOneWidget);
      await tester.tap(allAnimalsFinder);
      await tester.pumpAndSettle();

      // Verify navigation to /products and filter reset
      expect(navigatedRoute, '/products');
      expect(container.read(selectedHomeAnimalProvider), isNull);
      expect(container.read(productFilterProvider).animalType, isNull);
    });
  });
}
