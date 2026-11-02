class PetProfile {
  PetProfile({
    required this.id,
    required this.name,
    required this.animalType,
    this.breed,
    this.dateOfBirth,
    this.weightKg,
    this.photoUrl,
    this.sex,
    this.isNeutered,
    this.notes,
    this.lastDewormingAt,
    this.nextDewormingAt,
    this.lastVaccinationAt,
    this.nextVaccinationAt,
    this.reminderEnabled = false,
    this.careGuide,
  });

  final String id;
  final String name;
  final String animalType;
  final String? breed;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final String? photoUrl;
  final String? sex;
  final bool? isNeutered;
  final String? notes;
  final DateTime? lastDewormingAt;
  final DateTime? nextDewormingAt;
  final DateTime? lastVaccinationAt;
  final DateTime? nextVaccinationAt;
  final bool reminderEnabled;
  final Map<String, dynamic>? careGuide;

  factory PetProfile.fromJson(Map<String, dynamic> json) => PetProfile(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        animalType: json['animalType'] ?? '',
        breed: json['breed'],
        dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        photoUrl: json['photoUrl'],
        sex: json['sex'],
        isNeutered: json['isNeutered'],
        notes: json['notes'],
        lastDewormingAt:
            json['lastDewormingAt'] != null ? DateTime.tryParse(json['lastDewormingAt']) : null,
        nextDewormingAt:
            json['nextDewormingAt'] != null ? DateTime.tryParse(json['nextDewormingAt']) : null,
        lastVaccinationAt: json['lastVaccinationAt'] != null
            ? DateTime.tryParse(json['lastVaccinationAt'])
            : null,
        nextVaccinationAt: json['nextVaccinationAt'] != null
            ? DateTime.tryParse(json['nextVaccinationAt'])
            : null,
        reminderEnabled: json['reminderEnabled'] ?? false,
        careGuide: json['careGuide'] is Map<String, dynamic> ? json['careGuide'] : null,
      );

  int? get ageInMonths {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    return (now.year - dateOfBirth!.year) * 12 + (now.month - dateOfBirth!.month);
  }
}
