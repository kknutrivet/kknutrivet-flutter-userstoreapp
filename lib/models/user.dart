class AppUser {
  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.role = 'CUSTOMER',
    this.authProvider,
    this.isAnonymous = false,
    this.loyaltyPoints,
  });

  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role;
  final String? authProvider;
  final bool isAnonymous;
  final int? loyaltyPoints;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'].toString(),
        email: json['email'] ?? '',
        name: json['name'],
        phone: json['phone'],
        role: json['role'] ?? 'CUSTOMER',
        authProvider: json['authProvider'],
        isAnonymous: json['isAnonymous'] ?? false,
        loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ??
            (json['rewardsPoints'] as num?)?.toInt() ??
            0,
      );
}
