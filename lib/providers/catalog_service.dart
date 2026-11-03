import '../core/network/api_client.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_facets.dart';

class CatalogService {
  CatalogService(this._client);
  final ApiClient _client;

  final Map<String, (DateTime, List<Product>)> _productsCache = {};

  void invalidateCache() {
    _productsCache.clear();
  }

  Future<List<Product>> fetchProducts({
    String? category,
    String? subCategory,
    String? animalType,
    String? disease,
    String? search,
    String? sort,
    int? limit,
    String? relatedTo,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '$category|$subCategory|$animalType|$disease|$search|$sort|$limit|$relatedTo';
    if (!forceRefresh) {
      final hit = _productsCache[cacheKey];
      if (hit != null && DateTime.now().difference(hit.$1).inMinutes < 5) {
        return hit.$2;
      }
    }
    final data = await _client.get(
      '/products',
      query: {
        'category': ?category,
        'subCategory': ?subCategory,
        'animalType': ?animalType,
        'disease': ?disease,
        if (search != null && search.isNotEmpty) 'search': search,
        'sort': ?sort,
        'limit': ?limit,
        'relatedTo': ?relatedTo,
      },
    );
    final products = (data as List).map((e) => Product.fromJson(e)).toList();
    _productsCache[cacheKey] = (DateTime.now(), products);
    return products;
  }

  Future<Product> fetchProduct(String idOrSlug) async {
    final data = await _client.get('/products/$idOrSlug');
    return Product.fromJson(data);
  }

  /// Mirrors `saveStockAlert` (lib/products-client.ts): POST
  /// /api/products/:id/stock-alert. Requires login — 401 opens login.
  Future<void> saveStockAlert(String productId) async {
    await _client.post('/products/$productId/stock-alert');
  }

  /// Mirrors `useSearchSuggestions` (hooks/nav): GET
  /// /api/search/suggestions?q= (min 2 chars) → `{ suggestions: [...] }`.
  /// Returns [] on any error, exactly like the website.
  Future<List<SearchSuggestion>> fetchSuggestions(String query) async {
    if (query.trim().length < 2) return const [];
    try {
      final data = await _client.get(
        '/search/suggestions',
        query: {'q': query.trim()},
      );
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final inner = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'])
          : map;
      final list = inner['suggestions'] as List?;
      if (list == null) return const [];
      return list
          .map(
            (e) =>
                SearchSuggestion.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Product>> fetchProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final data = await _client.get('/products', query: {'ids': ids.join(',')});
    return (data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<ProductCategory>> fetchCategories({bool all = false}) async {
    try {
      final data = await _client.get(
        '/categories',
        query: all ? {'all': 'true'} : null,
      );
      if (data is List) {
        return data
            .map(
              (e) =>
                  ProductCategory.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .where((c) => all || c.active)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Brand>> fetchBrands() async {
    final data = await _client.get('/brands', query: {'all': 'true'});
    return (data as List).map((e) => Brand.fromJson(e)).toList();
  }

  Future<List<HealthConcern>> fetchHealthConcerns() async {
    final data = await _client.get('/health-concerns');
    return (data as List).map((e) => HealthConcern.fromJson(e)).toList();
  }

  Future<List<ComboBundle>> fetchCombos() async {
    try {
      final data = await _client.get('/combos');
      if (data is List) {
        return data
            .map(
              (e) => ComboBundle.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .where((c) => c.isActive && c.items.isNotEmpty)
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<ComboBundle?> fetchCombo(String id) async {
    try {
      final data = await _client.get('/combos', query: {'id': id});
      if (data is Map) {
        return ComboBundle.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ProductFacets> fetchFacets({
    String? category,
    String? animalType,
    String? search,
    String? disease,
  }) async {
    final data = await _client.get(
      '/products/facets',
      query: {
        'category': ?category,
        'animalType': ?animalType,
        if (search != null && search.isNotEmpty) 'search': search,
        'disease': ?disease,
      },
    );
    return ProductFacets.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
