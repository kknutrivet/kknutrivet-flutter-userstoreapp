import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../core/widgets/product_image_cover.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

/// Provider fetching animal-matched essentials/impulse add-ons (Feed, Grooming, Device, Home Care).
/// Matches `selectCartImpulseAddons` in `src/lib/cart-impulse-addons.ts`.
final cartImpulseAddonsProvider =
    FutureProvider.autoDispose.family<List<Product>, double>((ref, amountForFreeDelivery) async {
  final cart = ref.watch(cartProvider).valueOrNull ?? const [];
  if (cart.isEmpty) return const [];

  final inCartIds = cart.map((i) => i.productId).toSet();
  final animalTypes = cart
      .expand((i) => i.product?.animalTypes ?? const <String>[])
      .map((a) => a.trim())
      .where((a) => a.isNotEmpty)
      .toSet()
      .toList();

  final catalogService = ref.read(catalogServiceProvider);
  final List<Product> rawProducts = [];

  if (animalTypes.isNotEmpty) {
    final futures = animalTypes.map(
      (animal) => catalogService.fetchProducts(
        animalType: animal,
        category: 'Feed,Grooming,Device,Home Care',
        limit: 30,
      ),
    );
    final results = await Future.wait(futures);
    for (final list in results) {
      rawProducts.addAll(list);
    }
  }

  // Fallback to general essentials if no animal tags or no animal-specific items found
  if (rawProducts.isEmpty) {
    final fallback = await catalogService.fetchProducts(
      category: 'Feed,Grooming,Device,Home Care',
      limit: 30,
    );
    rawProducts.addAll(fallback);
  }

  final seen = <String>{};
  final suitable = <Product>[];

  for (final product in rawProducts) {
    if (seen.contains(product.id) || inCartIds.contains(product.id)) continue;
    if (product.stock <= 0) continue;
    if (product.requiresPrescription == true) continue;
    if (product.onlyForCombo == true) continue;
    // Keep impulse add-ons instant without complex pack selection
    if (product.variants.isNotEmpty) continue;

    final price = product.effectivePrice;
    if (price <= 0) continue;
    final minQty = product.minimumQuantity;
    if (product.stock < minQty) continue;

    seen.add(product.id);
    suitable.add(product);
  }

  // Rank: if there is a gap to free delivery, prioritize items that close the gap first, then sort by price
  suitable.sort((a, b) {
    final aTotal = a.effectivePrice * a.minimumQuantity;
    final bTotal = b.effectivePrice * b.minimumQuantity;
    if (amountForFreeDelivery > 0) {
      final aClosesGap = aTotal >= amountForFreeDelivery;
      final bClosesGap = bTotal >= amountForFreeDelivery;
      if (aClosesGap != bClosesGap) {
        return aClosesGap ? -1 : 1;
      }
    }
    return aTotal.compareTo(bTotal);
  });

  return suitable.take(8).toList();
});

/// "Useful extras for your animal" section matching `src/components/cart/CartImpulseAddons.tsx`.
class CartImpulseAddonsSection extends ConsumerStatefulWidget {
  const CartImpulseAddonsSection({
    super.key,
    required this.amountForFreeDelivery,
    required this.qualifiesForFreeDelivery,
  });

  final double amountForFreeDelivery;
  final bool qualifiesForFreeDelivery;

  @override
  ConsumerState<CartImpulseAddonsSection> createState() =>
      _CartImpulseAddonsSectionState();
}

class _CartImpulseAddonsSectionState
    extends ConsumerState<CartImpulseAddonsSection> {
  String? _addingId;

  Future<void> _quickAdd(Product product) async {
    if (_addingId != null) return;
    setState(() => _addingId = product.id);
    try {
      Haptics.tap();
      final minQty = product.minimumQuantity;
      await ref.read(cartProvider.notifier).addItem(
            productId: product.id,
            quantity: minQty,
            product: product,
          );
      showToast('Added "${product.name}" to cart!');
    } catch (e) {
      showToast('Could not add item to cart: $e', isError: true);
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addonsAsync =
        ref.watch(cartImpulseAddonsProvider(widget.amountForFreeDelivery));

    return addonsAsync.maybeWhen(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();

        final hasDeliveryGap =
            widget.amountForFreeDelivery > 0 && !widget.qualifiesForFreeDelivery;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD7E5DD)),
            gradient: const LinearGradient(
              colors: [Color(0xFFF4F9F6), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D173C32),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Useful extras for your animal',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasDeliveryGap
                              ? 'Add ₹${widget.amountForFreeDelivery.ceil()} more for free delivery. Extras matched to your animal.'
                              : 'Food, grooming and accessories matched to your cart',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 122,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final minQty = product.minimumQuantity;
                    final price = product.effectivePrice * minQty;
                    final mrp = product.mrp != null ? product.mrp! * minQty : null;
                    final isAdding = _addingId == product.id;
                    final packLabel = product.size;

                    return Container(
                      width: 216,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCE8E0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/products/${product.id}'),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: ProductImageCover(
                                    imageUrl: product.image,
                                    borderRadius: BorderRadius.circular(8),
                                    innerPadding: const EdgeInsets.all(2),
                                    showPlaceholderOnLoading: false,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          height: 1.2,
                                        ),
                                      ),
                                      if (packLabel != null &&
                                          packLabel.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Pack: $packLabel',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Color(0xFFF1F5F3),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${formatInr(price)}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDeepest,
                                      ),
                                    ),
                                    if (mrp != null && mrp > price) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '₹${formatInr(mrp)}',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          color: AppColors.mrp,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(
                                  height: 28,
                                  child: FilledButton(
                                    onPressed: _addingId != null
                                        ? null
                                        : () => _quickAdd(product),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryDeep,
                                      minimumSize: const Size(54, 28),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(7),
                                      ),
                                    ),
                                    child: isAdding
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.add,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                'Add${minQty > 1 ? " $minQty" : ""}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
