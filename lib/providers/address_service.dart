import '../core/network/api_client.dart';
import '../models/address.dart';

class AddressService {
  AddressService(this._client);
  final ApiClient _client;

  Future<List<Address>> fetchAddresses() async {
    try {
      final data = await _client.get('/addresses');
      return (data as List).map((e) => Address.fromJson(e)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 401) return const [];
      rethrow;
    } catch (_) {
      return const [];
    }
  }

  Future<Address> addAddress(Address address) async {
    final data = await _client.post('/addresses', data: address.toJson());
    return Address.fromJson(data);
  }

  Future<Address> updateAddress(String id, Address address) async {
    final data = await _client.put('/addresses', data: {'id': id, ...address.toJson()});
    return Address.fromJson(data);
  }

  Future<void> deleteAddress(String id) => _client.delete('/addresses', query: {'id': id});
}
