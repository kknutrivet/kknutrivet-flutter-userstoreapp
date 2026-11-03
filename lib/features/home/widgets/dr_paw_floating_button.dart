import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/haptics.dart';

/// Floating Dr. Paw AI button matching the website's floating pet companion launcher
/// (`src/components/VetCoachWidget.tsx:1475-1505` & `GlobalDesktopDrPaw.tsx`).
///
/// Features:
/// - Vibrant gradient border: Amber -> Coral -> Violet (`#F2B457` -> `#E77A67` -> `#6954A2`)
/// - Deep green outline (`#17322B`, 2dp)
/// - Inner cream avatar container (`#FFF7E8`) with Dr. Paw GenZ avatar
/// - High-contrast Lime "AI" pill badge (`#C9FF67`)
/// - Subtle breathing pulse animation and ambient violet glow
/// - One-tap navigation to `/vet` (Dr. Paw AI Chat) with haptic feedback
class DrPawFloatingButton extends StatefulWidget {
  const DrPawFloatingButton({super.key, this.visible = true});

  final bool visible;

  @override
  State<DrPawFloatingButton> createState() => _DrPawFloatingButtonState();
}

class _DrPawFloatingButtonState extends State<DrPawFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptics.light();
    AnalyticsService.instance.logDrPawChatStarted();
    context.push('/vet');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: widget.visible ? Offset.zero : const Offset(0, 1.8),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        child: IgnorePointer(
          ignoring: !widget.visible,
          child: Semantics(
            button: true,
            label: 'Ask Dr. Paw AI veterinary assistant',
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _handleTap,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Outer Gradient Container with Glow
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, _) {
                        return Container(
                          width: 58,
                          height: 58,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF17322B),
                              width: 2,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF2B457), // Amber
                                Color(0xFFE77A67), // Coral
                                Color(0xFF6954A2), // Violet
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6954A2,
                                ).withValues(alpha: 0.40),
                                blurRadius: _glowAnimation.value,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/marketing_image/dr-paw-genz-avatar.webp',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Image.asset(
                                'assets/images/dr-paw-genz-avatar.webp',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFFFFF7E8),
                                  child: const Icon(
                                    Icons.pets_rounded,
                                    color: Color(0xFF6954A2),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // "AI" Badge on top-right
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9FF67), // Lime
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0xFF17322B),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF17322B),
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17322B),
                            height: 1.0,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
