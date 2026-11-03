import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/in_app_announcement.dart';
import '../../providers/announcements_provider.dart';
import '../theme/app_theme.dart';

class _ThemeStyle {
  const _ThemeStyle({
    required this.badgeBg,
    required this.badgeTextColor,
    required this.icon,
    required this.defaultBadge,
    required this.borderColor,
  });

  final Color badgeBg;
  final Color badgeTextColor;
  final String icon;
  final String defaultBadge;
  final Color borderColor;
}

_ThemeStyle _getThemeStyle(String type) {
  switch (type.toUpperCase()) {
    case 'ALERT':
      return const _ThemeStyle(
        badgeBg: Color(0xFFFEF3C7), // amber-100
        badgeTextColor: Color(0xFF92400E), // amber-800
        icon: '🚨',
        defaultBadge: 'Delivery Notice',
        borderColor: Color(0xFFFCD34D),
      );
    case 'FEATURE':
      return const _ThemeStyle(
        badgeBg: Color(0xFFD1FAE5), // emerald-100
        badgeTextColor: Color(0xFF065F46), // emerald-800
        icon: '🌱',
        defaultBadge: 'New Arrival',
        borderColor: Color(0xFF6EE7B7),
      );
    case 'OFFER':
      return const _ThemeStyle(
        badgeBg: Color(0xFFFFE4E6), // rose-100
        badgeTextColor: Color(0xFF9F1239), // rose-800
        icon: '🎉',
        defaultBadge: 'Special Offer',
        borderColor: Color(0xFFFDA4AF),
      );
    case 'INFO':
    default:
      return const _ThemeStyle(
        badgeBg: Color(0xFFD1FAE5),
        badgeTextColor: Color(0xFF065F46),
        icon: '✨',
        defaultBadge: 'Notice',
        borderColor: Color(0xFF6EE7B7),
      );
  }
}

class ParsedMessage {
  const ParsedMessage({required this.intro, required this.bullets});

  final String intro;
  final List<MessageBullet> bullets;
}

class MessageBullet {
  const MessageBullet({required this.icon, required this.text});

  final String icon;
  final String text;
}

ParsedMessage parseMessageContent(String message) {
  if (message.trim().isEmpty) {
    return const ParsedMessage(intro: '', bullets: []);
  }

  final lines = message
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  final introLines = <String>[];
  final bullets = <MessageBullet>[];

  final bulletRegex =
      RegExp(r'^([•\-*🌱✨🌸🛡✅✔🏷🚨📦💊]\u{FE0F}?)\s*(.*)$', unicode: true);
  final emojiPrefixRegex = RegExp(
    r'^([\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]\u{FE0F}?)\s*(.*)$',
    unicode: true,
  );

  for (final line in lines) {
    final emojiMatch = emojiPrefixRegex.firstMatch(line);
    final bulletMatch = bulletRegex.firstMatch(line);

    if (emojiMatch != null) {
      final rawText = emojiMatch.group(2) ?? '';
      final cleanText =
          rawText.replaceFirst(RegExp(r'^[\uFE00-\uFE0F\s]+'), '');
      bullets.add(MessageBullet(
        icon: emojiMatch.group(1)!,
        text: cleanText,
      ));
    } else if (bulletMatch != null) {
      final char = bulletMatch.group(1)!;
      final icon =
          (char.startsWith('•') || char.startsWith('-') || char.startsWith('*'))
              ? '🌱'
              : char;
      final rawText = bulletMatch.group(2) ?? '';
      final cleanText =
          rawText.replaceFirst(RegExp(r'^[\uFE00-\uFE0F\s]+'), '');
      bullets.add(MessageBullet(
        icon: icon,
        text: cleanText,
      ));
    } else if (bullets.isNotEmpty) {
      bullets.add(MessageBullet(icon: '🌱', text: line));
    } else {
      introLines.add(line);
    }
  }

  return ParsedMessage(
    intro: introLines.join(' '),
    bullets: bullets,
  );
}

/// In-App Announcement Dialog replica of the web app's `InAppAnnouncementDialog.tsx`.
class InAppAnnouncementDialog extends ConsumerStatefulWidget {
  const InAppAnnouncementDialog({
    super.key,
    required this.announcement,
  });

  final InAppAnnouncement announcement;

  @override
  ConsumerState<InAppAnnouncementDialog> createState() =>
      _InAppAnnouncementDialogState();
}

class _InAppAnnouncementDialogState
    extends ConsumerState<InAppAnnouncementDialog> {
  bool _imageFailed = false;

  Future<void> _handleDismiss() async {
    final service = ref.read(announcementServiceProvider);
    await service.recordDismissal(widget.announcement);
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _handleCta() async {
    final service = ref.read(announcementServiceProvider);
    await service.recordDismissal(widget.announcement);

    if (!mounted) return;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final targetLink = widget.announcement.ctaLink;
    if (targetLink == null || targetLink.trim().isEmpty) return;

    final trimmed = targetLink.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        await launchUrlString(trimmed, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else {
      try {
        if (mounted) context.push(trimmed);
      } catch (_) {
        if (mounted) context.go(trimmed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ann = widget.announcement;
    final theme = _getThemeStyle(ann.type);
    final parsed = parseMessageContent(ann.message);
    final isLargePoster = ann.isLargePoster;
    final showImage = ann.hasImage && !_imageFailed;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargePoster ? 440 : 410,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38000000),
                blurRadius: 36,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Bar ──────────────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.badgeBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          theme.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'KK NUTRIVET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              theme.defaultBadge,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close announcement',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: _handleDismiss,
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ─────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: isLargePoster
                        ? const EdgeInsets.fromLTRB(16, 14, 16, 12)
                        : const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image banner
                        if (showImage) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: const Color(0xFFF3F6F3),
                              constraints: BoxConstraints(
                                maxHeight: isLargePoster ? 240 : 180,
                                minWidth: double.infinity,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: ann.imageUrl!,
                                fit: ann.imageFit == 'COVER'
                                    ? BoxFit.cover
                                    : BoxFit.contain,
                                errorWidget: (_, _, _) {
                                  WidgetsBinding.instance.addPostFrameCallback(
                                    (_) {
                                      if (mounted) {
                                        setState(() => _imageFailed = true);
                                      }
                                    },
                                  );
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Title
                        if (ann.title.trim().isNotEmpty) ...[
                          Text(
                            ann.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Intro text
                        if (parsed.intro.isNotEmpty) ...[
                          Text(
                            parsed.intro,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          if (parsed.bullets.isNotEmpty)
                            const SizedBox(height: 10),
                        ],

                        // Bullet rows
                        if (parsed.bullets.isNotEmpty) ...[
                          for (final bullet in parsed.bullets)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bullet.icon,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      bullet.text,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Bottom Action Buttons ───────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFCFA),
                    border: Border(
                      top: BorderSide(color: Color(0xFFF1F5F3)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ann.hasCta) ...[
                        SizedBox(
                          height: 46,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryDeep,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                            onPressed: _handleCta,
                            child: Text(
                              ann.ctaText!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      SizedBox(
                        height: 40,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _handleDismiss,
                          child: Text(
                            ann.dismissButtonText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: ann.hasCta
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: ann.hasCta
                                  ? AppColors.textSecondary
                                  : AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper to show announcement dialog
Future<void> showInAppAnnouncementDialog(
  BuildContext context,
  InAppAnnouncement announcement,
) {
  if (announcement.isFullscreenHero) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0xE6051510),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) =>
          FullscreenFestiveHeroOverlay(announcement: announcement),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0x8A000000), // slate-950/50
    builder: (ctx) => InAppAnnouncementDialog(announcement: announcement),
  );
}

/// Fullscreen Festive Hero Overlay matching web Diwali & festive campaign takeovers.
class FullscreenFestiveHeroOverlay extends ConsumerStatefulWidget {
  const FullscreenFestiveHeroOverlay({
    super.key,
    required this.announcement,
  });

  final InAppAnnouncement announcement;

  @override
  ConsumerState<FullscreenFestiveHeroOverlay> createState() =>
      _FullscreenFestiveHeroOverlayState();
}

class _FullscreenFestiveHeroOverlayState
    extends ConsumerState<FullscreenFestiveHeroOverlay> {
  Future<void> _handleDismiss() async {
    final service = ref.read(announcementServiceProvider);
    await service.recordDismissal(widget.announcement);
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _handleCta() async {
    final service = ref.read(announcementServiceProvider);
    await service.recordDismissal(widget.announcement);

    if (!mounted) return;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final targetLink = widget.announcement.ctaLink;
    if (targetLink == null || targetLink.trim().isEmpty) return;

    final trimmed = targetLink.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        await launchUrlString(trimmed, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else {
      try {
        if (mounted) context.push(trimmed);
      } catch (_) {
        if (mounted) context.go(trimmed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ann = widget.announcement;
    final bg = ann.bgImageUrl ?? ann.imageUrl;
    final hasHighlight = (ann.highlightTitle != null &&
            ann.highlightTitle!.isNotEmpty) ||
        (ann.highlightMessage != null && ann.highlightMessage!.isNotEmpty);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(announcementServiceProvider).recordDismissal(ann);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF071B14),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background Festive Image or Ambient Gradient ───────────
            if (bg != null && bg.isNotEmpty)
              CachedNetworkImage(
                imageUrl: bg,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _buildAmbientGradient(),
                placeholder: (_, _) => _buildAmbientGradient(),
              )
            else
              _buildAmbientGradient(),

            // ── Atmospheric Darkening / Vignette Overlay ─────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD904120D),
                    Color(0x8008241B),
                    Color(0xCC051813),
                    Color(0xF2030E0B),
                  ],
                  stops: [0.0, 0.35, 0.7, 1.0],
                ),
              ),
            ),

            // ── Main Content Scrollable Area ─────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Top close button bar
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, right: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleDismiss,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x66000000),
                              border: Border.all(
                                color: const Color(0x40E5C07B),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Brand header
                              const Text(
                                'KK NUTRIVET',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.4,
                                  color: Color(0xFFF3D08A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'HEALTH · CARE · TRUST',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.6,
                                  color: Color(0xB3F3D08A),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Eyebrow
                              Text(
                                ann.eyebrow?.toUpperCase() ??
                                    'A LITTLE LIGHT. A LOT OF LOVE.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: Color(0xFFE2C899),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Main festive title
                              Text(
                                ann.title,
                                textAlign: TextAlign.center,
                                style: AppTheme.serif(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Wish / message
                              Text(
                                ann.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFFE2EBE5),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Pet safety highlight card
                              if (hasHighlight)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xD90D2F23),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF1E5B42),
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(top: 2, right: 12),
                                        child: Icon(
                                          Icons.favorite_outline_rounded,
                                          color: Color(0xFF6EE7B7),
                                          size: 20,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (ann.highlightTitle != null)
                                              Text(
                                                ann.highlightTitle!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            if (ann.highlightMessage != null) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                ann.highlightMessage!,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  height: 1.35,
                                                  color: Color(0xFFB8DACB),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 24),

                              // CTA Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _handleCta,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE5C07B),
                                    foregroundColor: const Color(0xFF07261C),
                                    elevation: 4,
                                    shadowColor: const Color(0x66E5C07B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        ann.ctaText ?? 'Continue shopping',
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                          color: Color(0xFF07261C),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: Color(0xFF07261C),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (ann.footerText != null &&
                                  ann.footerText!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  ann.footerText!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0x99FFFFFF),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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

  Widget _buildAmbientGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.1,
          colors: [
            Color(0xFF134533),
            Color(0xFF09291D),
            Color(0xFF04120D),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// Global coordinator to trigger in-app announcement when eligible.
class InAppAnnouncementCoordinator {
  static bool _dialogCurrentlyOpen = false;

  static Future<void> checkAndShow(
    BuildContext context,
    WidgetRef ref, {
    required String currentRoute,
  }) async {
    if (_dialogCurrentlyOpen) return;
    final service = ref.read(announcementServiceProvider);
    if (service.hasShownThisSession) return;

    try {
      final candidate = await service.getNextEligibleAnnouncement(
        currentRoute: currentRoute,
      );

      if (candidate == null) return;
      if (!context.mounted) return;

      // Small delay so screen transition completes smoothly
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!context.mounted) return;
      if (service.hasShownThisSession || _dialogCurrentlyOpen) return;

      service.markShownThisSession();
      _dialogCurrentlyOpen = true;

      try {
        await showInAppAnnouncementDialog(context, candidate);
      } finally {
        _dialogCurrentlyOpen = false;
      }
    } catch (_) {}
  }
}
