import 'dart:convert';

class AppUpdateConfig {
  const AppUpdateConfig({
    this.forceUpdateEnabled = false,
    this.minBuildNumber = 1,
    this.minAppVersion = '1.0.0',
    this.latestVersion = '1.0.0',
    this.forceUpdateTitle = 'App Update Required',
    this.forceUpdateMessage =
        'A new version of KK Nutrivet is available on Google Play Store with critical improvements and new features. Please update to continue.',
    this.playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.kknutrivet.shop',
    this.maintenanceMode = false,
    this.maintenanceMessage =
        'We are undergoing quick scheduled maintenance to serve your pets better. Please check back shortly.',
  });

  final bool forceUpdateEnabled;
  final int minBuildNumber;
  final String minAppVersion;
  final String latestVersion;
  final String forceUpdateTitle;
  final String forceUpdateMessage;
  final String playStoreUrl;
  final bool maintenanceMode;
  final String maintenanceMessage;

  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) {
    return AppUpdateConfig(
      forceUpdateEnabled: json['forceUpdateEnabled'] == true,
      minBuildNumber: (json['minBuildNumber'] as num?)?.toInt() ?? 1,
      minAppVersion: json['minAppVersion']?.toString() ?? '1.0.0',
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      forceUpdateTitle:
          json['forceUpdateTitle']?.toString() ?? 'App Update Required',
      forceUpdateMessage: json['forceUpdateMessage']?.toString() ??
          'A new version of KK Nutrivet is available on Google Play Store with critical improvements and new features. Please update to continue.',
      playStoreUrl: json['playStoreUrl']?.toString() ??
          'https://play.google.com/store/apps/details?id=com.kknutrivet.shop',
      maintenanceMode: json['maintenanceMode'] == true,
      maintenanceMessage: json['maintenanceMessage']?.toString() ??
          'We are undergoing quick scheduled maintenance to serve your pets better. Please check back shortly.',
    );
  }

  /// Evaluates whether the installed app version or build number is outdated.
  bool isOutdated({
    required int currentBuildNumber,
    required String currentVersion,
  }) {
    if (currentBuildNumber < minBuildNumber) {
      return true;
    }
    return _isSemanticVersionLower(currentVersion, minAppVersion);
  }

  /// Compares semantic versions (e.g. "1.0.0" < "1.0.1").
  static bool _isSemanticVersionLower(String current, String required) {
    try {
      final currentParts = current
          .split('.')
          .map((s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0)
          .toList();
      final requiredParts = required
          .split('.')
          .map((s) => int.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0)
          .toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (requiredParts.length < 3) {
        requiredParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (currentParts[i] < requiredParts[i]) return true;
        if (currentParts[i] > requiredParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

class FeedPairingConfig {
  const FeedPairingConfig({
    this.enabled = true,
    this.discountPercent = 10.0,
    this.maxDiscount = 100.0,
  });

  final bool enabled;
  final double discountPercent;
  final double maxDiscount;

  factory FeedPairingConfig.fromJson(Map<String, dynamic> json) {
    return FeedPairingConfig(
      enabled: json['enabled'] != false,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 10.0,
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class LoyaltyRulesConfig {
  const LoyaltyRulesConfig({
    this.spendPerCoin = 20.0,
    this.coinValue = 1.0,
    this.maxRedemptionPercent = 20.0,
    this.maxRedemptionCoins = 50,
  });

  final double spendPerCoin;
  final double coinValue;
  final double maxRedemptionPercent;
  final int maxRedemptionCoins;

  factory LoyaltyRulesConfig.fromJson(Map<String, dynamic> json) {
    return LoyaltyRulesConfig(
      spendPerCoin: (json['spendPerCoin'] as num?)?.toDouble() ?? 20.0,
      coinValue: (json['coinValue'] as num?)?.toDouble() ?? 1.0,
      maxRedemptionPercent:
          (json['maxRedemptionPercent'] as num?)?.toDouble() ?? 20.0,
      maxRedemptionCoins:
          (json['maxRedemptionCoins'] as num?)?.toInt() ?? 50,
    );
  }
}

class StoreSettings {
  StoreSettings({
    required this.freeDeliveryThreshold,
    required this.deliveryCharge,
    this.localFreeDeliveryThreshold,
    this.prepaidFreeDeliveryThreshold = 0.0,
    this.courierDeliveryCharge,
    this.courierCodFlatFee = 0.0,
    this.codEnabled = true,
    this.codMaxOrderAmount = 1500.0,
    this.onlinePaymentsEnabled = true,
    this.payLaterEnabled = false,
    this.partialCodEnabled = false,
    this.partialCodPercent,
    this.partialCodMinimum,
    this.discountEnabled = false,
    this.codConfirmationEnabled = true,
    this.prescriptionDiscountPercent = 5,
    this.hiddenCategories = const [],
    this.appUpdate = const AppUpdateConfig(),
    this.feedPairing = const FeedPairingConfig(),
    this.loyaltyRules = const LoyaltyRulesConfig(),
  });

  final double freeDeliveryThreshold;
  final double? localFreeDeliveryThreshold;
  final double prepaidFreeDeliveryThreshold;
  final double deliveryCharge;
  final double? courierDeliveryCharge;
  final double courierCodFlatFee;
  final bool codEnabled;
  /// Maximum order amount (before COD handling fee) eligible for 100% Full COD (`0` = unlimited).
  final double codMaxOrderAmount;
  final bool onlinePaymentsEnabled;
  final bool payLaterEnabled;
  final bool partialCodEnabled;
  final double? partialCodPercent;
  /// Maximum Partial COD advance cap in rupees (0 = uncapped).
  /// Kept as `partialCodMinimum` for zero-migration backend parity.
  final double? partialCodMinimum;
  final bool discountEnabled;
  final bool codConfirmationEnabled;
  final int prescriptionDiscountPercent;
  final List<String> hiddenCategories;
  final AppUpdateConfig appUpdate;
  final FeedPairingConfig feedPairing;
  final LoyaltyRulesConfig loyaltyRules;

  static final RegExp _odishaPinRegex = RegExp(r'^(75|76|77)\d{4}$');

  static bool isOdishaOrLocal({String? pincode, String? source}) {
    if (source == 'local') return true;
    final trimmed = (pincode ?? '').trim();
    if (trimmed.isEmpty) return true;
    return _odishaPinRegex.hasMatch(trimmed);
  }

  /// Mirrors `calculateDeliveryPricing` in `src/lib/delivery-pricing.ts`:
  /// Non-COD payments (Online, Partial COD, Pay Later, EMI) unlock the lower
  /// `prepaidFreeDeliveryThreshold` (e.g. ₹299) when configured.
  double effectiveFreeDeliveryThreshold({
    String? pincode,
    String? source,
    String? paymentMethod,
  }) {
    final standardThreshold = isOdishaOrLocal(pincode: pincode, source: source)
        ? (localFreeDeliveryThreshold ?? freeDeliveryThreshold)
        : freeDeliveryThreshold;
    final isFullCod = paymentMethod == 'COD';
    if (!isFullCod && prepaidFreeDeliveryThreshold > 0) {
      return standardThreshold > 0
          ? (prepaidFreeDeliveryThreshold < standardThreshold
              ? prepaidFreeDeliveryThreshold
              : standardThreshold)
          : prepaidFreeDeliveryThreshold;
    }
    return standardThreshold;
  }

  double effectiveDeliveryCharge({String? pincode, String? source}) =>
      isOdishaOrLocal(pincode: pincode, source: source)
          ? deliveryCharge
          : (courierDeliveryCharge ?? deliveryCharge);

  double calculateDeliveryFee(
    double merchandiseAfterDiscount, {
    String? pincode,
    String? source,
    String? paymentMethod,
  }) {
    final threshold = effectiveFreeDeliveryThreshold(
      pincode: pincode,
      source: source,
      paymentMethod: paymentMethod,
    );
    final charge = effectiveDeliveryCharge(pincode: pincode, source: source);
    final clampedMerchandise =
        merchandiseAfterDiscount < 0 ? 0.0 : merchandiseAfterDiscount;
    if (threshold > 0 && clampedMerchandise >= threshold) {
      return 0.0;
    }
    return charge;
  }

  /// Full COD pays the saved flat COD fee; Online / Partial COD / Pay Later / EMI pay ₹0.
  double codCollectionFeeFor(String paymentMethod) {
    if (paymentMethod != 'COD' || courierCodFlatFee <= 0) return 0.0;
    return (courierCodFlatFee * 100).round() / 100.0;
  }

  /// True when Full COD has an active rupee cap (`> 0`) and [amountBeforeCodFee] exceeds it.
  bool exceedsCodMaxOrderAmount(
    double amountBeforeCodFee, {
    double? overrideMax,
  }) {
    final limit = overrideMax ?? codMaxOrderAmount;
    if (limit <= 0) return false;
    final clamped = amountBeforeCodFee < 0 ? 0.0 : amountBeforeCodFee;
    return (clamped * 100).round() > (limit * 100).round();
  }

  /// Mirrors `partialCodQuote` in `src/lib/order-payment.ts`:
  /// Integer rupee advance = min(max(1, round(total * percent%)), cap), capped at total.
  ({double advance, double balance}) partialCodQuote(double total) {
    final percent = partialCodPercent ?? 15.0;
    final cap = partialCodMinimum ?? 0.0;
    if (total <= 0) {
      return (advance: 0.0, balance: 0.0);
    }
    final calculated = (total * percent / 100.0).roundToDouble();
    final calculatedAdvance = calculated < 1.0 ? 1.0 : calculated;
    final capAdvance = cap.roundToDouble();
    final capped = (capAdvance > 0 && calculatedAdvance > capAdvance)
        ? capAdvance
        : calculatedAdvance;
    final roundedTotal = total.roundToDouble();
    final finalAdvance = capped > roundedTotal ? roundedTotal : capped;
    final rawBalance = ((total - finalAdvance) * 100).round() / 100.0;
    final balance = rawBalance < 0 ? 0.0 : rawBalance;
    return (advance: finalAdvance, balance: balance);
  }

  static Map<String, dynamic>? _parseBusinessRules(dynamic br) {
    if (br is Map) {
      return Map<String, dynamic>.from(br);
    }
    if (br is String && br.isNotEmpty) {
      try {
        final decoded = jsonDecode(br);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    final freeDeliveryThreshold =
        (json['freeDeliveryThreshold'] as num?)?.toDouble() ?? 500.0;
    final deliveryCharge =
        (json['deliveryCharge'] as num?)?.toDouble() ?? 49.0;
    final brMap = _parseBusinessRules(json['businessRules']);
    final deliveryRules = brMap?['delivery'] is Map
        ? Map<String, dynamic>.from(brMap!['delivery'] as Map)
        : null;
    final codPolicy = brMap?['codPolicy'] is Map
        ? Map<String, dynamic>.from(brMap!['codPolicy'] as Map)
        : null;
    final prepaidThreshold =
        (json['prepaidFreeDeliveryThreshold'] as num?)?.toDouble() ??
            (deliveryRules?['prepaidFreeDeliveryThreshold'] as num?)
                ?.toDouble() ??
            0.0;
    final rawCodMax =
        (json['codMaxOrderAmount'] as num?)?.toDouble() ??
            (codPolicy?['maxOrderAmount'] as num?)?.toDouble() ??
            1500.0;

    return StoreSettings(
      freeDeliveryThreshold: freeDeliveryThreshold,
      localFreeDeliveryThreshold:
          (json['localFreeDeliveryThreshold'] as num?)?.toDouble() ??
              freeDeliveryThreshold,
      prepaidFreeDeliveryThreshold:
          prepaidThreshold > 0 ? prepaidThreshold : 0.0,
      deliveryCharge: deliveryCharge,
      courierDeliveryCharge:
          (json['courierDeliveryCharge'] as num?)?.toDouble() ??
              deliveryCharge,
      courierCodFlatFee:
          (json['courierCodFlatFee'] as num?)?.toDouble() ?? 0.0,
      codEnabled: json['codEnabled'] != false,
      codMaxOrderAmount: rawCodMax >= 0 ? rawCodMax : 1500.0,
      onlinePaymentsEnabled: json['onlinePaymentsEnabled'] != false,
      payLaterEnabled: json['payLaterEnabled'] == true,
      partialCodEnabled: json['partialCodEnabled'] == true,
      partialCodPercent:
          (json['partialCodPercent'] as num?)?.toDouble(),
      partialCodMinimum:
          (json['partialCodMinimum'] as num?)?.toDouble(),
      discountEnabled: json['discountEnabled'] == true,
      codConfirmationEnabled: json['codConfirmationEnabled'] != false,
      prescriptionDiscountPercent:
          (json['prescriptionDiscountPercent'] as num?)?.toInt() ?? 5,
      hiddenCategories: (json['hiddenCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      appUpdate: json['appUpdate'] is Map
          ? AppUpdateConfig.fromJson(
              Map<String, dynamic>.from(json['appUpdate'] as Map))
          : (brMap != null && brMap['appUpdate'] is Map
              ? AppUpdateConfig.fromJson(
                  Map<String, dynamic>.from(brMap['appUpdate'] as Map))
              : const AppUpdateConfig()),
      feedPairing: brMap != null && brMap['feedPairing'] is Map
          ? FeedPairingConfig.fromJson(
              Map<String, dynamic>.from(brMap['feedPairing'] as Map))
          : const FeedPairingConfig(),
      loyaltyRules: brMap != null && brMap['loyalty'] is Map
          ? LoyaltyRulesConfig.fromJson(
              Map<String, dynamic>.from(brMap['loyalty'] as Map))
          : const LoyaltyRulesConfig(),
    );
  }

  /// Default baseline settings used only if network is completely offline.
  factory StoreSettings.defaults() => StoreSettings(
        freeDeliveryThreshold: 500.0,
        deliveryCharge: 49.0,
        localFreeDeliveryThreshold: 500.0,
        prepaidFreeDeliveryThreshold: 299.0,
        courierDeliveryCharge: 49.0,
        courierCodFlatFee: 0.0,
        codEnabled: true,
        onlinePaymentsEnabled: true,
        payLaterEnabled: false,
        partialCodEnabled: true,
        partialCodPercent: 15.0,
        partialCodMinimum: 150.0,
      );
}
