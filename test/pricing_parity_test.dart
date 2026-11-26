import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/models/cart_item.dart';
import 'package:nvit_app/models/coupon.dart';
import 'package:nvit_app/models/pricing.dart';
import 'package:nvit_app/models/product.dart';
import 'package:nvit_app/models/store_settings.dart';

void main() {
  group('StoreSettings Partial COD advance cap parity', () {
    test('uses min(percent%, cap) with ₹1 floor and caps at bill total', () {
      final settings = StoreSettings(
        freeDeliveryThreshold: 500,
        deliveryCharge: 49,
        partialCodEnabled: true,
        partialCodPercent: 15,
        partialCodMinimum: 150, // Max advance cap ₹150
      );

      // 15% of ₹2000 = ₹300, capped at ₹150
      final qLarge = settings.partialCodQuote(2000);
      expect(qLarge.advance, 150);
      expect(qLarge.balance, 1850);

      // 15% of ₹200 = ₹30 (< ₹150 cap, NOT floored to ₹150)
      final qSmall = settings.partialCodQuote(200);
      expect(qSmall.advance, 30);
      expect(qSmall.balance, 170);

      // Tiny order gets ₹1 floor, capped at total
      final qTiny = settings.partialCodQuote(3);
      expect(qTiny.advance, 1);
      expect(qTiny.balance, 2);
    });

    test('uncapped when partialCodMinimum (cap) is 0', () {
      final settings = StoreSettings(
        freeDeliveryThreshold: 500,
        deliveryCharge: 49,
        partialCodEnabled: true,
        partialCodPercent: 20,
        partialCodMinimum: 0,
      );
      final q = settings.partialCodQuote(1000);
      expect(q.advance, 200);
      expect(q.balance, 800);
    });
  });

  group('Prepaid ₹299 free delivery & COD fee parity', () {
    test('Online/Partial COD/Pay Later/EMI unlock ₹299 free delivery while COD uses ₹500 + COD fee', () {
      final settings = StoreSettings.fromJson({
        'freeDeliveryThreshold': 500,
        'localFreeDeliveryThreshold': 500,
        'deliveryCharge': 49,
        'courierDeliveryCharge': 69,
        'courierCodFlatFee': 30,
        'payLaterEnabled': true,
        'businessRules': {
          'delivery': {'prepaidFreeDeliveryThreshold': 299},
          'feedPairing': {'enabled': true, 'discountPercent': 10, 'maxDiscount': 100},
          'loyalty': {'maxRedemptionPercent': 20, 'maxRedemptionCoins': 50, 'coinValue': 1},
        },
      });

      expect(settings.payLaterEnabled, true);
      expect(settings.prepaidFreeDeliveryThreshold, 299);

      // ₹350 order -> FREE for CASHFREE / PARTIAL_COD / PAY_LATER / EMI
      expect(settings.calculateDeliveryFee(350, paymentMethod: 'CASHFREE'), 0);
      expect(settings.calculateDeliveryFee(350, paymentMethod: 'PARTIAL_COD'), 0);
      expect(settings.calculateDeliveryFee(350, paymentMethod: 'PAY_LATER'), 0);
      expect(settings.calculateDeliveryFee(350, paymentMethod: 'EMI'), 0);
      expect(settings.codCollectionFeeFor('CASHFREE'), 0);
      expect(settings.codCollectionFeeFor('PARTIAL_COD'), 0);

      // ₹350 order -> ₹49 delivery + ₹30 COD fee for Full COD
      expect(settings.calculateDeliveryFee(350, paymentMethod: 'COD'), 49);
      expect(settings.codCollectionFeeFor('COD'), 30);

      // ₹250 order -> ₹49 delivery even on Online
      expect(settings.calculateDeliveryFee(250, paymentMethod: 'CASHFREE'), 49);
    });
  });

  group('Feed+Care pairing & Best Single Promo Wins parity', () {
    final settings = StoreSettings(
      freeDeliveryThreshold: 500,
      deliveryCharge: 49,
      feedPairing: const FeedPairingConfig(
        enabled: true,
        discountPercent: 10,
        maxDiscount: 100,
      ),
    );

    final feedItem = CartItem(
      id: 'i1',
      productId: 'p1',
      quantity: 1,
      product: Product(
        id: 'p1',
        name: 'Dog Feed 5kg',
        slug: 'dog-feed',
        price: 800,
        category: 'Feed',
        animalTypes: const ['Dog'],
        stock: 10,
      ),
    );

    final medItem = CartItem(
      id: 'i2',
      productId: 'p2',
      quantity: 1,
      product: Product(
        id: 'p2',
        name: 'Liver Tonic',
        slug: 'liver-tonic',
        price: 600,
        category: 'Medicine',
        stock: 10,
      ),
    );

    final comboMedItem = CartItem(
      id: 'i3',
      productId: 'p3',
      comboId: 'combo-1',
      quantity: 1,
      product: Product(
        id: 'p3',
        name: 'Combo Supplement',
        slug: 'combo-supp',
        price: 500,
        category: 'Supplement & Nutrition',
        stock: 10,
      ),
    );

    test('awards 10% on standalone Medicine/Supplement when Feed is in cart, ignoring combo items', () {
      final breakdown = calculateFeedPairingDiscount(
        [feedItem, medItem, comboMedItem],
        settings,
      );
      expect(breakdown.hasFeed, true);
      expect(breakdown.hasEligibleCare, true);
      expect(breakdown.eligibleSubtotal, 600);
      expect(breakdown.discount, 60); // 10% of 600
    });

    test('Best Single Promo Wins: coupon and feed+care never stack', () {
      final couponWins = resolveBestPromo(
        subtotal: 1400,
        couponDiscount: 100,
        feedPairingDiscount: 60,
      );
      expect(couponWins.effectiveCouponDiscount, 100);
      expect(couponWins.effectiveFeedPairingDiscount, 0);
      expect(couponWins.merchandiseDiscount, 100);
      expect(couponWins.feedPairingSupersededByCoupon, true);

      final feedWins = resolveBestPromo(
        subtotal: 1400,
        couponDiscount: 40,
        feedPairingDiscount: 60,
      );
      expect(feedWins.effectiveCouponDiscount, 0);
      expect(feedWins.effectiveFeedPairingDiscount, 60);
      expect(feedWins.merchandiseDiscount, 60);
      expect(feedWins.couponSupersededByFeedPairing, true);
    });
  });

  group('KK Coins cap parity', () {
    test('caps at 20% of subtotal and 50 coins by default', () {
      expect(maxRedeemablePoints(200, 450), 50);
      expect(maxRedeemablePoints(200, 150), 30);
      expect(maxRedeemablePoints(20, 500), 20);
    });
  });
}
