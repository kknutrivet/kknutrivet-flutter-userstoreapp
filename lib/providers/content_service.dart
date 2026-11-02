import '../core/network/api_client.dart';
import '../models/content.dart';
import '../models/homepage_section.dart';

const _kFallbackShotVideos = [
  'https://kknutrivet-595949105490-ap-south-2-an.s3.ap-south-2.amazonaws.com/uploads/1793095623607-8joq29.mp4',
  'https://pub-c9240f8ca001415a88638f717e7dba45.r2.dev/marketing-videos/1793106781901-livol-demo.mp4',
  'https://pub-c9240f8ca001415a88638f717e7dba45.r2.dev/ugc-pet-stars/1793117350575-0j2gz21.mp4',
];

String _sanitizeShotVideoUrl(String? raw, int index) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.contains('commondatastorage.googleapis.com')) {
    return _kFallbackShotVideos[index % _kFallbackShotVideos.length];
  }
  return trimmed;
}

class ContentService {
  ContentService(this._client);
  final ApiClient _client;

  Future<List<BlogPost>> fetchBlogPosts({String? category, String? search, int page = 1}) async {
    final data = await _client.get('/blog', query: {
      'status': 'PUBLISHED',
      'category': ?category,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': 20,
    });
    return (data['posts'] as List).map((e) => BlogPost.fromJson(e)).toList();
  }

  Future<BlogPost> fetchBlogPost(String slug) async {
    final data = await _client.get('/blog', query: {'slug': slug});
    return BlogPost.fromJson(data);
  }

  Future<List<VetInsight>> fetchVetInsights({String? category, bool? featured}) async {
    final data = await _client.get('/vet-insights', query: {
      'category': ?category,
      if (featured == true) 'featured': 'true',
    });
    return (data as List).map((e) => VetInsight.fromJson(e)).toList();
  }

  List<ShotItem> _parseShotsList(List raw) {
    final items = <ShotItem>[];
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is Map<String, dynamic>) {
        final copy = Map<String, dynamic>.from(entry);
        copy['videoUrl'] = _sanitizeShotVideoUrl(copy['videoUrl']?.toString(), i);
        items.add(ShotItem.fromJson(copy));
      }
    }
    return items;
  }

  Future<List<ShotItem>> fetchShots() async {
    try {
      final data = await _client.get('/shots');
      if (data is Map && data['shots'] is List) {
        final list = _parseShotsList(data['shots'] as List);
        if (list.isNotEmpty) return list;
      } else if (data is List) {
        final list = _parseShotsList(data);
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Primary /api/shots unavailable or empty; fall back to /products
    }

    try {
      final data = await _client.get('/products', query: {'limit': 8});
      final rawList = data is Map && data['products'] is List
          ? data['products'] as List
          : (data is List ? data : const []);
      final items = <ShotItem>[];
      for (var i = 0; i < rawList.length; i++) {
        final p = rawList[i];
        if (p is! Map<String, dynamic>) continue;
        items.add(
          ShotItem(
            id: p['id']?.toString() ?? '',
            productId: p['id']?.toString(),
            name: p['name']?.toString() ?? '',
            slug: p['slug']?.toString(),
            description: p['description']?.toString(),
            price: (p['price'] as num?)?.toDouble() ?? 0.0,
            mrp: (p['mrp'] as num?)?.toDouble(),
            offerPrice: (p['offerPrice'] as num?)?.toDouble(),
            image: p['image']?.toString() ??
                ((p['images'] is List && (p['images'] as List).isNotEmpty)
                    ? (p['images'] as List).first.toString()
                    : ''),
            category: p['category']?.toString() ?? 'Essentials',
            brand: p['brand']?.toString() ?? 'KK Nutrivet',
            videoUrl: _sanitizeShotVideoUrl(p['videoUrl']?.toString(), i),
            videoViews: (p['videoViews'] as num?)?.toInt() ?? 17,
            videoLikes: (p['videoLikes'] as num?)?.toInt() ?? 12,
            animalTypes: (p['animalTypes'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
          ),
        );
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<List<HomepageSection>> fetchHomepageSections() async {
    try {
      final data = await _client.get('/homepage-sections');
      if (data is Map && data['sections'] is List) {
        return (data['sections'] as List)
            .whereType<Map<String, dynamic>>()
            .map((s) => HomepageSection.fromJson(s))
            .toList();
      } else if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((s) => HomepageSection.fromJson(s))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
