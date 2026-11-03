class InAppAnnouncement {
  const InAppAnnouncement({
    required this.id,
    required this.isActive,
    this.type = 'INFO',
    this.layoutMode = 'TEXT_ONLY',
    this.imageFit = 'CONTAIN',
    required this.title,
    required this.message,
    this.imageUrl,
    this.bgImageUrl,
    this.eyebrow,
    this.highlightTitle,
    this.highlightMessage,
    this.footerText,
    this.ctaText,
    this.ctaLink,
    this.target = 'ALL',
    this.dismissButtonText = 'Maybe Later',
    this.priority = 99,
    this.version = 1,
    this.updatedAt,
  });

  final String id;
  final bool isActive;
  final String type; // ALERT, FEATURE, OFFER, INFO, FESTIVE
  final String layoutMode; // TEXT_ONLY, IMAGE_AND_TEXT, LARGE_IMAGE_POSTER, FULLSCREEN_HERO, FESTIVE_HERO
  final String imageFit; // CONTAIN, COVER
  final String title;
  final String message;
  final String? imageUrl;
  final String? bgImageUrl;
  final String? eyebrow;
  final String? highlightTitle;
  final String? highlightMessage;
  final String? footerText;
  final String? ctaText;
  final String? ctaLink;
  final String target; // ALL, HOMEPAGE_ONLY, CHECKOUT_ONLY
  final String dismissButtonText;
  final int priority;
  final int version;
  final String? updatedAt;

  bool get isFullscreenHero =>
      layoutMode == 'FULLSCREEN_HERO' ||
      layoutMode == 'FESTIVE_HERO' ||
      type == 'FESTIVE';
  bool get isLargePoster => layoutMode == 'LARGE_IMAGE_POSTER';
  bool get hasImage =>
      layoutMode != 'TEXT_ONLY' &&
      ((imageUrl != null && imageUrl!.trim().isNotEmpty) ||
          (bgImageUrl != null && bgImageUrl!.trim().isNotEmpty));
  bool get hasCta =>
      ctaText != null &&
      ctaText!.trim().isNotEmpty &&
      ctaLink != null &&
      ctaLink!.trim().isNotEmpty;

  factory InAppAnnouncement.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?)?.toUpperCase() ?? 'INFO';
    final type = ['ALERT', 'FEATURE', 'OFFER', 'INFO', 'FESTIVE'].contains(rawType)
        ? rawType
        : 'INFO';

    final hasImg = (json['imageUrl'] as String?)?.trim().isNotEmpty == true ||
        (json['bgImageUrl'] as String?)?.trim().isNotEmpty == true;
    final hasTxt = (json['title'] as String?)?.trim().isNotEmpty == true ||
        (json['message'] as String?)?.trim().isNotEmpty == true;

    String fallbackLayout = 'TEXT_ONLY';
    if (type == 'FESTIVE') {
      fallbackLayout = 'FULLSCREEN_HERO';
    } else if (hasImg && hasTxt) {
      fallbackLayout = 'IMAGE_AND_TEXT';
    } else if (hasImg && !hasTxt) {
      fallbackLayout = 'LARGE_IMAGE_POSTER';
    }

    final rawLayout =
        (json['layoutMode'] as String?)?.toUpperCase() ?? fallbackLayout;
    final layoutMode = [
      'TEXT_ONLY',
      'IMAGE_AND_TEXT',
      'LARGE_IMAGE_POSTER',
      'FULLSCREEN_HERO',
      'FESTIVE_HERO',
    ].contains(rawLayout)
        ? rawLayout
        : fallbackLayout;

    final rawTarget = (json['target'] as String?)?.toUpperCase() ?? 'ALL';
    final target = ['ALL', 'HOMEPAGE_ONLY', 'CHECKOUT_ONLY'].contains(rawTarget)
        ? rawTarget
        : 'ALL';

    final rawDismiss =
        (json['dismissButtonText'] as String?)?.trim() ?? 'Maybe Later';
    final dismissButtonText = rawDismiss.toLowerCase() == 'got it'
        ? (layoutMode == 'IMAGE_AND_TEXT' ? 'Not Now' : 'Maybe Later')
        : (rawDismiss.isNotEmpty ? rawDismiss : 'Maybe Later');

    return InAppAnnouncement(
      id: (json['id'] as String?) ?? 'ann_default',
      isActive: (json['isActive'] as bool?) ?? true,
      type: type,
      layoutMode: layoutMode,
      imageFit: (json['imageFit'] as String?)?.toUpperCase() == 'COVER'
          ? 'COVER'
          : 'CONTAIN',
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      imageUrl: (json['imageUrl'] as String?)?.trim(),
      bgImageUrl: (json['bgImageUrl'] as String?)?.trim(),
      eyebrow: (json['eyebrow'] as String?)?.trim() ??
          (json['subtitle'] as String?)?.trim(),
      highlightTitle: (json['highlightTitle'] as String?)?.trim(),
      highlightMessage: (json['highlightMessage'] as String?)?.trim(),
      footerText: (json['footerText'] as String?)?.trim(),
      ctaText: (json['ctaText'] as String?)?.trim(),
      ctaLink: (json['ctaLink'] as String?)?.trim(),
      target: target,
      dismissButtonText: dismissButtonText,
      priority: (json['priority'] as num?)?.toInt() ?? 99,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isActive': isActive,
        'type': type,
        'layoutMode': layoutMode,
        'imageFit': imageFit,
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'bgImageUrl': bgImageUrl,
        'eyebrow': eyebrow,
        'highlightTitle': highlightTitle,
        'highlightMessage': highlightMessage,
        'footerText': footerText,
        'ctaText': ctaText,
        'ctaLink': ctaLink,
        'target': target,
        'dismissButtonText': dismissButtonText,
        'priority': priority,
        'version': version,
        'updatedAt': updatedAt,
      };
}
