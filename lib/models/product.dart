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
    this.brand,
    this.size,
    this.flavor,
    this.requiresPrescription = false,
    this.onlyForCombo = false,
    this.minimumQuantity = 1,
    this.stock = 0,
    this.offerPrice,
    this.offerLabel,
    this.variants = const [],
    this.quantityDiscounts = const [],
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
  final String? brand;
  final String? size;
  final String? flavor;
  final bool requiresPrescription;
  final bool onlyForCombo;
  final int minimumQuantity;
  final int stock;
  final double? offerPrice;
  final String? offerLabel;
  final List<ProductVariant> variants;
  final List<QuantityDiscountTier> quantityDiscounts;

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
        brand: json['brand']?.toString(),
        size: json['size']?.toString(),
        flavor: json['flavor']?.toString(),
        requiresPrescription: json['requiresPrescription'] == true,
        onlyForCombo: json['onlyForCombo'] == true,
        minimumQuantity: ((json['minimumQuantity'] as num?)?.toInt() ?? 1).clamp(1, 999),
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        offerPrice: (json['offerPrice'] as num?)?.toDouble(),
        offerLabel: json['offerLabel']?.toString(),
        variants: (json['variants'] as List?)
                ?.map((e) => ProductVariant.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        quantityDiscounts: (json['quantityDiscounts'] as List?)
                ?.map((e) => QuantityDiscountTier.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );

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
        if (flavor != null) 'flavor': flavor,
        'requiresPrescription': requiresPrescription,
        'onlyForCombo': onlyForCombo,
        'minimumQuantity': minimumQuantity,
        'stock': stock,
        if (offerPrice != null) 'offerPrice': offerPrice,
        if (offerLabel != null) 'offerLabel': offerLabel,
        'variants': variants.map((v) => v.toJson()).toList(),
        'quantityDiscounts': quantityDiscounts.map((q) => q.toJson()).toList(),
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
/// `{ id, slug, name, brand, category, image }`.
class SearchSuggestion {
  SearchSuggestion({
    required this.id,
    this.slug,
    required this.name,
    this.brand,
    required this.category,
    this.image,
  });

  final String id;
  final String? slug;
  final String name;
  final String? brand;
  final String category;
  final String? image;

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
      );
}
