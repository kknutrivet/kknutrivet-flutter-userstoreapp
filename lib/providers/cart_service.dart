import 'dart:math' as math;

import '../core/network/api_client.dart';
import '../models/cart_item.dart';

class CartService {
  CartService(this._client);
  final ApiClient _client;

  Future<List<CartItem>> fetchCart() async {
    final data = await _client.get('/cart');
    return (data as List).map((e) => CartItem.fromJson(e)).toList();
  }

  Future<void> addItem({required String productId, String? variantId, int quantity = 1}) =>
      _client.post('/cart', data: {
        'productId': productId,
        'variantId': ?variantId,
        'quantity': quantity,
      });

  Future<void> setQuantity({required String productId, String? variantId, required int quantity}) =>
      _client.put('/cart', data: {
        'productId': productId,
        'variantId': ?variantId,
        'quantity': quantity,
      });

  Future<void> addCombo(String comboId) =>
      _client.post('/cart', data: {
        'comboId': comboId,
        'addCombo': true,
      });

  Future<void> removeCombo(String comboId) =>
      _client.delete('/cart', query: {'comboId': comboId});

  Future<void> setComboQuantity(String comboId, int comboQuantity) {
    if (comboQuantity <= 0) {
      return removeCombo(comboId);
    }
    return _client.post('/cart', data: {
      'comboId': comboId,
      'comboQuantity': comboQuantity,
    });
  }

  Future<void> removeItem(String cartItemId) => _client.delete('/cart', query: {'id': cartItemId});

  Future<void> clearCart() => _client.delete('/cart');

  /// Folds a guest cart into the signed-in account after login — mirrors
  /// `mergeGuestCart` (lib/cart-client.ts): POST /api/cart/merge {items, mergeId}.
  /// Runs with the fresh account token, exactly like the website, which
  /// passes the new bearer explicitly because the merge happens before the
  /// token reaches storage.
  Future<void> mergeGuestCart(List<Map<String, dynamic>> items) {
    final rand = math.Random().nextInt(99999999).toString().padLeft(8, '0');
    final mergeId = 'merge_${DateTime.now().millisecondsSinceEpoch}_$rand';
    return _client.post('/cart/merge', data: {
      'items': items,
      'mergeId': mergeId,
    });
  }
}
