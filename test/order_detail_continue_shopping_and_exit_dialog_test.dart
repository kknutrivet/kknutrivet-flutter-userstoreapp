import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nvit_app/features/home/screens/main_shell.dart';
import 'package:nvit_app/features/orders/screens/order_detail_screen.dart';
import 'package:nvit_app/features/orders/screens/orders_screen.dart';
import 'package:nvit_app/models/order.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  group('OrderDetailScreen & Exit Dialog Tests', () {
    testWidgets('OrderDetailScreen groups combo items into bundle card with member products and shows standalone products', (tester) async {
      final fakeOrder = Order(
        id: 'ord-combo',
        orderNumber: 'KK-COMBO-1',
        totalAmount: 2392,
        paymentStatus: 'PAID',
        paymentMethod: 'ONLINE',
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        items: [
          // Standalone product
          OrderItem(
            id: 'item-standalone-1',
            quantity: 1,
            price: 499,
            product: Product(
              id: 'p-kennel',
              name: 'Veterinary Kennel & Shed Sanitizing Concentrate',
              slug: 'kennel-shed-sanitizing-concentrate',
              price: 499,
              mrp: 650,
              size: '5 Litres',
            ),
          ),
          // Combo items belonging to Cattle Udder Care & Mastitis Combo
          OrderItem(
            id: 'item-combo-1',
            quantity: 1,
            price: 1893,
            comboId: 'combo-mastitis',
            comboName: 'Cattle Udder Care & Mastitis Combo',
            comboQuantity: 1,
            comboPrice: 1893,
            product: Product(
              id: 'p-udder-1',
              name: 'Mastitis Spray 500ml',
              slug: 'mastitis-spray',
              price: 800,
            ),
          ),
          OrderItem(
            id: 'item-combo-2',
            quantity: 2,
            price: 0,
            comboId: 'combo-mastitis',
            comboName: 'Cattle Udder Care & Mastitis Combo',
            comboQuantity: 1,
            comboPrice: 1893,
            product: Product(
              id: 'p-udder-2',
              name: 'Herbal Udder Ointment 200g',
              slug: 'herbal-udder-ointment',
              price: 400,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrderItemsCard(order: fakeOrder),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Items count in title is 2 (1 standalone + 1 combo bundle), not 3 independent products
      expect(find.text('Items (2)'), findsOneWidget);

      // Verify combo bundle card is rendered
      expect(find.byType(OrderComboBundleGroupCard), findsOneWidget);
      expect(find.text('Cattle Udder Care & Mastitis Combo'), findsOneWidget);
      expect(find.text('CARE BUNDLE · 2 ITEMS'), findsOneWidget);

      // Verify member items of the combo bundle are listed inside
      expect(find.text('Mastitis Spray 500ml'), findsOneWidget);
      expect(find.text('Herbal Udder Ointment 200g'), findsOneWidget);

      // Verify standalone item row is rendered for the standalone product
      expect(find.byType(OrderStandaloneItemRow), findsOneWidget);
      expect(find.text('Veterinary Kennel & Shed Sanitizing Concentrate'), findsOneWidget);
    });

    testWidgets('OrderHeroCard renders crisp white check icon for Confirmed status (never black glyph)', (tester) async {
      final fakeOrder = Order(
        id: 'ord-hero',
        orderNumber: 'KK-HERO-1',
        totalAmount: 1500,
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        items: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderHeroCard(order: fakeOrder),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkIconFinder = find.descendant(
        of: find.byType(OrderHeroCard),
        matching: find.byIcon(Icons.check_rounded),
      );
      expect(checkIconFinder, findsOneWidget);
      final checkIcon = tester.widget<Icon>(checkIconFinder);
      expect(checkIcon.color, Colors.white);
    });

    testWidgets('OrderDetailScreen pins Continue Shopping in bottomNavigationBar and navigates to /home', (tester) async {
      final fakeOrder = Order(
        id: 'ord-123',
        orderNumber: 'KK-12345',
        totalAmount: 1499,
        paymentStatus: 'PAID',
        paymentMethod: 'CASHFREE',
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        items: const [],
      );

      String? navigatedLocation;

      final router = GoRouter(
        initialLocation: '/order/ord-123',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home Page')),
          ),
          GoRoute(
            path: '/order/:id',
            builder: (_, state) => OrderDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      );

      router.routerDelegate.addListener(() {
        navigatedLocation = router.routerDelegate.currentConfiguration.uri.toString();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderDetailProvider('ord-123').overrideWith((ref) async => fakeOrder),
            orderTrackingProvider('ord-123').overrideWith((ref) async => <String, dynamic>{}),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the bottom bar has "Continue shopping"
      expect(find.text('Continue shopping'), findsOneWidget);
      expect(find.text('Chat on WhatsApp'), findsOneWidget);

      // Verify OrderSupportSection height is compact (< 120px) and does not take over the screen
      final supportSize = tester.getSize(find.byType(OrderSupportSection));
      expect(supportSize.height, lessThan(120),
          reason: 'Bottom support bar must be compact and not stretch vertically across screen');

      // Verify Scaffold bottomNavigationBar has OrderSupportSection
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNotNull);

      // Tap Continue Shopping
      await tester.tap(find.text('Continue shopping'));
      await tester.pumpAndSettle();

      expect(navigatedLocation, '/home');
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('OrderDetailScreen AppBar back button navigates to /orders (order list)', (tester) async {
      final fakeOrder = Order(
        id: 'ord-123',
        orderNumber: 'KK-12345',
        totalAmount: 1499,
        paymentStatus: 'PAID',
        paymentMethod: 'CASHFREE',
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        items: const [],
      );

      String? navigatedLocation;

      final router = GoRouter(
        initialLocation: '/order/ord-123',
        routes: [
          GoRoute(
            path: '/orders',
            builder: (context, state) => const Scaffold(body: Text('Orders List Page')),
          ),
          GoRoute(
            path: '/order/:id',
            builder: (_, state) => OrderDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      );

      router.routerDelegate.addListener(() {
        navigatedLocation = router.routerDelegate.currentConfiguration.uri.toString();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderDetailProvider('ord-123').overrideWith((ref) async => fakeOrder),
            orderTrackingProvider('ord-123').overrideWith((ref) async => <String, dynamic>{}),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap AppBar back button
      await tester.tap(find.byIcon(Icons.arrow_back), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(navigatedLocation, '/orders');
      expect(find.text('Orders List Page'), findsOneWidget);
    });

    testWidgets('MainShell permits platform back from Home without exit confirmation', (tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MainShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (context, state) => const Scaffold(body: Text('Home Content')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/products',
                    builder: (context, state) => const Scaffold(body: Text('Shop Content')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Content'), findsOneWidget);

      // Trigger back button PopScope while on Home
      final popScopeFinder = find.byWidgetPredicate(
        (w) => w is PopScope,
        description: 'PopScope widget',
      );
      final popScope = tester.widget<PopScope>(popScopeFinder.first);
      popScope.onPopInvokedWithResult!(false, null);
      await tester.pumpAndSettle();

      expect(popScope.canPop, isTrue);
      expect(find.text('Exit KK Nutrivet?'), findsNothing);
      expect(find.text('Home Content'), findsOneWidget);
    });

    testWidgets('OrdersScreen AppBar and PopScope back button navigates to /home when at root', (tester) async {
      String? navigatedLocation;

      final router = GoRouter(
        initialLocation: '/orders',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home Page')),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, state) => const OrdersScreen(),
          ),
        ],
      );

      router.routerDelegate.addListener(() {
        navigatedLocation = router.routerDelegate.currentConfiguration.uri.toString();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersProvider.overrideWith((ref) async => <Order>[]),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Orders'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Tap AppBar back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(navigatedLocation, '/home');
      expect(find.text('Home Page'), findsOneWidget);
    });
  });
}
