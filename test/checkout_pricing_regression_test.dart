import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/providers/app_providers.dart';
import 'package:nvit_app/features/referral/screens/referral_screen.dart';
import 'package:nvit_app/models/referral.dart';

class CartFixture extends CartNotifier {
  @override
  Future<List<CartItem>> build() async => [item(10)];
  void replace(int quantity) => state = AsyncData([item(quantity)]);
  static CartItem item(int qty) => CartItem(id: 'c', productId: 'p', quantity: qty, product: Product(id: 'p', name: 'Food', slug: 'food', price: 100, stock: 20));
}
void main() {
  test('cart reduction clears coupon and synchronizes redeemed coins', () async {
    final container = ProviderContainer(overrides: [
      cartProvider.overrideWith(CartFixture.new),
      homeCombosProvider.overrideWith((ref) async => []),
      referralSummaryProvider.overrideWith((ref) async => ReferralSummary(referralCode: 'x', rewardsPoints: 1000)),
    ]);
    addTearDown(container.dispose);
    await container.read(cartProvider.future);
    container.read(checkoutDraftProvider.notifier).state = const CheckoutDraft(couponCode: 'SAVE', couponDiscount: 100, pointsToRedeem: 300);
    (container.read(cartProvider.notifier) as CartFixture).replace(2);
    final draft = container.read(checkoutDraftProvider);
    expect(draft.pointsToRedeem, 60);
    expect(draft.couponCode, isNull);
    expect(draft.couponDiscount, 0);
  });
  test('selected pack stock takes precedence over product stock', () {
    final product = Product(id: 'p', name: 'Food', slug: 'food', price: 100, stock: 50);
    final item = CartItem(id: 'i', productId: 'p', quantity: 1, product: product, variant: ProductVariant(id: 'v', name: 'Small', price: 100, stock: 0));
    expect(item.hasStockIssue, isTrue);
  });
}
