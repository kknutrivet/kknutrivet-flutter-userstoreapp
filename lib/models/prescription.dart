class Prescription {
  Prescription({
    required this.id,
    this.imageUrl,
    this.imageUrls = const [],
    required this.status,
    this.notes,
    this.vetName,
    required this.createdAt,
  });

  final String id;
  final String? imageUrl;
  final List<String> imageUrls;
  final String status;
  final String? notes;
  final String? vetName;
  final DateTime createdAt;

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'].toString(),
        imageUrl: json['imageUrl'],
        imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        status: json['status'] ?? 'PENDING',
        notes: json['notes'],
        vetName: json['vetName'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
