import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/features/cart/widgets/cart_item_tiles.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  group('ComboBundleCartTile Design & Pricing Tests', () {
    testWidgets('renders unified card design with price, strike-through MRP, % OFF and mint stepper', (tester) async {
      final bundleItems = [
        CartItem(
          id: 'item1',
          productId: 'prod1',
          quantity: 1,
          comboId: 'combo-mastitis',
          comboName: 'Cattle Udder Care & Mastitis Combo (3-in-1 Mastitis Shield Kit)',
          comboPrice: 1234,
          comboQuantity: 1,
          product: Product(
            id: 'prod1',
            name: 'Mastitis Powder',
            slug: 'mastitis-powder',
            price: 649,
            mrp: 750,
            images: [],
          ),
        ),
        CartItem(
          id: 'item2',
          productId: 'prod2',
          quantity: 1,
          comboId: 'combo-mastitis',
          product: Product(
            id: 'prod2',
            name: 'MastiWin Spray',
            slug: 'mastiwin-spray',
            price: 349,
            mrp: 398,
            images: [],
          ),
        ),
        CartItem(
          id: 'item3',
          productId: 'prod3',
          quantity: 1,
          comboId: 'combo-mastitis',
          product: Product(
            id: 'prod3',
            name: 'Gratone-H',
            slug: 'gratone-h',
            price: 310,
            mrp: 399,
            images: [],
          ),
        ),
      ];

      final catalogCombos = [
        ComboBundle(
          id: 'combo-mastitis',
          name: 'Cattle Udder Care & Mastitis Combo (3-in-1 Mastitis Shield Kit)',
          originalPrice: 1547,
          comboPrice: 1234,
          isActive: true,
          items: const [],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ComboBundleCartTile(
                comboId: 'combo-mastitis',
                bundleItems: bundleItems,
                combos: catalogCombos,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header chip
      expect(find.text('COMBO BUNDLE · 3 items'), findsOneWidget);
      expect(
        find.text('Cattle Udder Care & Mastitis Combo (3-in-1 Mastitis Shield Kit)'),
        findsOneWidget,
      );
      expect(find.text('View bundle items →'), findsOneWidget);

      // Check top-right remove icon
      expect(find.byTooltip('Remove bundle'), findsOneWidget);

      // Check price: ₹1,234 (not 1893!)
      expect(find.text('₹1,234'), findsOneWidget);

      // Check MRP: ₹1,547
      expect(find.text('₹1,547'), findsOneWidget);

      // Check discount badge: 20% OFF
      expect(find.text('20% OFF'), findsOneWidget);

      // Check stepper with 1
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget); // delete action on the right side
    });

    test('getCartSubtotal calculates combo bundle subtotal correctly without double-counting', () {
      final items = [
        // Standalone product: ₹499
        CartItem(
          id: 'single1',
          productId: 'prod-single',
          quantity: 1,
          product: Product(
            id: 'prod-single',
            name: 'Sanitizing Concentrate',
            slug: 'sanitizing-concentrate',
            price: 499,
            mrp: 650,
            images: [],
          ),
        ),
        // Combo with 3 items: comboPrice is 1234 on item 1
        CartItem(
          id: 'c1',
          productId: 'p1',
          quantity: 1,
          comboId: 'combo1',
          comboPrice: 1234,
          comboQuantity: 1,
          product: Product(id: 'p1', name: 'P1', slug: 'p1', price: 649, images: []),
        ),
        CartItem(
          id: 'c2',
          productId: 'p2',
          quantity: 1,
          comboId: 'combo1',
          product: Product(id: 'p2', name: 'P2', slug: 'p2', price: 349, images: []),
        ),
        CartItem(
          id: 'c3',
          productId: 'p3',
          quantity: 1,
          comboId: 'combo1',
          product: Product(id: 'p3', name: 'P3', slug: 'p3', price: 310, images: []),
        ),
      ];

      // Subtotal should be: 499 + 1234 = 1733 (NOT 499 + 1893 = 2392!)
      final subtotal = getCartSubtotal(items);
      expect(subtotal, 1733);
    });
  });
}
