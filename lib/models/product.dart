import 'package:intl/intl.dart';

class QuantityDiscountTier {
  const QuantityDiscountTier({
    required this.minQuantity,
    required this.discountPercent,
    this.unitPrice,
  });

  final int minQuantity;
  final double discountPercent;
  final double? unitPrice;

  factory QuantityDiscountTier.fromJson(Map<String, dynamic> json) =>
      QuantityDiscountTier(
        minQuantity: (json['minQuantity'] as num?)?.toInt() ??
            (json['quantity'] as num?)?.toInt() ??
            1,
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ??
            (json['discount'] as num?)?.toDouble() ??
            0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ??
            (json['price'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'minQuantity': minQuantity,
        'discountPercent': discountPercent,
        if (unitPrice != null) 'unitPrice': unitPrice,
      };
}

class ProductVariant {
  ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    this.mrp,
    this.stock = 0,
    this.isActive = true,
    this.minimumQuantity = 1,
  });

  final String id;
  final String name;
  final double price;
  final double? mrp;
  final int stock;
  final bool isActive;
  final int minimumQuantity;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        mrp: (json['mrp'] as num?)?.toDouble(),
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] ?? true,
        minimumQuantity: ((json['minimumQuantity'] as num?)?.toInt() ?? 1).clamp(1, 999),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        if (mrp != null) 'mrp': mrp,
        'stock': stock,
        'isActive': isActive,
        'minimumQuantity': minimumQuantity,
      };
}

class ProductTranslation {
  const ProductTranslation({this.name, this.description});

  final String? name;
  final String? description;

  factory ProductTranslation.fromJson(Map<String, dynamic> json) =>
      ProductTranslation(
        name: json['name']?.toString().trim().isNotEmpty == true
            ? json['name'].toString().trim()
            : null,
        description: json['description']?.toString().trim().isNotEmpty == true
            ? json['description'].toString().trim()
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      };
}

class ProductHighlightBadge {
  const ProductHighlightBadge({required this.label, required this.tone});

  final String label;
  final String tone; // 'fire' | 'views' | 'farmer' | 'pet' | 'vet' | 'new'

  factory ProductHighlightBadge.fromJson(Map<String, dynamic> json) =>
      ProductHighlightBadge(
        label: json['label']?.toString() ?? '',
        tone: json['tone']?.toString() ?? 'farmer',
      );

  Map<String, dynamic> toJson() => {'label': label, 'tone': tone};
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.composition,
    required this.price,
    this.mrp,
    this.image,
    this.images = const [],
    this.category,
    this.subCategory,
    this.animalTypes = const [],
    this.diseases = const [],
    this.tags = const [],
    this.brand,
    this.size,
    this.weight,
    this.flavor,
    this.requiresPrescription = false,
    this.onlyForCombo = false,
    this.minimumQuantity = 1,
    this.stock = 0,
    this.offerPrice,
    this.offerLabel,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.viewCount = 0,
    this.highlightBadge,
    this.variants = const [],
    this.quantityDiscounts = const [],
    this.translations = const {},
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? composition;
  final double price;
  final double? mrp;
  final String? image;
  final List<String> images;
  final String? category;
  final String? subCategory;
  final List<String> animalTypes;
  final List<String> diseases;
  final List<String> tags;
  final String? brand;
  final String? size;
  final String? weight;
  final String? flavor;

  /// Base pack label combining `size` and `weight` (exact parity with
  /// `VariantPickerDialog.tsx` on web, e.g. `"5 L"`).
  String get basePackLabel {
    final parts = [
      if (size != null && size!.trim().isNotEmpty) size!.trim(),
      if (weight != null && weight!.trim().isNotEmpty) weight!.trim(),
    ];
    return parts.join(' / ');
  }
  final bool requiresPrescription;
  final bool onlyForCombo;
  final int minimumQuantity;
  final int stock;
  final double? offerPrice;
  final String? offerLabel;
  final double ratingAverage;
  final int ratingCount;
  final int viewCount;
  final ProductHighlightBadge? highlightBadge;
  final List<ProductVariant> variants;
  final List<QuantityDiscountTier> quantityDiscounts;
  final Map<String, ProductTranslation> translations;

  static const Map<String, ProductHighlightBadge> _manualTagBadges = {
    'bestseller': ProductHighlightBadge(label: '🔥 Best Seller', tone: 'fire'),
    'best-seller': ProductHighlightBadge(label: '🔥 Best Seller', tone: 'fire'),
    'best seller': ProductHighlightBadge(label: '🔥 Best Seller', tone: 'fire'),
    'trending': ProductHighlightBadge(label: '🔥 Trending Now', tone: 'fire'),
    'trending-now': ProductHighlightBadge(label: '🔥 Trending Now', tone: 'fire'),
    'most-viewed': ProductHighlightBadge(label: '👀 Most Viewed', tone: 'views'),
    'most-view': ProductHighlightBadge(label: '👀 Most Viewed', tone: 'views'),
    'most viewed': ProductHighlightBadge(label: '👀 Most Viewed', tone: 'views'),
    'farmers-choice': ProductHighlightBadge(label: "🌾 Farmer's Choice", tone: 'farmer'),
    'farmer-choice': ProductHighlightBadge(label: "🌾 Farmer's Choice", tone: 'farmer'),
    "farmer's choice": ProductHighlightBadge(label: "🌾 Farmer's Choice", tone: 'farmer'),
    'pet-pick': ProductHighlightBadge(label: "🐾 Pet Parent's Pick", tone: 'pet'),
    'pet-parents-pick': ProductHighlightBadge(label: "🐾 Pet Parent's Pick", tone: 'pet'),
    "pet parent's pick": ProductHighlightBadge(label: "🐾 Pet Parent's Pick", tone: 'pet'),
    'vet-pick': ProductHighlightBadge(label: '🩺 Vet Pick', tone: 'vet'),
    'vet-recommended': ProductHighlightBadge(label: '🩺 Vet Recommended', tone: 'vet'),
    'new': ProductHighlightBadge(label: '✨ New Arrival', tone: 'new'),
    'new-arrival': ProductHighlightBadge(label: '✨ New Arrival', tone: 'new'),
  };

  /// Matches `resolveHighlightBadge` in `src/lib/product-highlights.ts`.
  ProductHighlightBadge? get resolvedHighlightBadge {
    if (highlightBadge != null && highlightBadge!.label.isNotEmpty) {
      return highlightBadge;
    }
    for (final raw in tags) {
      final badge = _manualTagBadges[raw.trim().toLowerCase()];
      if (badge != null) return badge;
    }
    if (ratingAverage >= 4.5 && ratingCount >= 2) {
      final isLivestock = animalTypes.any(
        (a) => RegExp(
          r'cattle|cow|buffalo|goat|sheep|poultry|broiler|layer',
          caseSensitive: false,
        ).hasMatch(a),
      );
      if (isLivestock) {
        return const ProductHighlightBadge(
          label: "🌾 Farmer's Choice",
          tone: 'farmer',
        );
      }
      final isPet = animalTypes.any(
        (a) => RegExp(r'dog|puppy|cat|kitten', caseSensitive: false).hasMatch(a),
      );
      if (isPet) {
        return const ProductHighlightBadge(
          label: "🐾 Pet Parent's Pick",
          tone: 'pet',
        );
      }
      return const ProductHighlightBadge(label: '⭐ Top Rated', tone: 'farmer');
    }
    if (viewCount >= 18) {
      return const ProductHighlightBadge(
        label: '👀 Most Viewed',
        tone: 'views',
      );
    }
    return null;
  }

  /// Returns the localized product name for [localeCode] (e.g. `'hi'`, `'or'`, `'te'`, `'ta'`),
  /// falling back to the canonical English [name].
  String localizedName(String localeCode) {
    if (localeCode == 'en') return name;
    return translations[localeCode]?.name ?? name;
  }

  /// Returns the localized product description for [localeCode], falling back to [description].
  String? localizedDescription(String localeCode) {
    if (localeCode == 'en') return description;
    return translations[localeCode]?.description ?? description;
  }

  String get formattedViewsLabel => viewCount >= 10
      ? NumberFormat.decimalPattern('en_IN').format(viewCount)
      : '10+';

  double get effectivePrice => offerPrice ?? price;
  bool get inStock => stock > 0 || variants.any((v) => v.stock > 0);
  bool get hasDiscount => mrp != null && mrp! > effectivePrice;
  int get discountPercent =>
      hasDiscount ? (((mrp! - effectivePrice) / mrp!) * 100).round() : 0;

  int minQtyFor([ProductVariant? variant]) {
    final vMin = variant?.minimumQuantity ?? 1;
    return vMin > 1 ? vMin : (minimumQuantity > 1 ? minimumQuantity : 1);
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        slug: json['slug'] ?? json['id'].toString(),
        description: json['description']?.toString(),
        composition: json['composition']?.toString(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        mrp: (json['mrp'] as num?)?.toDouble(),
        image: json['image']?.toString(),
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        category: json['category']?.toString(),
        subCategory: json['subCategory']?.toString(),
        animalTypes:
            (json['animalTypes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        diseases: (json['diseases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        brand: json['brand']?.toString(),
        size: json['size']?.toString(),
        weight: json['weight']?.toString(),
        flavor: json['flavor']?.toString(),
        requiresPrescription: json['requiresPrescription'] == true,
        onlyForCombo: json['onlyForCombo'] == true,
        minimumQuantity: ((json['minimumQuantity'] as num?)?.toInt() ?? 1).clamp(1, 999),
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        offerPrice: (json['offerPrice'] as num?)?.toDouble(),
        offerLabel: json['offerLabel']?.toString(),
        ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        viewCount:
            (json['viewCount'] as num?)?.toInt() ??
            (json['views'] as num?)?.toInt() ??
            0,
        highlightBadge: json['highlightBadge'] is Map
            ? ProductHighlightBadge.fromJson(
                Map<String, dynamic>.from(json['highlightBadge'] as Map),
              )
            : null,
        variants: (json['variants'] as List?)
                ?.map((e) => ProductVariant.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        quantityDiscounts: (json['quantityDiscounts'] as List?)
                ?.map((e) => QuantityDiscountTier.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        translations: _parseTranslations(json['translations']),
      );

  static Map<String, ProductTranslation> _parseTranslations(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <String, ProductTranslation>{};
    raw.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] =
            ProductTranslation.fromJson(Map<String, dynamic>.from(value));
      }
    });
    return result;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        if (description != null) 'description': description,
        if (composition != null) 'composition': composition,
        'price': price,
        if (mrp != null) 'mrp': mrp,
        if (image != null) 'image': image,
        'images': images,
        if (category != null) 'category': category,
        if (subCategory != null) 'subCategory': subCategory,
        'animalTypes': animalTypes,
        'diseases': diseases,
        if (brand != null) 'brand': brand,
        if (size != null) 'size': size,
        if (weight != null) 'weight': weight,
        if (flavor != null) 'flavor': flavor,
        'requiresPrescription': requiresPrescription,
        'onlyForCombo': onlyForCombo,
        'minimumQuantity': minimumQuantity,
        'stock': stock,
        if (offerPrice != null) 'offerPrice': offerPrice,
        if (offerLabel != null) 'offerLabel': offerLabel,
        'ratingAverage': ratingAverage,
        'ratingCount': ratingCount,
        'viewCount': viewCount,
        'variants': variants.map((v) => v.toJson()).toList(),
        'quantityDiscounts': quantityDiscounts.map((q) => q.toJson()).toList(),
        if (translations.isNotEmpty)
          'translations':
              translations.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class ComboItem {
  const ComboItem({
    required this.id,
    required this.productId,
    required this.quantity,
    this.variantId,
    this.product,
  });

  final String id;
  final String productId;
  final int quantity;
  final String? variantId;
  final Product? product;

  factory ComboItem.fromJson(Map<String, dynamic> json) {
    final prodMap = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : null;
    return ComboItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? prodMap?['id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variantId: json['variantId']?.toString(),
      product: prodMap != null ? Product.fromJson(prodMap) : null,
    );
  }
}

class ComboBundle {
  const ComboBundle({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.originalPrice,
    required this.comboPrice,
    this.isActive = true,
    this.items = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? image;
  final double originalPrice;
  final double comboPrice;
  final bool isActive;
  final List<ComboItem> items;

  int get savingPercent => originalPrice > comboPrice && originalPrice > 0
      ? ((1 - comboPrice / originalPrice) * 100).round()
      : 0;

  double get savingAmount =>
      (originalPrice - comboPrice).clamp(0, double.infinity);

  bool matchesAnimal(String? animal) {
    if (animal == null || animal.isEmpty) return true;
    final needle = animal.toLowerCase();
    if (name.toLowerCase().contains(needle) ||
        (description?.toLowerCase().contains(needle) ?? false)) {
      return true;
    }
    return items.any(
      (it) => (it.product?.animalTypes ?? const []).any(
        (a) => a.toLowerCase().contains(needle),
      ),
    );
  }

  factory ComboBundle.fromJson(Map<String, dynamic> json) {
    final comboPrice = (json['comboPrice'] is num)
        ? (json['comboPrice'] as num).toDouble()
        : double.tryParse(json['comboPrice']?.toString() ?? '') ?? 0;
    final origPrice = (json['originalPrice'] is num)
        ? (json['originalPrice'] as num).toDouble()
        : double.tryParse(json['originalPrice']?.toString() ?? '') ?? comboPrice;
    return ComboBundle(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      originalPrice: origPrice > 0 ? origPrice : comboPrice,
      comboPrice: comboPrice,
      isActive: json['isActive'] != false,
      items: (json['items'] as List?)
              ?.map((e) => ComboItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}

class Brand {
  Brand({required this.id, required this.name, this.logo});
  final String id;
  final String name;
  final String? logo;

  factory Brand.fromJson(Map<String, dynamic> json) =>
      Brand(id: json['id'].toString(), name: json['name'] ?? '', logo: json['logo']);
}

class HealthConcern {
  HealthConcern({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.icon,
    this.description,
    this.order,
    this.enabled,
  });
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? icon;
  final String? description;
  final int? order;
  final bool? enabled;

  factory HealthConcern.fromJson(Map<String, dynamic> json) => HealthConcern(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        imageUrl: json['imageUrl'],
        icon: json['icon'],
        description: json['description']?.toString(),
        order: json['order'] as int?,
        enabled: json['enabled'] as bool?,
      );
}

/// Mirrors `SearchSuggestion` (hooks/nav/useSearchSuggestions.ts):
/// `{ id, slug, name, brand, category, image, isCombo, price, mrp }`.
class SearchSuggestion {
  SearchSuggestion({
    required this.id,
    this.slug,
    required this.name,
    this.brand,
    required this.category,
    this.image,
    this.isCombo = false,
    this.price,
    this.mrp,
  });

  final String id;
  final String? slug;
  final String name;
  final String? brand;
  final String category;
  final String? image;
  final bool isCombo;
  final double? price;
  final double? mrp;

  /// Detail route this suggestion opens (website links suggestions to
  /// `productHref`, i.e. the canonical slug when present).
  String get targetId =>
      slug?.isNotEmpty == true ? slug! : id;

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) =>
      SearchSuggestion(
        id: json['id'].toString(),
        slug: json['slug']?.toString(),
        name: json['name']?.toString() ?? '',
        brand: json['brand']?.toString(),
        category: json['category']?.toString() ?? '',
        image: json['image']?.toString(),
        isCombo: json['isCombo'] == true,
        price: (json['price'] as num?)?.toDouble(),
        mrp: (json['mrp'] as num?)?.toDouble(),
      );
}
