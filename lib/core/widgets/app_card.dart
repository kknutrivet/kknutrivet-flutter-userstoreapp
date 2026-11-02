import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Style variants for [AppCard].
enum AppCardVariant {
  flat,
  outlined,
  elevated,
  tinted,
}

/// Standardized card component providing unified border, padding, radius,
/// soft ambient shadows, and tactile press response.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.outlined,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.borderRadius = AppRadius.card,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ??
        switch (widget.variant) {
          AppCardVariant.flat => Colors.white,
          AppCardVariant.outlined => Colors.white,
          AppCardVariant.elevated => Colors.white,
          AppCardVariant.tinted => AppColors.surfaceAlt,
        };

    final border = switch (widget.variant) {
      AppCardVariant.flat => null,
      AppCardVariant.outlined =>
        Border.all(color: widget.borderColor ?? AppColors.border),
      AppCardVariant.elevated =>
        Border.all(color: widget.borderColor ?? AppColors.borderSubtle),
      AppCardVariant.tinted =>
        Border.all(color: widget.borderColor ?? AppColors.borderWarmSoft),
    };

    final shadow = widget.variant == AppCardVariant.elevated
        ? AppShadows.lifted
        : (widget.variant == AppCardVariant.outlined ? AppShadows.card : null);

    Widget cardContent = Container(
      padding: widget.padding,
      child: widget.child,
    );

    if (widget.onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            widget.onTap!();
          },
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: cardContent,
        ),
      );
    }

    final card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: border,
        boxShadow: shadow,
      ),
      clipBehavior: widget.clipBehavior,
      child: cardContent,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Tone variations for [AppBadge].
enum AppBadgeTone {
  emerald,
  mint,
  amber,
  peach,
  violet,
  coral,
  neutral,
  blue,
}

/// Reusable status pill / badge used across cards, lists, and headers.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.emerald,
    this.icon,
    this.isPill = true,
    this.fontSize = 10.0,
  });

  final String label;
  final AppBadgeTone tone;
  final Widget? icon;
  final bool isPill;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppBadgeTone.emerald => (AppColors.primaryWash, AppColors.primaryDeep),
      AppBadgeTone.mint => (AppColors.primaryWashFaint, AppColors.primary),
      AppBadgeTone.amber => (AppColors.coinsBg, AppColors.warning),
      AppBadgeTone.peach => (AppColors.homePeach, AppColors.homePeachInk),
      AppBadgeTone.violet => (AppColors.homeLavender, AppColors.accentViolet),
      AppBadgeTone.coral =>
        (AppColors.error.withValues(alpha: 0.1), AppColors.error),
      AppBadgeTone.neutral => (AppColors.surfaceAlt, AppColors.textSecondary),
      AppBadgeTone.blue => (AppColors.rxBg, AppColors.rxText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isPill ? 999 : AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern interactive list tile with icon container, title, subtitle,
/// optional badge, and trailing action with ink ripple.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBg,
    this.iconColor,
    this.badgeText,
    this.trailing,
    this.onTap,
    this.isLast = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final String? badgeText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap != null
                ? () {
                    AppHaptics.selection();
                    onTap!();
                  }
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: iconBg ?? AppColors.primaryWash,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor ?? AppColors.primaryDeep,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (badgeText != null) ...[
                                const SizedBox(width: 6),
                                AppBadge(
                                  label: badgeText!,
                                  tone: AppBadgeTone.violet,
                                  isPill: false,
                                  fontSize: 9,
                                ),
                              ],
                            ],
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing ??
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}

/// Callout / notification banner.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = AppBadgeTone.emerald,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final AppBadgeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppBadgeTone.emerald => (AppColors.primaryWash, AppColors.primaryDeep),
      AppBadgeTone.mint => (AppColors.primaryWashFaint, AppColors.primary),
      AppBadgeTone.amber => (AppColors.coinsBg, AppColors.warning),
      AppBadgeTone.peach => (AppColors.homePeach, AppColors.homePeachInk),
      AppBadgeTone.violet => (AppColors.homeLavender, AppColors.accentViolet),
      AppBadgeTone.coral =>
        (AppColors.error.withValues(alpha: 0.1), AppColors.error),
      AppBadgeTone.neutral => (AppColors.surfaceAlt, AppColors.textSecondary),
      AppBadgeTone.blue => (AppColors.rxBg, AppColors.rxText),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: fg.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
