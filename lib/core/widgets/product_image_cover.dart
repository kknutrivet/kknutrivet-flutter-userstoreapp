import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_network_image.dart';

/// Product card image component replicating the website's signature
/// `.coverLayers` presentation (`CatalogueCard.module.css`):
/// - A blurred ambient backdrop (`.coverBackdrop`) that casts a soft color glow
///   matching the product packaging.
/// - A crisp, centered foreground image (`.coverForeground`) with `BoxFit.contain`
///   so the product is never cropped or distorted.
/// - Built-in automatic retry with exponential backoff and tap-to-retry.
class ProductImageCover extends StatelessWidget {
  const ProductImageCover({
    super.key,
    required this.imageUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.backgroundColor = Colors.white,
    this.innerPadding = const EdgeInsets.all(4),
    this.backdropOpacity = 0.85,
    this.blurSigma = 12.0,
    this.showPlaceholderOnLoading = true,
  });

  final String? imageUrl;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final EdgeInsetsGeometry innerPadding;
  final double backdropOpacity;
  final double blurSigma;
  final bool showPlaceholderOnLoading;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = AppNetworkImage.resolveUrl(imageUrl);
    final hasImage = resolvedUrl != null && resolvedUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0xFFE3ECE6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient blurred packaging backdrop (lightweight downsampled decode for RAM efficiency)
          if (hasImage)
            Positioned(
              left: -12,
              top: -12,
              right: -12,
              bottom: -12,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Opacity(
                  opacity: backdropOpacity,
                  child: CachedNetworkImage(
                    imageUrl: resolvedUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 80,
                    maxWidthDiskCache: 200,
                    placeholder: (_, _) => const SizedBox.shrink(),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // 2. Subtle radial vignette to keep foreground packaging crisp while preserving rich color
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  radius: 0.85,
                ),
              ),
            ),
          ),

          // 3. Crisp centered foreground image with auto-retry and tap-to-retry
          Padding(
            padding: innerPadding,
            child: Center(
              child: hasImage
                  ? AppNetworkImage(
                      imageUrl: resolvedUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 600,
                      showPlaceholderOnLoading: showPlaceholderOnLoading,
                      enableManualRetry: true,
                    )
                  : const Center(
                      child: Icon(
                        Icons.pets,
                        size: 26,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
