import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/cart/widgets/cart_coupons_and_coins.dart';
import 'package:nvit_app/features/prescriptions/screens/prescriptions_screen.dart'
    show prescriptionsProvider;
import 'package:nvit_app/features/prescriptions/widgets/rx_checkout_gate.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/prescription.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final rxProduct = Product(
    id: 'prod-rx-banner',
    name: 'Rx Antibiotic 100ml',
    slug: 'rx-antibiotic-100ml',
    price: 300,
    stock: 10,
    requiresPrescription: true,
  );

  final rxItem = CartItem(
    id: 'cart-rx-banner',
    productId: 'prod-rx-banner',
    quantity: 1,
    product: rxProduct,
  );

  Prescription rx(String id, String status) => Prescription(
    id: id,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );

  Future<void> pumpBanner(
    WidgetTester tester, {
    required List<CartItem> items,
    required List<Prescription> prescriptions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prescriptionsProvider.overrideWith(
            (ref) => Future.value(prescriptions),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: CartRxBanner(items: items)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('cartRxStatus derives none / pending / approved', () {
    expect(cartRxStatus(const []), CartRxStatus.none);
    expect(cartRxStatus([rx('1', 'REJECTED')]), CartRxStatus.none);
    expect(cartRxStatus([rx('1', 'PENDING')]), CartRxStatus.pending);
    expect(
      cartRxStatus([rx('1', 'PENDING'), rx('2', 'APPROVED')]),
      CartRxStatus.approved,
    );
  });

  test('attachedPrescription prefers the latest ready prescription', () {
    expect(attachedPrescription(const []), isNull);
    expect(attachedPrescription([rx('1', 'REJECTED')]), isNull);
    expect(attachedPrescription([rx('1', 'PENDING')])?.id, '1');
    expect(
      attachedPrescription([rx('1', 'PENDING'), rx('2', 'APPROVED')])?.id,
      '1',
    );
  });

  testWidgets('required state prompts attach with a consult link', (
    tester,
  ) async {
    await pumpBanner(tester, items: [rxItem], prescriptions: const []);

    expect(find.text('PRESCRIPTION REQUIRED'), findsOneWidget);
    expect(
      find.text('Prescription required — attach now or check consultation'),
      findsOneWidget,
    );
    expect(find.text('Attach Rx'), findsOneWidget);
    expect(find.text('Consult Doctor'), findsOneWidget);
    expect(find.text('VERIFICATION PENDING'), findsNothing);
  });

  testWidgets('pending prescription shows verification state with view/replace', (
    tester,
  ) async {
    await pumpBanner(tester, items: [rxItem], prescriptions: [
      Prescription(
        id: 'rx-pending',
        imageUrl: 'https://example.com/rx.png',
        status: 'PENDING',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    expect(find.text('VERIFICATION PENDING'), findsOneWidget);
    expect(
      find.text('Prescription uploaded — pending verification'),
      findsOneWidget,
    );
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
    expect(find.text('PRESCRIPTION REQUIRED'), findsNothing);
  });

  testWidgets('pending prescription without images hides the view button', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      items: [rxItem],
      prescriptions: [
        Prescription(
          id: 'rx-pending-noimg',
          status: 'PENDING',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    expect(find.text('VERIFICATION PENDING'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'View'),
      findsNothing,
    );
  });

  testWidgets('approved prescription shows the verified state', (tester) async {
    await pumpBanner(tester, items: [rxItem], prescriptions: [rx('rx-approved', 'APPROVED')]);

    expect(find.text('PRESCRIPTION APPROVED'), findsOneWidget);
    expect(find.text('Prescription verified'), findsOneWidget);
    expect(find.text('Attach Rx'), findsNothing);
    expect(find.text('Replace'), findsNothing);
  });

  testWidgets('rejected-only prescription still prompts attach', (tester) async {
    await pumpBanner(tester, items: [rxItem], prescriptions: [rx('rx-rejected', 'REJECTED')]);

    expect(find.text('PRESCRIPTION REQUIRED'), findsOneWidget);
    expect(find.text('Attach Rx'), findsOneWidget);
  });

  testWidgets('stays hidden for non-Rx carts', (tester) async {
    final nonRxItem = CartItem(
      id: 'cart-non-rx',
      productId: 'prod-non-rx',
      quantity: 1,
      product: Product(
        id: 'prod-non-rx',
        name: 'Regular Tonic',
        slug: 'regular-tonic',
        price: 200,
        stock: 10,
      ),
    );
    await pumpBanner(tester, items: [nonRxItem], prescriptions: const []);

    expect(find.text('PRESCRIPTION REQUIRED'), findsNothing);
    expect(find.text('PRESCRIPTION APPROVED'), findsNothing);
  });
}
