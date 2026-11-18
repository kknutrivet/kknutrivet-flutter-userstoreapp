import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nvit_app/features/checkout/widgets/checkout_address_section.dart';
import 'package:nvit_app/features/checkout/widgets/checkout_payment_and_review.dart';
import 'package:nvit_app/models/address.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final sampleProduct = Product(
    id: 'prod-1',
    name: 'Rose Floor Cleaner',
    slug: 'rose-floor-cleaner',
    price: 169,
    mrp: 199,
  );

  final List<CartItem> sampleItems = [
    CartItem(
      id: 'cart-1',
      productId: 'prod-1',
      product: sampleProduct,
      quantity: 2,
    ),
  ];

  final sampleAddresses = [
    Address(
      id: 'addr-1',
      fullName: 'Saroj Panigrahy',
      phone: '8892635336',
      fullAddress: 'Hanuman temple road, Manikonda, Gandipet mandal',
      city: 'Hyderabad',
      state: 'Telangana',
      zipCode: '500089',
      isDefault: true,
      label: 'Home',
    ),
    Address(
      id: 'addr-2',
      fullName: 'Saroj Panigrahy',
      phone: '8892635336',
      fullAddress: 'Aditya Nivas, Berhampur',
      city: 'Berhampur',
      state: 'Odisha',
      zipCode: '760004',
      isDefault: false,
      label: 'Home',
    ),
  ];

  testWidgets(
    'tapping Order review arrow/card opens order review bottom sheet',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutOrderReviewSection(
              items: sampleItems,
              combos: const [],
              cartCount: 2,
              subtotal: 338,
              deliveryFee: 49,
            ),
          ),
        ),
      );

      // Verify the order review card is visible
      expect(find.textContaining('Order review'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      // Tap the arrow/card
      await tester.tap(find.textContaining('Order review'));
      await tester.pumpAndSettle();

      // Verify the bottom sheet opened
      expect(find.text('Order review · 2 items'), findsOneWidget);
      expect(find.text('Rose Floor Cleaner'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done to close
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify sheet is dismissed
      expect(find.text('Order review · 2 items'), findsNothing);
    },
  );

  testWidgets(
    'tapping Change address arrow/button opens address picker bottom sheet',
    (tester) async {
      Address? selected;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CheckoutAddressSection(
                addressesAsync: AsyncData(sampleAddresses),
                selectedAddressId: 'addr-1',
                addressExpanded: false,
                onSelectAddress: (addr) => selected = addr,
                onToggleExpanded: () {},
                onDefaultAddressResolved: (_) {},
              ),
            ),
          ),
        ),
      );

      // Verify change button is visible with down arrow
      final changeFinder = find.text('Change (1 more)');
      expect(changeFinder, findsOneWidget);

      // Tap Change button
      await tester.tap(changeFinder);
      await tester.pumpAndSettle();

      // Verify the address bottom sheet opened
      expect(find.text('Select delivery address'), findsOneWidget);
      expect(find.textContaining('Berhampur'), findsOneWidget);

      // Tap second address to select it
      await tester.tap(find.textContaining('Berhampur'));
      await tester.pumpAndSettle();

      // Verify selection callback fired and sheet dismissed
      expect(selected?.id, 'addr-2');
      expect(find.text('Select delivery address'), findsNothing);
    },
  );
}
