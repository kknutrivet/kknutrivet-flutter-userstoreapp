import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/compact_product_card.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

final brandsListProvider = FutureProvider.autoDispose<List<Brand>>(
  (ref) => ref.read(catalogServiceProvider).fetchBrands(),
);

final brandProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, String>((ref, brandName) {
      return ref
          .read(catalogServiceProvider)
          .fetchProducts(brand: brandName, limit: 60);
    });

String brandSlugOf(String name) => name
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

/// Dedicated `/brands` screen mirroring `src/app/brands/page.tsx` on mobile web.
class BrandsListScreen extends ConsumerWidget {
  const BrandsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsListProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: const Color(0xFF07583F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Trusted Brands',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: brandsAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'Could not load brands right now.',
          onRetry: () => ref.invalidate(brandsListProvider),
        ),
        data: (brands) {
          if (brands.isEmpty) {
            return const EmptyView(
              message: 'No partner brands available yet.',
              icon: Icons.verified_outlined,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              final name = brand.name.trim().isNotEmpty ? brand.name.trim() : 'Brand';
              final slug = brandSlugOf(name);
              final logo = brand.logo;

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Haptics.tap();
                    context.push(
                      '/brands/$slug?name=${Uri.encodeComponent(name)}',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: logo != null && logo.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: logo,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, _, _) => _brandInitial(name),
                                )
                              : _brandInitial(name),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Shop products →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _brandInitial(String name) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeep,
        ),
      ),
    );
  }
}

/// Dedicated `/brands/:slug` screen mirroring `src/app/brands/[slug]/page.tsx`.
class BrandDetailScreen extends ConsumerWidget {
  const BrandDetailScreen({
    super.key,
    required this.slug,
    this.initialName,
  });

  final String slug;
  final String? initialName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsListProvider);
    final resolvedBrand = brandsAsync.valueOrNull?.where((b) {
      return brandSlugOf(b.name) == slug.toLowerCase();
    }).firstOrNull;

    final brandName =
        resolvedBrand?.name.trim() ??
        initialName ??
        slug
            .split('-')
            .map(
              (w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');

    final productsAsync = ref.watch(brandProductsProvider(brandName));

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: const Color(0xFF07583F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          brandName,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: productsAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'Could not load products for $brandName.',
          onRetry: () => ref.invalidate(brandProductsProvider(brandName)),
        ),
        data: (products) {
          if (products.isEmpty) {
            return EmptyView(
              message: 'No products currently listed for $brandName.',
              icon: Icons.inventory_2_outlined,
              action: ElevatedButton(
                onPressed: () => context.go('/products'),
                child: const Text('Browse all products'),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.62,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => CompactProductCard(
              product: products[index],
              variant: CompactCardVariant.catalogue,
            ),
          );
        },
      ),
    );
  }
}
