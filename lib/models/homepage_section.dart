import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

Color parseHexColor(dynamic hex, {Color fallback = AppColors.primaryDeep}) {
  if (hex is! String) return fallback;
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) {
    final val = int.tryParse('FF$clean', radix: 16);
    return val != null ? Color(val) : fallback;
  } else if (clean.length == 8) {
    final val = int.tryParse(clean, radix: 16);
    return val != null ? Color(val) : fallback;
  }
  return fallback;
}

IconData parseIcon(
  String? iconName, {
  IconData fallback = Icons.star_outline_rounded,
}) {
  if (iconName == null) return fallback;
  switch (iconName.toLowerCase().replaceAll('-', '_')) {
    case 'shopping_bag':
    case 'shopping_bag_outlined':
      return Icons.shopping_bag_outlined;
    case 'medical_services':
    case 'medical_services_outlined':
      return Icons.medical_services_outlined;
    case 'calculate':
    case 'calculate_outlined':
      return Icons.calculate_outlined;
    case 'verified_user':
    case 'verified_user_outlined':
    case 'shield':
      return Icons.verified_user_outlined;
    case 'local_shipping':
    case 'local_shipping_outlined':
    case 'truck':
      return Icons.local_shipping_outlined;
    case 'pets':
      return Icons.pets;
    case 'heart':
    case 'favorite':
      return Icons.favorite_border_rounded;
    case 'bolt':
    case 'flash':
      return Icons.bolt_rounded;
    case 'eco':
      return Icons.eco_outlined;
    case 'water_drop':
    case 'water_drop_outlined':
      return Icons.water_drop_outlined;
    case 'medication':
    case 'medication_outlined':
      return Icons.medication_outlined;
    case 'auto_awesome':
    case 'auto_awesome_outlined':
      return Icons.auto_awesome_outlined;
    default:
      return fallback;
  }
}

class HeroSlideData {
  const HeroSlideData({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.cta,
    required this.icon,
    required this.image,
    required this.imageCover,
    required this.route,
    required this.bg,
    required this.chipBg,
    required this.chipText,
    required this.bodyColor,
    required this.accent,
  });

  final String id;
  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final IconData icon;
  final String image;
  final bool imageCover;
  final String route;
  final List<Color> bg;
  final Color chipBg;
  final Color chipText;
  final Color bodyColor;
  final Color accent;

  factory HeroSlideData.fromJson(Map<String, dynamic> json) {
    final bgList = json['bg'];
    List<Color> bgColors = const [Color(0xFFF4F8EE), Color(0xFFE0EFE2)];
    if (bgList is List && bgList.isNotEmpty) {
      bgColors = bgList.map((c) => parseHexColor(c)).toList();
      if (bgColors.length == 1) bgColors = [bgColors[0], bgColors[0]];
    }

    return HeroSlideData(
      id: json['id']?.toString() ?? '',
      eyebrow: json['eyebrow']?.toString() ?? 'Health · Care · Trust',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      cta: json['cta']?.toString() ?? 'Shop Now',
      icon: parseIcon(
        json['icon']?.toString(),
        fallback: Icons.shopping_bag_outlined,
      ),
      image: json['image']?.toString() ??
          'assets/marketing_image/hero-animals-cutout-v1.png',
      imageCover: json['imageCover'] == true,
      route: json['route']?.toString() ?? '/products',
      bg: bgColors,
      chipBg: parseHexColor(json['chipBg'], fallback: const Color(0xB2FFFFFF)),
      chipText:
          parseHexColor(json['chipText'], fallback: AppColors.primaryDeep),
      bodyColor:
          parseHexColor(json['bodyColor'], fallback: const Color(0xFF38594C)),
      accent: parseHexColor(json['accent'], fallback: const Color(0xFFB9412E)),
    );
  }
}

class HeroSectionContent {
  const HeroSectionContent({required this.slides});
  final List<HeroSlideData> slides;

  factory HeroSectionContent.fromJson(Map<String, dynamic> json) {
    final rawSlides = json['slides'];
    final list = <HeroSlideData>[];
    if (rawSlides is List) {
      for (final s in rawSlides) {
        if (s is Map<String, dynamic>) list.add(HeroSlideData.fromJson(s));
      }
    }
    return HeroSectionContent(slides: list);
  }
}

class ReviewTestimonialData {
  const ReviewTestimonialData({
    required this.author,
    required this.relativeTime,
    required this.content,
    this.rating = 5,
  });

  final String author;
  final String relativeTime;
  final String content;
  final int rating;

  factory ReviewTestimonialData.fromJson(Map<String, dynamic> json) {
    return ReviewTestimonialData(
      author: json['author']?.toString() ??
          json['name']?.toString() ??
          'Verified Customer',
      relativeTime: json['relativeTime']?.toString() ??
          json['date']?.toString() ??
          'Recently',
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
    );
  }
}

class ReviewsSectionContent {
  const ReviewsSectionContent({
    this.eyebrow = 'GOOGLE REVIEWS',
    this.title = 'Loved by pet parents',
    this.rating = '4.9',
    this.ratingSubtitle =
        'Rated by verified customers on Google Business Profile',
    required this.testimonials,
  });

  final String eyebrow;
  final String title;
  final String rating;
  final String ratingSubtitle;
  final List<ReviewTestimonialData> testimonials;

  factory ReviewsSectionContent.fromJson(Map<String, dynamic> json) {
    final rawTestimonials = json['testimonials'] ?? json['reviews'];
    final list = <ReviewTestimonialData>[];
    if (rawTestimonials is List) {
      for (final t in rawTestimonials) {
        if (t is Map<String, dynamic>) {
          list.add(ReviewTestimonialData.fromJson(t));
        }
      }
    }
    return ReviewsSectionContent(
      eyebrow: json['eyebrow']?.toString() ?? 'GOOGLE REVIEWS',
      title: json['title']?.toString() ?? 'Loved by pet parents',
      rating: json['rating']?.toString() ?? '4.9',
      ratingSubtitle: json['ratingSubtitle']?.toString() ??
          'Rated by verified customers on Google Business Profile',
      testimonials: list,
    );
  }
}

class TrustBadgeData {
  const TrustBadgeData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  factory TrustBadgeData.fromJson(Map<String, dynamic> json) {
    return TrustBadgeData(
      icon: parseIcon(
        json['icon']?.toString(),
        fallback: Icons.verified_user_outlined,
      ),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}

class TrustSectionContent {
  const TrustSectionContent({
    this.title = 'Care you can count on',
    this.subtitle = 'Every order, from checkout to your doorstep',
    required this.badges,
  });

  final String title;
  final String subtitle;
  final List<TrustBadgeData> badges;

  factory TrustSectionContent.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'];
    final list = <TrustBadgeData>[];
    if (rawBadges is List) {
      for (final b in rawBadges) {
        if (b is Map<String, dynamic>) list.add(TrustBadgeData.fromJson(b));
      }
    }
    return TrustSectionContent(
      title: json['title']?.toString() ?? 'Care you can count on',
      subtitle: json['subtitle']?.toString() ??
          'Every order, from checkout to your doorstep',
      badges: list,
    );
  }
}

class PromoFeatureItem {
  const PromoFeatureItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;

  factory PromoFeatureItem.fromJson(Map<String, dynamic> json) {
    return PromoFeatureItem(
      label: json['label']?.toString() ?? json['title']?.toString() ?? '',
      route:
          json['route']?.toString() ?? json['link']?.toString() ?? '/products',
      icon: parseIcon(
        json['icon']?.toString(),
        fallback: Icons.auto_awesome_outlined,
      ),
    );
  }
}

class SeasonalPromoContent {
  const SeasonalPromoContent({
    this.badgeLabel = 'MONSOON CARE',
    this.badgeIcon = Icons.water_drop_outlined,
    this.title = 'Wet paws & damp coats need extra care',
    this.subtitle =
        'Keep ticks, fleas, gut worms and seasonal skin infections away with vet-trusted monsoon essentials.',
    this.bgGradient = const [
      Color(0xFF072E29),
      Color(0xFF0D4A3E),
      Color(0xFF136B56),
    ],
    required this.features,
  });

  final String badgeLabel;
  final IconData badgeIcon;
  final String title;
  final String subtitle;
  final List<Color> bgGradient;
  final List<PromoFeatureItem> features;

  factory SeasonalPromoContent.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'] ?? json['buttons'];
    final featuresList = <PromoFeatureItem>[];
    if (rawFeatures is List) {
      for (final f in rawFeatures) {
        if (f is Map<String, dynamic>) {
          featuresList.add(PromoFeatureItem.fromJson(f));
        }
      }
    }

    final rawGrad = json['bgGradient'];
    List<Color> grad = const [
      Color(0xFF072E29),
      Color(0xFF0D4A3E),
      Color(0xFF136B56),
    ];
    if (rawGrad is List && rawGrad.isNotEmpty) {
      grad = rawGrad.map((c) => parseHexColor(c)).toList();
      if (grad.length == 1) grad = [grad[0], grad[0]];
    }

    return SeasonalPromoContent(
      badgeLabel: json['badgeLabel']?.toString() ??
          json['tag']?.toString() ??
          'MONSOON CARE',
      badgeIcon: parseIcon(
        json['badgeIcon']?.toString(),
        fallback: Icons.water_drop_outlined,
      ),
      title:
          json['title']?.toString() ?? 'Wet paws & damp coats need extra care',
      subtitle: json['subtitle']?.toString() ??
          'Keep ticks, fleas, gut worms and seasonal skin infections away with vet-trusted monsoon essentials.',
      bgGradient: grad,
      features: featuresList,
    );
  }
}

class CommunityStatItem {
  const CommunityStatItem({
    required this.value,
    required this.label,
    required this.bg,
  });

  final String value;
  final String label;
  final Color bg;

  factory CommunityStatItem.fromJson(Map<String, dynamic> json) {
    return CommunityStatItem(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      bg: parseHexColor(json['bg'], fallback: const Color(0xFFE5F0DE)),
    );
  }
}

class CommunityStoryContent {
  const CommunityStoryContent({
    this.eyebrow = 'FROM BRAHMAPUR',
    this.headline = 'A little local care.\nA journey across India.',
    this.storyText =
        'Animal-care essentials, packed with care in Brahmapur, Odisha and sent across India.',
    this.ctaText = 'See our journey',
    this.ctaLink = '/info/about',
    this.image = 'assets/images/brahmapur-delivery-story.webp',
    required this.stats,
  });

  final String eyebrow;
  final String headline;
  final String storyText;
  final String ctaText;
  final String ctaLink;
  final String image;
  final List<CommunityStatItem> stats;

  factory CommunityStoryContent.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final statsList = <CommunityStatItem>[];
    if (rawStats is List) {
      for (final s in rawStats) {
        if (s is Map<String, dynamic>) {
          statsList.add(CommunityStatItem.fromJson(s));
        }
      }
    }

    return CommunityStoryContent(
      eyebrow: json['eyebrow']?.toString() ?? 'FROM BRAHMAPUR',
      headline: json['headline']?.toString() ??
          json['title']?.toString() ??
          'A little local care.\nA journey across India.',
      storyText: json['storyText']?.toString() ??
          json['body']?.toString() ??
          'Animal-care essentials, packed with care in Brahmapur, Odisha and sent across India.',
      ctaText: json['ctaText']?.toString() ?? 'See our journey',
      ctaLink: json['ctaLink']?.toString() ?? '/info/about',
      image: json['image']?.toString() ??
          'assets/images/brahmapur-delivery-story.webp',
      stats: statsList,
    );
  }
}

/// Generic container for any homepage section payload returned from `GET /api/homepage-sections`.
class HomepageSection {
  const HomepageSection({
    required this.id,
    required this.title,
    this.subtitle,
    this.images = const [],
    this.enabled = true,
    this.order = 0,
    required this.type,
    this.config = const {},
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<dynamic> images;
  final bool enabled;
  final int order;
  final String type;
  final Map<String, dynamic> config;

  String get identifier => id.isNotEmpty ? id : type;

  HeroSectionContent? get heroContent {
    if (identifier == 'hero_carousel' || type == 'hero_carousel') {
      return HeroSectionContent.fromJson(config);
    }
    return null;
  }

  ReviewsSectionContent? get reviewsContent {
    if (identifier == 'reviews' || type == 'reviews') {
      return ReviewsSectionContent.fromJson(config);
    }
    return null;
  }

  TrustSectionContent? get trustContent {
    if (identifier == 'trust_badges' || type == 'trust_badges') {
      return TrustSectionContent.fromJson(config);
    }
    return null;
  }

  SeasonalPromoContent? get seasonalPromoContent {
    if (identifier == 'seasonal-promo' || type == 'seasonal-promo') {
      return SeasonalPromoContent.fromJson(config);
    }
    return null;
  }

  CommunityStoryContent? get communityStoryContent {
    if (identifier == 'community_story' || type == 'community_story') {
      return CommunityStoryContent.fromJson(config);
    }
    return null;
  }

  factory HomepageSection.fromJson(Map<String, dynamic> json) {
    return HomepageSection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      images: (json['images'] as List<dynamic>?) ?? const [],
      enabled: json['enabled'] != false,
      order: (json['order'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'generic',
      config: (json['config'] is Map<String, dynamic>)
          ? json['config'] as Map<String, dynamic>
          : const {},
    );
  }
}
