import '../core/widgets/product_card.dart' show formatInr;

/// Mirrors `CouponOffer` (lib/coupons-client.ts): the public coupon list
/// from GET /api/coupons shown in the cart's offers sheet.
class CouponOffer {
  CouponOffer({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minOrderAmount,
    this.firstTimeOnly = false,
    this.expiresAt,
  });

  final String id;
  final String code;
  final String? description;
  final String discountType; // 'percent' | 'flat' | 'fixed'
  final double discountValue;
  final double? maxDiscount;
  final double minOrderAmount;
  final bool firstTimeOnly;
  final DateTime? expiresAt;

  /// "10% OFF up to ₹30" / "₹50 OFF".
  String get headline {
    if (discountType == 'percent') {
      final base =
          '${discountValue.toStringAsFixed(discountValue.truncateToDouble() == discountValue ? 0 : 1)}% OFF';
      return maxDiscount != null && maxDiscount! > 0
          ? '$base up to ₹${formatInr(maxDiscount!)}'
          : base;
    }
    return '₹${formatInr(discountValue)} OFF';
  }

  /// "On orders of ₹399 or more" / "On any order".
  String get subline => minOrderAmount > 0
      ? 'On orders of ₹${formatInr(minOrderAmount)} or more'
      : 'On any order';

  /// Human-readable expiry badge or note from dynamic backend expiration timestamp.
  String? get expiryBadge {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    final diff = expiresAt!.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inDays == 0) {
      if (diff.inHours > 0) return 'Expires in ${diff.inHours}h';
      return 'Expires today';
    }
    if (diff.inDays == 1) return 'Expires tomorrow';
    if (diff.inDays <= 7) return 'Expires in ${diff.inDays} days';
    return 'Valid till ${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  factory CouponOffer.fromJson(Map<String, dynamic> json) {
    DateTime? exp;
    final rawExp = json['expiresAt'] ?? json['validUntil'] ?? json['endDate'];
    if (rawExp is String && rawExp.isNotEmpty) {
      exp = DateTime.tryParse(rawExp);
    }
    return CouponOffer(
      id: json['id'].toString(),
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discountType']?.toString() ?? 'flat',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
      firstTimeOnly: json['firstTimeOnly'] ?? false,
      expiresAt: exp,
    );
  }
}

/// Loyalty cap mirrored from `getMaxRedeemablePoints` (lib/loyalty.ts):
/// at most 30% of the subtotal can be paid with KK Coins (1 coin = ₹1).
int maxRedeemablePoints(int loyaltyPoints, double subtotal) {
  final cap = (subtotal * 0.30).floor();
  return loyaltyPoints.clamp(0, cap);
}
