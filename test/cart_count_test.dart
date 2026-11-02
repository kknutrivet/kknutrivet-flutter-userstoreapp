import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/providers/app_providers.dart';

void main() {
  group('getCartCount tests', () {
    test('returns 0 for empty cart', () {
      expect(getCartCount([]), 0);
    });

    test('counts standalone items by their individual quantities', () {
      final items = [
        CartItem(id: '1', productId: 'p1', quantity: 2),
        CartItem(id: '2', productId: 'p2', quantity: 3),
      ];
      expect(getCartCount(items), 5);
    });

    test('counts combo bundle rows as 1 item, regardless of member count', () {
      // 12-item combo bundle where each row has comboId 'combo-poultry'
      final comboRows = List.generate(
        12,
        (index) => CartItem(
          id: 'row_$index',
          productId: 'prod_$index',
          quantity: 1,
          comboId: 'combo-poultry',
          comboQuantity: 1,
        ),
      );

      expect(getCartCount(comboRows), 1);
    });

    test('counts 1 standalone item and 12-item combo as 2 items total (not 13)',
        () {
      final standalone = CartItem(id: 's1', productId: 'single', quantity: 1);
      final comboRows = List.generate(
        12,
        (index) => CartItem(
          id: 'row_$index',
          productId: 'prod_$index',
          quantity: 1,
          comboId: 'combo-poultry',
          comboQuantity: 1,
        ),
      );

      final cart = [standalone, ...comboRows];
      expect(getCartCount(cart), 2);
    });

    test('multiplies combo bundle quantity correctly when resized', () {
      final comboRows = List.generate(
        5,
        (index) => CartItem(
          id: 'row_$index',
          productId: 'prod_$index',
          quantity: 2,
          comboId: 'combo-poultry',
          comboQuantity: 2,
        ),
      );

      expect(getCartCount(comboRows), 2);
    });
  });
}
