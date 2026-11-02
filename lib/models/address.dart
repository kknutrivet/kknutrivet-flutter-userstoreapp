class Address {
  Address({
    required this.id,
    this.label,
    required this.fullName,
    required this.phone,
    this.buildingNumber,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });

  final String id;
  final String? label;
  final String fullName;
  final String phone;
  final String? buildingNumber;
  final String fullAddress;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  /// Returns full display address line including building number if provided
  String get formattedAddress {
    final bldg = (buildingNumber ?? '').trim();
    if (bldg.isEmpty) return fullAddress;
    if (fullAddress.toLowerCase().contains(bldg.toLowerCase())) {
      return fullAddress;
    }
    return '$bldg, $fullAddress';
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'].toString(),
        label: json['label'],
        fullName: json['fullName'] ?? '',
        phone: json['phone'] ?? '',
        buildingNumber: json['buildingNumber']?.toString(),
        fullAddress: json['fullAddress'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        zipCode: json['zipCode'] ?? '',
        isDefault: json['isDefault'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (label != null) 'label': label,
        'fullName': fullName,
        'phone': phone,
        if (buildingNumber != null && buildingNumber!.isNotEmpty)
          'buildingNumber': buildingNumber,
        'fullAddress': fullAddress,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'isDefault': isDefault,
      };
}
