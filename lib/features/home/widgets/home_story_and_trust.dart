import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../models/homepage_section.dart';
import 'home_models_and_data.dart';

// ── 11. Trust panel ("Care you can count on" 2×2 grid) ───────────────────────
class HomeTrustPanel extends ConsumerWidget {
  const HomeTrustPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustSection = ref.watch(homeTrustSectionProvider);

    final title = trustSection?.title ?? 'Care you can count on';
    final subtitle = trustSection?.subtitle ??
        'Every order, from checkout to your doorstep';
    final List<(IconData, String, String)> badges =
        (trustSection != null && trustSection.badges.length >= 4)
            ? trustSection.badges
                .take(4)
                .map((b) => (b.icon, b.title, b.subtitle))
                .toList()
            : const [
                (Icons.verified_user_outlined, 'Genuine', 'Products'),
                (Icons.local_shipping_outlined, 'All India', 'Delivery'),
                (Icons.shopping_bag_outlined, 'Secure', 'Checkout'),
                (Icons.pets, 'AI', 'Guidance'),
              ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryWashFaint,
          border: Border.all(color: AppColors.primaryWashDeep),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.primaryWashDeep),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryDeep,
                    child: Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _trustTile(badges[0])),
                      const SizedBox(width: 8),
                      Expanded(child: _trustTile(badges[1])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _trustTile(badges[2])),
                      const SizedBox(width: 8),
                      Expanded(child: _trustTile(badges[3])),
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

  Widget _trustTile((IconData, String, String) badge) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(
          color: AppColors.primaryWashDeep.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              badge.$1,
              size: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  badge.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 12. CareReachStoryCard (CareReachStory.tsx) ──────────────────────────────
class HomeCareReachStoryCard extends ConsumerWidget {
  const HomeCareReachStoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(homeCommunityStorySectionProvider);

    final eyebrow = story?.eyebrow ?? 'FROM BRAHMAPUR';
    final storyText = story?.storyText ??
        'Animal-care essentials, packed with care in Brahmapur, Odisha and sent across India.';
    final ctaText = story?.ctaText ?? 'See our journey';
    final ctaLink = story?.ctaLink ?? '/info/about';
    final image = story?.image ?? 'assets/images/brahmapur-delivery-story.webp';

    final stats = (story != null && story.stats.isNotEmpty)
        ? story.stats.map((s) => (s.value, s.label, s.bg)).toList()
        : const [
            ('5,000+', 'Delivered', Color(0xFFE5F0DE)),
            ('18', 'States & UTs', Color(0xFFFFE9BE)),
            ('1,200+', 'Vet consults', Color(0xFFF8DDD0)),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFDF8), Color(0xFFF4FAF6)],
          ),
          border: Border.all(color: const Color(0xFFDCE8E0)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF624519).withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Color(0xFF936035),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              eyebrow,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Color(0xFF936035),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: story != null && story.headline.contains('\n')
                                    ? '${story.headline.split('\n').first}\n'
                                    : 'A little local care.\n',
                              ),
                              TextSpan(
                                text: story != null && story.headline.contains('\n')
                                    ? story.headline.split('\n').sublist(1).join('\n')
                                    : 'A journey across India.',
                                style: AppTheme.serif(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  color: const Color(0xFFB45E35),
                                ),
                              ),
                            ],
                          ),
                          style: AppTheme.serif(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: const Color(0xFF173F34),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          storyText,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Color(0xFF52645C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: AppColors.primaryDeep,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              Haptics.tap();
                              context.push(ctaLink);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ctaText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.north_east_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: (image.startsWith('http') || image.startsWith('/'))
                          ? AppNetworkImage(
                              imageUrl: image,
                              height: 140,
                              fit: BoxFit.contain,
                              fallbackIcon: Icons.local_shipping_outlined,
                            )
                          : Image.asset(
                              image,
                              height: 140,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFDCE8E0)),
                ),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        color: stats[i].$3,
                        child: Column(
                          children: [
                            Text(
                              stats[i].$1,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF173F34),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stats[i].$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF52645C),
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
      ),
    );
  }
}

// ── 13. Reviews band (GoogleReviewsSection mobile) ───────────────────────────
class HomeReviewsBand extends ConsumerWidget {
  const HomeReviewsBand({super.key});

  static const _defaultReviews = [
    (
      'Subhashree Panda',
      '2 weeks ago',
      'Genuine veterinary medicines and supplements in Brahmapur. Ordered calcium and dewormer for our Labrador — fast delivery and well packed!',
    ),
    (
      'Rajesh Kumar Patro',
      '1 month ago',
      'Best store in Ganjam for cattle & poultry supplements. Reasonable price compared to local market and always authentic stock.',
    ),
    (
      'Ananya Mohanty',
      '3 weeks ago',
      'Uploaded my vet prescription and their team matched every medicine within minutes. Super helpful WhatsApp and consultation support.',
    ),
    (
      'Santosh Behera',
      '1 month ago',
      'Very reliable service for both pet food and farm medicines. Online vet consultation saved us a stressful clinic trip.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsContent = ref.watch(homeReviewsSectionProvider);

    final eyebrow = reviewsContent?.eyebrow ?? 'GOOGLE REVIEWS';
    final title = reviewsContent?.title ?? 'Loved by pet parents';
    final rating = reviewsContent?.rating ?? '4.9';
    final ratingSubtitle = reviewsContent?.ratingSubtitle ??
        'Rated by verified customers on Google Business Profile';

    final reviews = (reviewsContent != null &&
            reviewsContent.testimonials.isNotEmpty)
        ? reviewsContent.testimonials
            .map((t) => (t.author, t.relativeTime, t.content))
            .toList()
        : _defaultReviews;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFBFCF4),
            Color(0xFFEEF8EE),
            Color(0xFFE2F3E7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              eyebrow,
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.serif(
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Haptics.tap();
                      context.push('/help');
                    },
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 12,
                            color: AppColors.primaryDeep,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    rating,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.starGold,
                            ),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.starGold,
                            ),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.starGold,
                            ),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.starGold,
                            ),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.starGold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ratingSubtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final (name, time, text) = reviews[i];
                final initial = name.substring(0, 1);
                return Container(
                  width: 268,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryWash,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
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
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.starGold,
                              ),
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.starGold,
                              ),
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.starGold,
                              ),
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.starGold,
                              ),
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.starGold,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
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
  }
}

// ── 13b. MonsoonCareBanner (MonsoonCareBanner.tsx) ───────────────────────────
class HomeMonsoonCareBanner extends ConsumerWidget {
  const HomeMonsoonCareBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promo = ref.watch(homeSeasonalPromoSectionProvider);

    final badgeLabel = promo?.badgeLabel ?? 'MONSOON CARE';
    final badgeIcon = promo?.badgeIcon ?? Icons.water_drop_outlined;
    final title = promo?.title ?? 'Wet paws & damp coats need extra care';
    final subtitle = promo?.subtitle ??
        'Keep ticks, fleas, gut worms and seasonal skin infections away with vet-trusted monsoon essentials.';
    final bgColors = promo?.bgGradient ??
        const [
          Color(0xFF072E29),
          Color(0xFF0D4A3E),
          Color(0xFF136B56),
        ];

    final features = (promo != null && promo.features.isNotEmpty)
        ? promo.features
        : const [
            PromoFeatureItem(
              label: 'Shop Deworming',
              route: '/products?category=Deworming',
              icon: Icons.medication_outlined,
            ),
            PromoFeatureItem(
              label: 'Immunity & Skin',
              route: '/products?category=Grooming',
              icon: Icons.auto_awesome_outlined,
            ),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
          border:
              Border.all(color: const Color(0xFFB7D4E8).withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF123A52).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 12, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    badgeLabel,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTheme.serif(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < features.length; i++)
                  i == 0
                      ? Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              Haptics.tap();
                              context.push(features[i].route);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    features[i].icon,
                                    size: 14,
                                    color: AppColors.primaryDeep,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    features[i].label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {
                              Haptics.tap();
                              context.push(features[i].route);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    features[i].icon,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    features[i].label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
