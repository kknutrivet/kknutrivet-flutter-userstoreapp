class BlogPost {
  BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.content,
    this.excerpt,
    this.coverImage,
    this.category,
    this.publishedAt,
    this.authorName,
  });

  final String id;
  final String title;
  final String slug;
  final String? content;
  final String? excerpt;
  final String? coverImage;
  final String? category;
  final DateTime? publishedAt;
  final String? authorName;

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        slug: json['slug'] ?? '',
        content: json['content'],
        excerpt: json['excerpt'],
        coverImage: json['coverImage'],
        category: json['category'],
        publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
        authorName: json['author']?['name'],
      );
}

class VetInsight {
  VetInsight({
    required this.id,
    required this.slug,
    required this.title,
    this.excerpt,
    this.category,
    this.vetName,
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String? excerpt;
  final String? category;
  final String? vetName;
  final DateTime? publishedAt;

  factory VetInsight.fromJson(Map<String, dynamic> json) => VetInsight(
        id: json['id'].toString(),
        slug: json['slug'] ?? '',
        title: json['title'] ?? '',
        excerpt: json['excerpt'],
        category: json['category'],
        vetName: json['vet']?['user']?['name'],
        publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
      );
}

class ShotItem {
  ShotItem({
    required this.id,
    this.productId,
    required this.name,
    this.slug,
    this.description,
    required this.price,
    this.mrp,
    this.offerPrice,
    required this.image,
    required this.category,
    this.brand,
    required this.videoUrl,
    this.videoViews = 0,
    this.videoLikes = 0,
    this.isMarketing = false,
    this.badge,
    this.ctaLabel = 'Add',
    this.ctaLink,
    this.animalTypes = const [],
  });

  final String id;
  final String? productId;
  final String name;
  final String? slug;
  final String? description;
  final double price;
  final double? mrp;
  final double? offerPrice;
  final String image;
  final String category;
  final String? brand;
  final String videoUrl;
  final int videoViews;
  final int videoLikes;
  final bool isMarketing;
  final String? badge;
  final String ctaLabel;
  final String? ctaLink;
  final List<String> animalTypes;

  double get effectivePrice => offerPrice ?? price;

  int get discountPercent {
    final m = mrp;
    final p = effectivePrice;
    if (m != null && m > p && p > 0) {
      return (((m - p) / m) * 100).round();
    }
    return 0;
  }

  bool get hasVideo => videoUrl.trim().isNotEmpty;

  int get viewsCount => videoViews;

  factory ShotItem.fromJson(Map<String, dynamic> json) => ShotItem(
        id: json['id']?.toString() ?? '',
        productId: json['productId']?.toString(),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString(),
        description: json['description']?.toString(),
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        mrp: (json['mrp'] as num?)?.toDouble(),
        offerPrice: (json['offerPrice'] as num?)?.toDouble(),
        image: json['image']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Essentials',
        brand: json['brand']?.toString(),
        videoUrl: json['videoUrl']?.toString() ?? '',
        videoViews: (json['videoViews'] as num?)?.toInt() ?? 0,
        videoLikes: (json['videoLikes'] as num?)?.toInt() ?? 0,
        isMarketing: json['isMarketing'] == true,
        badge: json['badge']?.toString(),
        ctaLabel: json['ctaLabel']?.toString() ?? 'Add',
        ctaLink: json['ctaLink']?.toString(),
        animalTypes: (json['animalTypes'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
