import '../core/network/api_client.dart';
import '../models/pet.dart';

class PetService {
  PetService(this._client);
  final ApiClient _client;

  Future<List<PetProfile>> fetchPets() async {
    final data = await _client.get('/pets');
    return (data as List).map((e) => PetProfile.fromJson(e)).toList();
  }

  Future<PetProfile> fetchPet(String id) async {
    final data = await _client.get('/pets/$id');
    return PetProfile.fromJson(data['pet']);
  }

  Future<PetProfile> createPet(Map<String, dynamic> payload) async {
    final data = await _client.post('/pets', data: payload);
    return PetProfile.fromJson(data is Map && data.containsKey('pet') ? data['pet'] : data);
  }

  Future<PetProfile> quickAddPet(Map<String, dynamic> payload) async {
    final data = await _client.post('/pets/quick', data: payload);
    return PetProfile.fromJson(data);
  }

  Future<void> deletePet(String id) => _client.delete('/pets/$id');

  Future<PetProfile> updateReminders(String id, Map<String, dynamic> payload) async {
    final data = await _client.patch('/pets/$id', data: payload);
    return PetProfile.fromJson(data['pet']);
  }
}
