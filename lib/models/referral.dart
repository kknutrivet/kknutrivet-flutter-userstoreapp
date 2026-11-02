class ReferralSummary {
  ReferralSummary({
    required this.referralCode,
    required this.rewardsPoints,
    this.referralLink,
    this.totalReferrals,
    this.pendingReferrals,
    this.completedReferrals,
    this.referralReward,
    this.referralRewardDescription,
    this.loyaltyHistory = const [],
  });

  final String referralCode;
  final int rewardsPoints;
  final String? referralLink;
  final int? totalReferrals;
  final int? pendingReferrals;
  final int? completedReferrals;
  final double? referralReward;
  final String? referralRewardDescription;

  /// Mirrors `loyaltyHistory[]` in GET /api/referral.
  final List<LoyaltyEntry> loyaltyHistory;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) => ReferralSummary(
        referralCode: json['referralCode'] ?? '',
        // The API sends `loyaltyPoints`; older builds read `rewardsPoints`.
        rewardsPoints: (json['loyaltyPoints'] as num?)?.toInt() ??
            (json['rewardsPoints'] as num?)?.toInt() ??
            0,
        referralLink: json['referralLink'],
        totalReferrals: (json['totalReferrals'] as num?)?.toInt(),
        pendingReferrals: (json['pendingReferrals'] as num?)?.toInt(),
        completedReferrals: (json['completedReferrals'] as num?)?.toInt(),
        referralReward: (json['referralReward'] as num?)?.toDouble(),
        referralRewardDescription: json['referralRewardDescription'],
        loyaltyHistory: (json['loyaltyHistory'] as List?)
                ?.map((e) =>
                    LoyaltyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

/// Mirrors `LoyaltyEntry` in GET /api/referral (lib/referral-client.ts).
class LoyaltyEntry {
  LoyaltyEntry({
    required this.points,
    required this.type,
    required this.description,
    required this.balance,
    required this.date,
  });

  final int points;
  final String type;
  final String description;
  final int balance;
  final String date;

  factory LoyaltyEntry.fromJson(Map<String, dynamic> json) => LoyaltyEntry(
        points: (json['points'] as num?)?.toInt() ?? 0,
        type: json['type']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        date: json['date']?.toString() ?? '',
      );
}
