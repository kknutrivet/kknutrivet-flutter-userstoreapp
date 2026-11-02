import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/core/router/app_router.dart';
import 'package:nvit_app/features/cart/screens/cart_screen.dart';
import 'package:nvit_app/features/checkout/screens/checkout_screen.dart';
import 'package:nvit_app/features/referral/screens/referral_screen.dart'
    show referralSummaryProvider;
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/models/referral.dart';
import 'package:nvit_app/models/store_settings.dart';
import 'package:nvit_app/models/user.dart';
import 'package:nvit_app/providers/app_providers.dart';

class MockCartNotifier extends CartNotifier {
  MockCartNotifier(this._items);
  final List<CartItem> _items;

  @override
  Future<List<CartItem>> build() async => _items;
}

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(this._user);
  final AppUser? _user;

  @override
  Future<AppUser?> build() async => _user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleProduct = Product(
    id: 'prod-cart-flow-1',
    name: 'GranLiv Tonic 500ml',
    slug: 'granliv-tonic-500ml',
    price: 450.0,
    mrp: 520.0,
    images: ['https://example.com/granliv.png'],
    stock: 10,
  );

  final sampleCartItem = CartItem(
    id: 'cart-item-1',
    productId: 'prod-cart-flow-1',
    quantity: 2,
    product: sampleProduct,
  );

  testWidgets(
      'CartScreen checkout button navigates directly to /checkout without redirecting to login',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        cartProvider.overrideWith(() => MockCartNotifier([sampleCartItem])),
        addressesProvider.overrideWith(
          (ref) => Future.value([]),
        ),
        homeCombosProvider.overrideWith(
          (ref) => Future.value([]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Initial launch past splash
    await tester.pump(const Duration(milliseconds: 800));

    // Navigate to /cart
    router.go('/cart');
    await tester.pumpAndSettle();

    // Verify cart screen elements
    expect(find.text('GranLiv Tonic 500ml'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);

    // Tap Checkout button
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    // Verify we arrived on /checkout page directly (NOT /login)
    expect(router.state.matchedLocation, '/checkout');
    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.textContaining('Order review'), findsOneWidget);
  });

  testWidgets(
      'CartScreen renders KK Coins redemption and Delivery Fee in Order Summary',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 1200 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final singleItem = CartItem(
      id: 'cart-item-single',
      productId: 'prod-cart-flow-1',
      quantity: 1, // Subtotal = 450 (< 500 threshold -> ₹49 delivery fee)
      product: sampleProduct,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartProvider.overrideWith(() => MockCartNotifier([singleItem])),
          authProvider.overrideWith(
            () => MockAuthNotifier(
              AppUser(
                id: 'u1',
                email: 'pet@kknutrivet.in',
                name: 'Pet Parent',
                loyaltyPoints: 200,
              ),
            ),
          ),
          referralSummaryProvider.overrideWith(
            (ref) => Future.value(
              ReferralSummary(referralCode: 'KK200', rewardsPoints: 200),
            ),
          ),
          storeSettingsProvider.overrideWith(
            (ref) => Future.value(
              StoreSettings(freeDeliveryThreshold: 500, deliveryCharge: 49),
            ),
          ),
          homeCombosProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll down to KK Coins & Order Summary
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    // Verify KK Coins redemption card is visible (200 available, max 30% of 450 = 135)
    expect(find.text('KK Coins · 200 available'), findsOneWidget);
    expect(find.text('Use max'), findsOneWidget);

    // Verify Delivery Fee is shown (₹49 since 450 < 500) and Total = 450 + 49 = ₹499
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('₹49'), findsOneWidget);
    expect(find.text('₹499'), findsWidgets);

    // Tap 'Use max' to redeem 135 KK Coins
    await tester.tap(find.text('Use max'));
    await tester.pumpAndSettle();

    // Verify 135 coins applied -> Merchandise = 315, Delivery = 49, Total = ₹364
    expect(find.text('135 Coins applied'), findsOneWidget);
    expect(find.text('KK Coins (135)'), findsOneWidget);
    expect(find.text('₹364'), findsWidgets);
  });
}
