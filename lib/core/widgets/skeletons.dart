import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Content-shaped shimmer placeholders — spinners read as "web page
/// loading"; skeletons that mirror the eventual layout read as native.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height, this.radius = 8});
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        period: const Duration(milliseconds: 1250),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Container(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 16,
                        width: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 28,
                        width: 62,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of skeleton cards, e.g. for the product list screen while loading.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio:
            MediaQuery.sizeOf(context).width < 350 ? 0.61 : 0.66,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) => const ProductCardSkeleton(),
    );
  }
}

/// Horizontal rail of skeleton cards, e.g. for home screen product rails.
class ProductRailSkeleton extends StatelessWidget {
  const ProductRailSkeleton({super.key, this.itemCount = 4});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, i) => const SizedBox(width: 155, child: ProductCardSkeleton()),
    );
  }
}

/// Layout-matched shimmer skeleton for the Product Detail screen.
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1250),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      ShimmerBox(width: 72, height: 24, radius: 999),
                      SizedBox(width: 8),
                      ShimmerBox(width: 96, height: 24, radius: 999),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const ShimmerBox(width: double.infinity, height: 22, radius: 6),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 210, height: 22, radius: 6),
                  const SizedBox(height: 16),
                  const ShimmerBox(width: double.infinity, height: 74, radius: 14),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(height: 52, radius: 12)),
                      SizedBox(width: 10),
                      Expanded(child: ShimmerBox(height: 52, radius: 12)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ShimmerBox(width: double.infinity, height: 110, radius: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layout-matched shimmer skeleton for the Combo Detail screen.
class ComboDetailSkeleton extends StatelessWidget {
  const ComboDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1250),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ShimmerBox(width: double.infinity, radius: 16),
            ),
            SizedBox(height: 16),
            ShimmerBox(width: 120, height: 22, radius: 999),
            SizedBox(height: 10),
            ShimmerBox(width: double.infinity, height: 24, radius: 6),
            SizedBox(height: 8),
            ShimmerBox(width: 180, height: 16, radius: 6),
            SizedBox(height: 20),
            ShimmerBox(width: double.infinity, height: 84, radius: 14),
            SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: 84, radius: 14),
            SizedBox(height: 12),
            ShimmerBox(width: double.infinity, height: 84, radius: 14),
          ],
        ),
      ),
    );
  }
}

/// Layout-matched shimmer skeleton for the Orders list screen.
class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key, this.itemCount = 3});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1250),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: const [
              ShimmerBox(width: 56, height: 32, radius: 999),
              SizedBox(width: 8),
              ShimmerBox(width: 84, height: 32, radius: 999),
              SizedBox(width: 8),
              ShimmerBox(width: 84, height: 32, radius: 999),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < itemCount; i++) ...[
            const ShimmerBox(width: double.infinity, height: 152, radius: 14),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Generic list of card skeletons for Pets, Addresses, Blog, and Health screens.
class ListCardSkeleton extends StatelessWidget {
  const ListCardSkeleton({
    super.key,
    this.itemCount = 4,
    this.cardHeight = 104,
  });

  final int itemCount;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1250),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, _) => ShimmerBox(
          width: double.infinity,
          height: cardHeight,
          radius: AppRadius.card,
        ),
      ),
    );
  }
}
