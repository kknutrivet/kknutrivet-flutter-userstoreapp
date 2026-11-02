/// Represents a category managed in the Admin panel and fetched from `/api/categories`.
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.description,
    this.sortOrder = 0,
    this.active = true,
    this.parentId,
  });

  final String id;
  final String name;
  final String slug;
  final String? image;
  final String? description;
  final int sortOrder;
  final bool active;
  final String? parentId;

  bool get isSubcategory => parentId != null && parentId!.isNotEmpty;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        image: json['image']?.toString(),
        description: json['description']?.toString(),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        active: json['active'] as bool? ?? true,
        parentId: json['parentId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'image': image,
        'description': description,
        'sortOrder': sortOrder,
        'active': active,
        'parentId': parentId,
      };
}
