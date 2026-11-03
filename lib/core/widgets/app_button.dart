import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Variant styling for [AppButton].
enum AppButtonVariant {
  primary,
  secondary,
  outline,
  tonal,
  ghost,
  danger,
  amber,
}

/// Size constraints for [AppButton].
enum AppButtonSize {
  sm, // 36dp height
  md, // 46-48dp height
  lg, // 52dp height
}

/// Production-grade tactile button with:
/// - Immediate pressed-state micro-scale deflection (0.97 scale on tap-down)
/// - Double-tap debounce protection (500ms)
/// - Accessible 48×48dp hit targets (Material 3 & iOS guidelines)
/// - Native haptic feedback
/// - Smooth loading state without layout shift
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
    this.semanticLabel,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
  final String? semanticLabel;
  final double? borderRadius;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  int _lastTapTimestamp = 0;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (!_isEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTimestamp < 500) {
      // Ignore rapid double taps
      return;
    }
    _lastTapTimestamp = now;
    AppHaptics.tap();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ??
        (widget.size == AppButtonSize.sm
            ? AppRadius.sm
            : (widget.size == AppButtonSize.md ? AppRadius.md : AppRadius.lg));

    final minHeight = switch (widget.size) {
      AppButtonSize.sm => 48.0,
      AppButtonSize.md => 48.0,
      AppButtonSize.lg => 52.0,
    };

    final horizontalPadding = switch (widget.size) {
      AppButtonSize.sm => 12.0,
      AppButtonSize.md => 16.0,
      AppButtonSize.lg => 20.0,
    };

    final fontSize = switch (widget.size) {
      AppButtonSize.sm => 12.5,
      AppButtonSize.md => 14.0,
      AppButtonSize.lg => 15.0,
    };

    final (backgroundColor, foregroundColor, borderColor) = _resolveColors();

    Widget content = IconTheme.merge(
      data: IconThemeData(
        color: foregroundColor,
        size: widget.size == AppButtonSize.sm ? 16 : 18,
      ),
      child: Row(
        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: widget.size == AppButtonSize.sm ? 14 : 18,
              height: widget.size == AppButtonSize.sm ? 14 : 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: foregroundColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (!widget.isLoading && widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            widget.trailingIcon!,
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight,
          maxHeight: minHeight,
          minWidth: widget.fullWidth
              ? double.infinity
              : (widget.size == AppButtonSize.sm ? 48.0 : 64.0),
        ),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(effectiveRadius),
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: minHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: widget.size == AppButtonSize.sm ? 6 : 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(effectiveRadius),
                  border: borderColor != null
                      ? Border.all(color: borderColor, width: 1.2)
                      : null,
                ),
                alignment: Alignment.center,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color bg, Color fg, Color? border) _resolveColors() {
    if (!_isEnabled) {
      return (
        AppColors.borderWarmSoft,
        AppColors.textTertiary,
        null,
      );
    }

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (
          AppColors.primaryDeep,
          Colors.white,
          null,
        );
      case AppButtonVariant.secondary:
        return (
          AppColors.primaryWash,
          AppColors.primaryDeep,
          null,
        );
      case AppButtonVariant.outline:
        return (
          Colors.white,
          AppColors.primaryDeep,
          AppColors.primary,
        );
      case AppButtonVariant.tonal:
        return (
          AppColors.primaryWashFaint,
          AppColors.primary,
          AppColors.border,
        );
      case AppButtonVariant.ghost:
        return (
          Colors.transparent,
          AppColors.primaryDeep,
          null,
        );
      case AppButtonVariant.danger:
        return (
          AppColors.error.withValues(alpha: 0.1),
          AppColors.error,
          AppColors.error.withValues(alpha: 0.3),
        );
      case AppButtonVariant.amber:
        return (
          AppColors.homePeach,
          AppColors.homePeachInk,
          null,
        );
    }
  }
}

/// Circular or square icon button with Google Play & Apple `48×48dp` tap targets,
/// pressed scale animation, and optional badge.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.size = 48.0,
    this.badgeCount,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double size;
  final int? badgeCount;
  final BoxShape shape;
  final double? borderRadius;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveFg = widget.foregroundColor ??
        (widget.backgroundColor != null &&
                (widget.backgroundColor == AppColors.primaryDeep ||
                    widget.backgroundColor == AppColors.primary ||
                    widget.backgroundColor == AppColors.brandPrimary ||
                    ThemeData.estimateBrightnessForColor(
                            widget.backgroundColor!) ==
                        Brightness.dark)
            ? Colors.white
            : AppColors.textPrimary);
    final r = widget.borderRadius ??
        (widget.shape == BoxShape.circle ? 999.0 : AppRadius.md);

    Widget btn = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.size < 48 ? 48 : widget.size,
        minHeight: widget.size < 48 ? 48 : widget.size,
      ),
      child: Center(
        child: GestureDetector(
          onTapDown: widget.onPressed != null
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: widget.onPressed != null
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed != null
              ? () {
                  AppHaptics.selection();
                  widget.onPressed!();
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: Material(
              color: widget.backgroundColor ?? Colors.transparent,
              shape: widget.shape == BoxShape.circle
                  ? const CircleBorder()
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(r),
                    ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: widget.shape,
                  borderRadius: widget.shape == BoxShape.rectangle
                      ? BorderRadius.circular(r)
                      : null,
                  border: widget.borderColor != null
                      ? Border.all(color: widget.borderColor!)
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  color: effectiveFg,
                  size: widget.size * 0.45,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.badgeCount != null && widget.badgeCount! > 0) {
      btn = Stack(
        clipBehavior: Clip.none,
        children: [
          btn,
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              child: Text(
                widget.badgeCount! > 99 ? '99+' : widget.badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// Standardized `−  N  +` quantity stepper widget with native haptics,
/// micro-scale deflection, and 48×48dp hit test areas.
class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.min = 0,
    this.max = 99,
    this.height = 36.0,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.textColor = AppColors.primaryDeep,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int min;
  final int max;
  final double height;
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: borderColor ?? AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: quantity > min,
            onTap: () {
              AppHaptics.step();
              onDecrement();
            },
            label: 'Decrease quantity',
            height: height,
            color: textColor,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Text(
                '$quantity',
                key: ValueKey<int>(quantity),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: quantity < max,
            onTap: () {
              AppHaptics.step();
              onIncrement();
            },
            label: 'Increase quantity',
            height: height,
            color: textColor,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.label,
    required this.height,
    required this.color,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String label;
  final double height;
  final Color color;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: widget.height, minHeight: widget.height),
            child: Icon(
              widget.icon,
              size: widget.height * 0.45,
              color: widget.enabled ? widget.color : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
