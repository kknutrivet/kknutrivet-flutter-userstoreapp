import 'dart:math' as math;

import 'cart_item.dart';
import 'store_settings.dart';

const String kFeedPairingTriggerCategory = 'Feed';
const Set<String> kFeedPairingEligibleCategories = {
  'Medicine',
  'Supplement & Nutrition',
};

class FeedPairingBreakdown {
  const FeedPairingBreakdown({
    required this.enabled,
    required this.hasFeed,
    required this.hasEligibleCare,
    required this.eligibleSubtotal,
    required this.discount,
    required this.discountPercent,
    required this.maxDiscount,
    required this.feedAnimalTypes,
  });

  final bool enabled;
  final bool hasFeed;
  final bool hasEligibleCare;
  final double eligibleSubtotal;
  final double discount;
  final double discountPercent;
  final double maxDiscount;
  final List<String> feedAnimalTypes;

  double get remainingSavingsCap =>
      math.max(0.0, maxDiscount - discount);
}

/// Mirrors `calculateFeedPairingDiscount` in `src/lib/pricing.ts`.
///
/// When a cart has at least one `Feed` item, standalone `Medicine` or
/// `Supplement & Nutrition` items (not part of a combo) unlock a configurable
/// percentage discount (default 10%, max ₹100) on those eligible care items.
FeedPairingBreakdown calculateFeedPairingDiscount(
  List<CartItem> items,
  StoreSettings settings,
) {
  final cfg = settings.feedPairing;
  var hasFeed = false;
  var hasEligibleCare = false;
  var eligibleSubtotal = 0.0;
  final animalTypes = <String>{};

  for (final item in items) {
    final category = item.product?.category?.trim() ?? '';
    if (category == kFeedPairingTriggerCategory) {
      hasFeed = true;
      for (final a in item.product?.animalTypes ?? const <String>[]) {
        if (a.trim().isNotEmpty) animalTypes.add(a.trim());
      }
    }
    final isComboItem = item.comboId != null && item.comboId!.isNotEmpty;
    if (!isComboItem &&
        item.product != null &&
        kFeedPairingEligibleCategories.contains(category)) {
      hasEligibleCare = true;
      eligibleSubtotal += item.lineTotal;
    }
  }

  final rawDiscount =
      cfg.enabled &&
          hasFeed &&
          eligibleSubtotal > 0 &&
          cfg.discountPercent > 0 &&
          cfg.maxDiscount > 0
      ? math
            .min(
              (eligibleSubtotal * cfg.discountPercent) / 100.0,
              cfg.maxDiscount,
            )
            .roundToDouble()
      : 0.0;

  final cappedDiscount = math.min(
    rawDiscount,
    eligibleSubtotal.roundToDouble(),
  );

  return FeedPairingBreakdown(
    enabled: cfg.enabled,
    hasFeed: hasFeed,
    hasEligibleCare: hasEligibleCare,
    eligibleSubtotal: eligibleSubtotal,
    discount: cappedDiscount,
    discountPercent: cfg.discountPercent,
    maxDiscount: cfg.maxDiscount,
    feedAnimalTypes: animalTypes.toList(),
  );
}

/// Best Single Promo Wins (matches `src/lib/pricing.ts` & `src/app/api/orders/route.ts`):
/// Coupon and Feed+Care pairing discount never stack — whichever saves the customer more applies.
class BestPromoResolution {
  const BestPromoResolution({
    required this.effectiveCouponDiscount,
    required this.effectiveFeedPairingDiscount,
    required this.merchandiseDiscount,
    required this.couponSupersededByFeedPairing,
    required this.feedPairingSupersededByCoupon,
  });

  final double effectiveCouponDiscount;
  final double effectiveFeedPairingDiscount;
  final double merchandiseDiscount;
  final bool couponSupersededByFeedPairing;
  final bool feedPairingSupersededByCoupon;
}

BestPromoResolution resolveBestPromo({
  required double subtotal,
  required double couponDiscount,
  required double feedPairingDiscount,
}) {
  final safeSubtotal = math.max(0.0, subtotal);
  final safeCoupon = math.max(0.0, couponDiscount);
  final safeFeed = math.max(0.0, feedPairingDiscount);

  if (safeFeed > safeCoupon) {
    final effective = math.min(safeFeed, safeSubtotal);
    return BestPromoResolution(
      effectiveCouponDiscount: 0.0,
      effectiveFeedPairingDiscount: effective,
      merchandiseDiscount: effective,
      couponSupersededByFeedPairing: safeCoupon > 0,
      feedPairingSupersededByCoupon: false,
    );
  }

  final effective = math.min(safeCoupon, safeSubtotal);
  return BestPromoResolution(
    effectiveCouponDiscount: effective,
    effectiveFeedPairingDiscount: 0.0,
    merchandiseDiscount: effective,
    couponSupersededByFeedPairing: false,
    feedPairingSupersededByCoupon: safeFeed > 0 && safeCoupon >= safeFeed,
  );
}
