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
      );
}
