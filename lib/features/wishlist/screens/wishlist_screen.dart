import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

final wishlistProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final ids = ref.watch(wishlistProvider).value ?? {};
  if (ids.isEmpty) return [];
  return ref.read(catalogServiceProvider).fetchProductsByIds(ids.toList());
});

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(wishlistProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Saved Items',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: productsAsync.when(
          data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'No saved items yet',
                  description:
                      'Tap the heart icon on any veterinary product, feed or care combo to save it here for later.',
                  actionLabel: 'Browse Catalogue',
                  onAction: () => context.go('/products'),
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(wishlistProductsProvider);
              await ref.read(wishlistProductsProvider.future);
            },
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: productCardExtent(context),
              ),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return CompactProductCard(
                  product: p,
                  variant: CompactCardVariant.catalogue,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: AppLoader.large()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load wishlist',
              description: e.toString(),
              actionLabel: 'Try Again',
              onAction: () => ref.invalidate(wishlistProductsProvider),
            ),
          ),
        ),
      ),
    ),
  );
}
}
