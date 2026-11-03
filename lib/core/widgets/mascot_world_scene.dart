import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Renders a whimsical, high-polish brand world featuring floating clouds,
/// twinkle sparkle stars, subtle curved horizon line, ground shadow, and an
/// animated floating mascot or brand logo matching the modern model illustration style.
class MascotWorldScene extends StatefulWidget {
  const MascotWorldScene({
    super.key,
    this.mascotAsset = 'assets/images/dr-paw-genz.png',
    this.centerWidget,
    this.mascotHeight = 240,
    this.bottomContent,
    this.topBadge,
    this.gradientColors,
    this.floating = true,
    this.showGroundShadow = true,
    this.shadowWidth,
  });

  final String mascotAsset;
  final Widget? centerWidget;
  final double mascotHeight;
  final Widget? bottomContent;
  final Widget? topBadge;
  final List<Color>? gradientColors;
  final bool floating;
  final bool showGroundShadow;
  final double? shadowWidth;

  @override
  State<MascotWorldScene> createState() => _MascotWorldSceneState();
}

class _MascotWorldSceneState extends State<MascotWorldScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bobAnimation;
  late final Animation<double> _sparkleAnimation;

  bool get _isTestEnvironment =>
      kIsWeb ? false : Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // In unit/widget tests, do not repeat indefinitely so pumpAndSettle resolves
    if (widget.floating && !_isTestEnvironment) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }

    _bobAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _sparkleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors ??
        const [
          Color(0xFF075B43), // KK Nutrivet Primary Green
          Color(0xFF054935),
          Color(0xFF033324), // Deep forest ground
        ];

    return Stack(
      children: [
        // 1. Rich Organic Background Gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // 2. Custom Painted Background Elements (Clouds, Sparkles, Horizon Arc)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: _WorldBackgroundPainter(
                  sparkleProgress: _sparkleAnimation.value,
                ),
              );
            },
          ),
        ),

        // 3. Foreground Safe Content
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final effectiveMascotHeight = h < 640
                  ? math.min(widget.mascotHeight, h * 0.28)
                  : widget.mascotHeight;

              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          if (widget.topBadge != null) ...[
                            const SizedBox(height: 14),
                            widget.topBadge!,
                          ],

                          const Spacer(flex: 3),

                          // 4. Center Character or Logo & Ground Shadow
                          AnimatedBuilder(
                            animation: _bobAnimation,
                            builder: (context, child) {
                              final baseShadowWidth = widget.shadowWidth ??
                                  (effectiveMascotHeight * 0.55);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Center Widget or Mascot Image with Bobbing Float
                                  Transform.translate(
                                    offset: Offset(0, _bobAnimation.value),
                                    child: widget.centerWidget ??
                                        Image.asset(
                                          widget.mascotAsset,
                                          height: effectiveMascotHeight,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => Icon(
                                            Icons.pets_rounded,
                                            size: effectiveMascotHeight * 0.7,
                                            color: Colors.white70,
                                          ),
                                        ),
                                  ),
                                  if (widget.showGroundShadow) ...[
                                    const SizedBox(height: 6),

                                    // Elliptical Ground Shadow
                                    Container(
                                      width: baseShadowWidth *
                                          (1.0 -
                                              (_bobAnimation.value.abs() / 45.0)),
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.28),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),

                          const Spacer(flex: 4),

                          // 5. Bottom Brand Content
                          if (widget.bottomContent != null) ...[
                            widget.bottomContent!,
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Paints the clouds, horizon curve, and glowing sparkle stars.
class _WorldBackgroundPainter extends CustomPainter {
  const _WorldBackgroundPainter({required this.sparkleProgress});

  final double sparkleProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // A. Soft Puffy Clouds in Upper Sky
    final cloudPaint = Paint()
      ..color = const Color(0xFFE6F4EA).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    // Left Upper Cloud
    _drawCloud(canvas, Offset(size.width * 0.16, size.height * 0.18), 70, cloudPaint);

    // Right Upper Cloud (Higher and wider)
    _drawCloud(canvas, Offset(size.width * 0.82, size.height * 0.12), 90, cloudPaint);

    // B. Subtle Curved Horizon Wire / Line behind mascot
    final horizonPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final horizonY = size.height * 0.52;
    final path = Path()
      ..moveTo(0, horizonY - 14)
      ..quadraticBezierTo(size.width * 0.5, horizonY + 22, size.width, horizonY - 14);
    canvas.drawPath(path, horizonPaint);

    // C. Twinkling Sparkle Stars (+ and ✦)
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45 * sparkleProgress + 0.35)
      ..style = PaintingStyle.fill;

    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 * (1.5 - sparkleProgress))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    // Cross star (+) top left
    _drawCrossStar(canvas, Offset(size.width * 0.18, size.height * 0.10), 7, crossPaint);

    // Diamond sparkle (✦) above Dr. Paw's head
    _drawDiamondSparkle(canvas, Offset(size.width * 0.54, size.height * 0.28), 11 * sparkleProgress, starPaint);

    // Small cross (+) top right
    _drawCrossStar(canvas, Offset(size.width * 0.82, size.height * 0.29), 6, crossPaint);

    // Mid-left cross (+) near horizon
    _drawCrossStar(canvas, Offset(size.width * 0.18, size.height * 0.40), 8 * sparkleProgress, crossPaint);

    // Mid-right cross (+) near horizon
    _drawCrossStar(canvas, Offset(size.width * 0.84, size.height * 0.42), 6.5, crossPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double baseRadius, Paint paint) {
    // Draw an organic cloud composed of intersecting circles
    canvas.drawCircle(center, baseRadius * 0.65, paint);
    canvas.drawCircle(center + Offset(-baseRadius * 0.45, baseRadius * 0.15), baseRadius * 0.45, paint);
    canvas.drawCircle(center + Offset(baseRadius * 0.45, baseRadius * 0.15), baseRadius * 0.48, paint);
    canvas.drawCircle(center + Offset(baseRadius * 0.80, baseRadius * 0.25), baseRadius * 0.32, paint);
    canvas.drawCircle(center + Offset(-baseRadius * 0.75, baseRadius * 0.25), baseRadius * 0.32, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, baseRadius * 0.32),
          width: baseRadius * 1.6,
          height: baseRadius * 0.5,
        ),
        Radius.circular(baseRadius * 0.25),
      ),
      paint,
    );
  }

  void _drawCrossStar(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
  }

  void _drawDiamondSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WorldBackgroundPainter oldDelegate) =>
      oldDelegate.sparkleProgress != sparkleProgress;
}
