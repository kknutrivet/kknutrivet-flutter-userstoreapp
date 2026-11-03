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

class StoreSettings {
  StoreSettings({
    required this.freeDeliveryThreshold,
    required this.deliveryCharge,
    this.localFreeDeliveryThreshold,
    this.courierDeliveryCharge,
    this.courierCodFlatFee = 0.0,
    this.codEnabled = true,
    this.onlinePaymentsEnabled = true,
    this.partialCodEnabled = false,
    this.partialCodPercent,
    this.partialCodMinimum,
    this.discountEnabled = false,
    this.codConfirmationEnabled = true,
    this.prescriptionDiscountPercent = 5,
    this.hiddenCategories = const [],
    this.appUpdate = const AppUpdateConfig(),
  });

  final double freeDeliveryThreshold;
  final double? localFreeDeliveryThreshold;
  final double deliveryCharge;
  final double? courierDeliveryCharge;
  final double courierCodFlatFee;
  final bool codEnabled;
  final bool onlinePaymentsEnabled;
  final bool partialCodEnabled;
  final double? partialCodPercent;
  final double? partialCodMinimum;
  final bool discountEnabled;
  final bool codConfirmationEnabled;
  final int prescriptionDiscountPercent;
  final List<String> hiddenCategories;
  final AppUpdateConfig appUpdate;

  static final RegExp _odishaPinRegex = RegExp(r'^(75|76|77)\d{4}$');

  static bool isOdishaOrLocal({String? pincode, String? source}) {
    if (source == 'local') return true;
    final trimmed = (pincode ?? '').trim();
    if (trimmed.isEmpty) return true;
    return _odishaPinRegex.hasMatch(trimmed);
  }

  double effectiveFreeDeliveryThreshold({String? pincode, String? source}) =>
      isOdishaOrLocal(pincode: pincode, source: source)
          ? (localFreeDeliveryThreshold ?? freeDeliveryThreshold)
          : freeDeliveryThreshold;

  double effectiveDeliveryCharge({String? pincode, String? source}) =>
      isOdishaOrLocal(pincode: pincode, source: source)
          ? deliveryCharge
          : (courierDeliveryCharge ?? deliveryCharge);

  double calculateDeliveryFee(
    double merchandiseAfterDiscount, {
    String? pincode,
    String? source,
  }) {
    final threshold =
        effectiveFreeDeliveryThreshold(pincode: pincode, source: source);
    final charge = effectiveDeliveryCharge(pincode: pincode, source: source);
    final clampedMerchandise =
        merchandiseAfterDiscount < 0 ? 0.0 : merchandiseAfterDiscount;
    if (threshold > 0 && clampedMerchandise >= threshold) {
      return 0.0;
    }
    return charge;
  }

  /// Calculates the Partial COD / Partial Payment quote (advance + balance on delivery).
  ({double advance, double balance}) partialCodQuote(double total) {
    final percent = partialCodPercent ?? 20.0;
    final minimum = partialCodMinimum ?? 50.0;
    if (total <= 0) {
      return (advance: 0.0, balance: 0.0);
    }
    final calculatedAdvance = (total * percent / 100).roundToDouble();
    final minAdvance = minimum.roundToDouble();
    final advance = (total.roundToDouble() < minAdvance)
        ? total.roundToDouble()
        : (calculatedAdvance < minAdvance ? minAdvance : calculatedAdvance);
    final finalAdvance =
        advance > total.roundToDouble() ? total.roundToDouble() : advance;
    final balance = (total - finalAdvance).clamp(0.0, double.infinity);
    return (advance: finalAdvance, balance: balance);
  }

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    final freeDeliveryThreshold =
        (json['freeDeliveryThreshold'] as num?)?.toDouble() ?? 500.0;
    final deliveryCharge =
        (json['deliveryCharge'] as num?)?.toDouble() ?? 49.0;
    return StoreSettings(
      freeDeliveryThreshold: freeDeliveryThreshold,
      localFreeDeliveryThreshold:
          (json['localFreeDeliveryThreshold'] as num?)?.toDouble() ??
              freeDeliveryThreshold,
      deliveryCharge: deliveryCharge,
      courierDeliveryCharge:
          (json['courierDeliveryCharge'] as num?)?.toDouble() ??
              deliveryCharge,
      courierCodFlatFee:
          (json['courierCodFlatFee'] as num?)?.toDouble() ?? 0.0,
      codEnabled: json['codEnabled'] != false,
      onlinePaymentsEnabled: json['onlinePaymentsEnabled'] != false,
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
          : (json['businessRules'] is Map &&
                  (json['businessRules'] as Map)['appUpdate'] is Map
              ? AppUpdateConfig.fromJson(Map<String, dynamic>.from(
                  (json['businessRules'] as Map)['appUpdate'] as Map))
              : const AppUpdateConfig()),
    );
  }

  /// Default baseline settings used only if network is completely offline.
  factory StoreSettings.defaults() => StoreSettings(
        freeDeliveryThreshold: 500.0,
        deliveryCharge: 49.0,
        localFreeDeliveryThreshold: 500.0,
        courierDeliveryCharge: 49.0,
        courierCodFlatFee: 0.0,
        codEnabled: true,
        onlinePaymentsEnabled: true,
        partialCodEnabled: true,
        partialCodPercent: 15.0,
        partialCodMinimum: 50.0,
      );
}
