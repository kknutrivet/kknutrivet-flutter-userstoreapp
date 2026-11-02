/// Mirrors GET /api/products/facets — per-dimension counts computed with
/// every other active filter applied, so picking one facet doesn't zero out
/// the others (standard faceted search).
class ProductFacets {
  ProductFacets({
    required this.animalTypeCounts,
    required this.categoryCounts,
    required this.brandCounts,
    this.diseaseOptions = const [],
  });

  final Map<String, int> animalTypeCounts;
  final Map<String, int> categoryCounts;
  final Map<String, int> brandCounts;
  final List<DiseaseOption> diseaseOptions;

  factory ProductFacets.fromJson(Map<String, dynamic> json) => ProductFacets(
        animalTypeCounts: (json['animalTypeCounts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
        categoryCounts: (json['categoryCounts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
        brandCounts: (json['brandCounts'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
        diseaseOptions: (json['diseaseOptions'] as List?)
                ?.map((e) => DiseaseOption.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

/// Mirrors the `{ name, slug, count }` entries of `diseaseOptions` in
/// `computeProductFacets` (lib/product-service.ts on the website).
class DiseaseOption {
  DiseaseOption({required this.name, required this.slug, required this.count});

  final String name;
  final String slug;
  final int count;

  factory DiseaseOption.fromJson(Map<String, dynamic> json) => DiseaseOption(
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
