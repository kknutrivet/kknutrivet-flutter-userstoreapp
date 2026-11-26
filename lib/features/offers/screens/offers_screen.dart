import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/compact_product_card.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../cart/widgets/cart_coupons_and_coins.dart'
    show publicCouponsProvider;

final offerProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final products = await ref
      .read(catalogServiceProvider)
      .fetchProducts(limit: 40);
  return products
      .where((p) => (p.mrp != null && p.mrp! > p.effectivePrice) || p.offerPrice != null)
      .toList();
});

/// Dedicated `/offers` screen mirroring `src/app/offers/page.tsx` on mobile web:
/// active promo codes, Care Combos, and discounted products.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(publicCouponsProvider);
    final combosAsync = ref.watch(homeCombosProvider);
    final dealsAsync = ref.watch(offerProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        toolbarHeight: 54,
        backgroundColor: const Color(0xFF07583F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Offers & Deals',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDeep,
        onRefresh: () async {
          ref.invalidate(publicCouponsProvider);
          ref.invalidate(homeCombosProvider);
          ref.invalidate(offerProductsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
          children: [
            // Active Coupons
            couponsAsync.maybeWhen(
              data: (coupons) {
                if (coupons.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Coupon Codes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final offer in coupons) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryWashDeep),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryWash,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                offer.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer.headline,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    offer.subline,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Haptics.tap();
                                Clipboard.setData(
                                  ClipboardData(text: offer.code),
                                );
                                showToast('Copied ${offer.code}');
                              },
                              child: const Text(
                                'Copy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Care Combos
            combosAsync.maybeWhen(
              data: (combos) {
                final active = combos.where((c) => c.isActive).toList();
                if (active.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Value Care Combos',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final combo in active.take(6)) ...[
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push('/combos/${combo.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (combo.savingAmount > 0)
                                        Text(
                                          'SAVE ₹${combo.savingAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primaryDeep,
                                          ),
                                        ),
                                      Text(
                                        combo.name,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${combo.comboPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryDeepest,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Discounted Products
            const Text(
              'Top Discounted Products',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            dealsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingView(),
              ),
              error: (_, _) => ErrorView(
                message: 'Could not load discounted products.',
                onRetry: () => ref.invalidate(offerProductsProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyView(
                    message: 'Check back soon for new offers!',
                    icon: Icons.local_offer_outlined,
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
    );
  }
}
