import '../core/network/api_client.dart';
import '../models/prescription.dart';

class PrescriptionService {
  PrescriptionService(this._client);
  final ApiClient _client;

  Future<List<Prescription>> fetchPrescriptions() async {
    final data = await _client.get('/prescriptions');
    return (data as List).map((e) => Prescription.fromJson(e)).toList();
  }

  Future<Prescription> uploadPrescription({
    required List<String> imageUrls,
    String? notes,
    String? phone,
  }) async {
    final data = await _client.post('/prescriptions', data: {
      'imageUrls': imageUrls,
      'notes': ?notes,
      'phone': ?phone,
    });
    return Prescription.fromJson(data);
  }
}
