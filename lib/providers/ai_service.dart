import '../core/network/api_client.dart';
import '../models/chat.dart';
import '../models/product.dart';

class AiService {
  AiService(this._client);
  final ApiClient _client;

  Future<ChatMessage> ask({
    required String question,
    String? animalType,
    String? language,
    String? petProfileId,
    Product? currentProduct,
    List<Map<String, dynamic>>? history,
  }) async {
    try {
      final payload = <String, dynamic>{
        'question': question,
        if (animalType != null && animalType.isNotEmpty) 'animalType': animalType,
        if (language != null && language.isNotEmpty) 'language': language,
        if (petProfileId != null && petProfileId.isNotEmpty) 'petProfileId': petProfileId,
        if (currentProduct != null)
          'currentProduct': {
            'id': currentProduct.id,
            if (currentProduct.slug.isNotEmpty) 'slug': currentProduct.slug,
            'name': currentProduct.name,
            'price': currentProduct.price,
            if (currentProduct.brand != null && currentProduct.brand!.isNotEmpty)
              'brand': currentProduct.brand,
            if (currentProduct.category != null && currentProduct.category!.isNotEmpty)
              'category': currentProduct.category,
            if (currentProduct.composition != null && currentProduct.composition!.isNotEmpty)
              'composition': currentProduct.composition,
            'animalTypes': currentProduct.animalTypes,
            if (currentProduct.description != null && currentProduct.description!.isNotEmpty)
              'description': currentProduct.description,
            'requiresPrescription': currentProduct.requiresPrescription,
          },
        if (history != null && history.isNotEmpty) 'history': history,
      };

      dynamic data;
      try {
        data = await _client.post('/pet-care/vet-coach', data: payload);
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) {
          // Fallback to legacy endpoint if available
          data = await _client.post('/ai/ask', data: payload);
        } else {
          rethrow;
        }
      }

      final map = Map<String, dynamic>.from(data as Map);

      // Check if response matches vet-coach contract
      if (map.containsKey('reply') && map['reply'] is Map) {
        final reply = Map<String, dynamic>.from(map['reply'] as Map);
        final headline = (reply['headline'] as String?)?.trim() ?? '';
        final summary = (reply['summary'] as String?)?.trim() ?? '';
        final steps = (reply['steps'] as List?)
                ?.map((s) => s.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];
        final caution = (reply['caution'] as String?)?.trim() ?? '';

        final buffer = StringBuffer();
        if (headline.isNotEmpty) {
          buffer.writeln('**$headline**\n');
        }
        if (summary.isNotEmpty) {
          buffer.writeln(summary);
        }
        if (steps.isNotEmpty) {
          buffer.writeln('\n**Key Steps:**');
          for (int i = 0; i < steps.length; i++) {
            buffer.writeln('${i + 1}. ${steps[i]}');
          }
        }
        if (caution.isNotEmpty) {
          buffer.writeln('\n> ⚠️ **Note:** $caution');
        }

        final followUpChoices = (reply['followUpChoices'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];

        final matchedProducts = (map['matchedProducts'] as List?)
                ?.map((p) => (p is Map) ? p['id']?.toString() : null)
                .whereType<String>()
                .toList() ??
            const <String>[];

        return ChatMessage(
          role: 'assistant',
          content: buffer.toString().trim(),
          productIds: matchedProducts,
          suggestedQuestions: followUpChoices,
        );
      }

      return ChatMessage.fromJson(map);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) {
        throw ApiException(
            'Dr. Paw is resting right now. Please try again in a few minutes.');
      }
      rethrow;
    }
  }

  Future<List<Product>> findAlternativesByText(String query) async {
    final data = await _client.get('/alternatives/search', query: {'query': query});
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Product>> findAlternativesByImage(String imageUrl) async {
    final data = await _client.post('/alternatives/match', data: {'imageUrl': imageUrl});
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }
}
