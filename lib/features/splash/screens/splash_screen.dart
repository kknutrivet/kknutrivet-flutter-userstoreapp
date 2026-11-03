import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

/// Shown briefly on cold start while auth/session state and the
/// first-run-tutorial flag are resolved, then routes to onboarding,
/// login, or home accordingly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
    ));

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    // Resolve session silently in the background; browsing never waits on
    // login, same as the website — home is public for everyone.
    final results = await Future.wait([
      ref.read(onboardingProvider.future),
      ref.read(authProvider.future),
      Future.delayed(const Duration(milliseconds: 700)),
    ]);
    if (!mounted) return;

    final onboardingComplete = results[0] as bool;

    final updateResult = ref.read(appUpdateCheckProvider).valueOrNull;
    if (updateResult != null && updateResult.isBlocked) {
      context.go('/update');
      return;
    }

    context.go(onboardingComplete ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Warm Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFFAF7F2),
                    Color(0xFFF3ECE1),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ), 
              ),
            ),
          ),

          // Soft Brand Watermark Ambient Rings
          Positioned(
            top: size.height * 0.28 - 150,
            left: size.width * 0.5 - 150,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.55 * _glowAnim.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryWash.withValues(alpha: 0.65),
                          const Color(0xFFFAF7F2).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main Foreground Content
          Positioned.fill(
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Animated Brand Core Section
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: ScaleTransition(
                            scale: _scaleAnim,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Sculpted Luxury App Icon Container
                            Container(
                              width: 108,
                              height: 108,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFE2EBE5),
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F07583F),
                                    blurRadius: 36,
                                    offset: Offset(0, 14),
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.pets_rounded,
                                      size: 52,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Brand Name
                            const Text(
                              'KK NUTRIVET',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Brand Tagline in Elegant Golden Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFEBD4A5),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'HEALTH  •  CARE  •  TRUST',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.8,
                                  color: Color(0xFF9E7B35),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Descriptor
                            const Text(
                              'Veterinary Medicine & Animal Healthcare',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.15,
                              ),
                            ),
                            const SizedBox(height: 38),

                            // Sleek Brand Progress Indicator
                            Container(
                              width: 38,
                              height: 38,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryWashDeep,
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0C000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
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

                const Spacer(flex: 3),

                // Bottom Trust Marker Card p;
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE5EDE8),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryWash,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            '100% Genuine Veterinary Care',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}
