import 'product.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    this.comboId,
    this.comboPrice,
    this.comboName,
    this.comboImage,
    this.comboDescription,
    this.comboQuantity,
    this.product,
    this.variant,
  });

  final String id;
  final String productId;
  final String? variantId;
  final int quantity;
  final String? comboId;
  final double? comboPrice;
  final String? comboName;
  final String? comboImage;
  final String? comboDescription;
  final int? comboQuantity;
  final Product? product;
  final ProductVariant? variant;

  double get unitPrice => comboPrice ?? variant?.price ?? product?.effectivePrice ?? 0;
  double get lineTotal => unitPrice * quantity;

  /// Dynamic server-driven minimum quantity requirement for this product / variant.
  int get minimumQuantity =>
      variant?.minimumQuantity ?? product?.minimumQuantity ?? 1;

  /// Maximum available stock limit if provided by backend catalog.
  int get maxStock {
    final vStock = variant?.stock;
    if (vStock != null && vStock > 0) return vStock;
    final pStock = product?.stock;
    if (pStock != null && pStock > 0) return pStock;
    return 999;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'].toString(),
        productId: json['productId']?.toString() ?? '',
        variantId: json['variantId']?.toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        comboId: json['comboId']?.toString(),
        comboPrice: (json['comboPrice'] as num?)?.toDouble(),
        comboName: json['comboName']?.toString(),
        comboImage: json['comboImage']?.toString() ?? (json['combo'] is Map ? json['combo']['image']?.toString() : null),
        comboDescription: json['comboDescription']?.toString(),
        comboQuantity: (json['comboQuantity'] as num?)?.toInt(),
        product: json['product'] != null ? Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)) : null,
        variant: json['variant'] != null ? ProductVariant.fromJson(Map<String, dynamic>.from(json['variant'] as Map)) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        if (variantId != null) 'variantId': variantId,
        'quantity': quantity,
        if (comboId != null) 'comboId': comboId,
        if (comboPrice != null) 'comboPrice': comboPrice,
        if (comboName != null) 'comboName': comboName,
        if (comboImage != null) 'comboImage': comboImage,
        if (comboDescription != null) 'comboDescription': comboDescription,
        if (comboQuantity != null) 'comboQuantity': comboQuantity,
        if (product != null) 'product': product!.toJson(),
        if (variant != null) 'variant': variant!.toJson(),
      };
}
