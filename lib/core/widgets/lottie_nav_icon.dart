import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Supported Lottie navigation icon types matching the web's `LottieNavIcon.tsx`.
enum NavLottieIcon {
  home(
    'assets/lottie/nav_home.json',
    Icons.home_rounded,
    Icons.home_outlined,
  ),
  shop(
    'assets/lottie/nav_shop.json',
    Icons.shopping_bag_rounded,
    Icons.shopping_bag_outlined,
  ),
  consult(
    'assets/lottie/nav_consult.json',
    Icons.medical_services_rounded,
    Icons.medical_services_rounded,
  ),
  health(
    'assets/lottie/nav_health.json',
    Icons.monitor_heart_rounded,
    Icons.monitor_heart_outlined,
  ),
  shots(
    'assets/lottie/nav_health.json',
    Icons.movie_creation_rounded,
    Icons.movie_creation_outlined,
  ),
  account(
    'assets/lottie/nav_account.json',
    Icons.person_rounded,
    Icons.person_outline_rounded,
  ),
  pets(
    'assets/lottie/nav_pets.json',
    Icons.pets_rounded,
    Icons.pets_outlined,
  );

  const NavLottieIcon(this.assetPath, this.activeIcon, this.inactiveIcon);
  final String assetPath;
  final IconData activeIcon;
  final IconData inactiveIcon;
}

/// An interactive Lottie-animated navigation icon.
///
/// Triggers a micro-interaction animation when selected or tapped,
/// and tints dynamically to the active brand emerald or inactive grey.
class LottieNavIcon extends StatefulWidget {
  const LottieNavIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    this.size = 24.0,
    required this.color,
    this.playOnTapTrigger,
  });

  final NavLottieIcon icon;
  final bool isSelected;
  final double size;
  final Color color;

  /// Optional trigger value that increments on each tab tap to replay the animation.
  final int? playOnTapTrigger;

  @override
  State<LottieNavIcon> createState() => LottieNavIconState();
}

class LottieNavIconState extends State<LottieNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant LottieNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected && !oldWidget.isSelected) {
      // Transitioned to selected state
      _playAnimation();
    } else if (widget.isSelected &&
        widget.playOnTapTrigger != null &&
        widget.playOnTapTrigger != oldWidget.playOnTapTrigger) {
      // Re-tapped already selected tab
      _playAnimation();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      // Unselected - reset to initial resting frame
      _controller.reset();
    }
  }

  void _playAnimation() {
    if (_hasError) return;
    _controller.forward(from: 0.0);
  }

  /// Public method to programmatically trigger animation on tap
  void triggerTap() => _playAnimation();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      widget.isSelected ? widget.icon.activeIcon : widget.icon.inactiveIcon,
      size: widget.size,
      color: widget.color,
    );

    if (_hasError || widget.icon == NavLottieIcon.shots) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(child: fallback),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Render fallback icon for instant visual feedback and test finders
          Opacity(
            opacity: _isLoaded ? 0.0 : 1.0,
            child: fallback,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
                child: Lottie.asset(
                  widget.icon.assetPath,
                  controller: _controller,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    if (mounted && !_isLoaded) {
                      setState(() => _isLoaded = true);
                    }
                    if (widget.isSelected &&
                        !_controller.isAnimating &&
                        _controller.value == 0.0) {
                      _controller.forward(from: 0.0);
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_hasError) {
                        setState(() => _hasError = true);
                      }
                    });
                    return fallback;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
