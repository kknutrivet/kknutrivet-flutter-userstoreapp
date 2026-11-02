/// Mirrors the response of GET /api/delivery?pincode= — backed by NimbusPost
/// courier serviceability, with a local DeliveryZone table as a fast path.
class DeliveryInfo {
  DeliveryInfo({
    required this.pincode,
    required this.serviceable,
    required this.deliveryDays,
    required this.deliveryDaysMax,
    required this.cod,
    required this.prepaid,
    this.city,
    required this.source,
    required this.message,
  });

  final String pincode;
  final bool serviceable;
  final int deliveryDays;
  final int deliveryDaysMax;
  final bool cod;
  final bool prepaid;
  final String? city;
  final String source;
  final String message;

  String get etaLabel {
    if (!serviceable) return '';
    if (deliveryDays == deliveryDaysMax) return '$deliveryDays day${deliveryDays == 1 ? '' : 's'}';
    return '$deliveryDays-$deliveryDaysMax days';
  }

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) => DeliveryInfo(
        pincode: (json['pincode'] ?? '').toString(),
        serviceable: json['serviceable'] ?? false,
        deliveryDays: (json['deliveryDays'] as num?)?.toInt() ?? 0,
        deliveryDaysMax: (json['deliveryDaysMax'] as num?)?.toInt() ?? 0,
        cod: json['cod'] ?? false,
        prepaid: json['prepaid'] ?? false,
        city: json['city'],
        source: json['source'] ?? 'local',
        message: json['message'] ?? '',
      );
}
