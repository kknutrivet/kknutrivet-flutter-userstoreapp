import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// Reusable native progress loader indicator with brand colors and standard sizes.
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.5,
    this.color,
  });

  const AppLoader.small({super.key})
      : size = 16.0,
        strokeWidth = 2.0,
        color = null;

  const AppLoader.large({super.key})
      : size = 36.0,
        strokeWidth = 3.0,
        color = null;

  const AppLoader.white({super.key, this.size = 20.0})
      : strokeWidth = 2.0,
        color = Colors.white;

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor:
              AlwaysStoppedAnimation<Color>(color ?? AppColors.primaryDeep),
        ),
      ),
    );
  }
}

/// Fullscreen or modal loading overlay with optional status message.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
  });

  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.lifted,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(size: 32, strokeWidth: 3),
              if (message != null) ...[
                const SizedBox(height: 14),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Standardized empty state view with illustration icon, title, description and CTA.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primaryWash,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppColors.primaryDeep),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.serif(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                size: AppButtonSize.md,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
