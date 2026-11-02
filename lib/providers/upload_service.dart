import '../core/network/api_client.dart';

class UploadService {
  UploadService(this._client);
  final ApiClient _client;

  /// Uploads an image file and returns the public URL.
  Future<String> uploadImage(String filePath, {String purpose = 'general'}) async {
    final data = await _client.upload('/upload', filePath, fields: {'purpose': purpose});
    if (data is Map) {
      if (data['url'] != null) return data['url'].toString();
      if (data['imageUrl'] != null) return data['imageUrl'].toString();
      if (data['file'] != null && data['file'] is Map && data['file']['url'] != null) {
        return data['file']['url'].toString();
      }
    }
    throw ApiException('Upload completed but returned no URL.');
  }
}
