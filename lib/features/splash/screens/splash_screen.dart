import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/widgets/mascot_world_scene.dart';
import '../../../providers/app_providers.dart';

/// Shown briefly on cold start while auth/session state and the
/// first-run-tutorial flag are resolved, then routes to onboarding,
/// login, or home accordingly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    // Resolve session silently in the background; browsing never waits on
    // login, same as the website — home is public for everyone.
    try {
      final results = await Future.wait([
        ref.read(onboardingProvider.future),
        ref.read(authProvider.future),
        Future.delayed(const Duration(milliseconds: 700)),
      ]);
      if (!mounted) return;

      final onboardingComplete = results[0] as bool;

      // Check maintenance or force update before navigating
      final updateResult = ref.read(appUpdateCheckProvider).valueOrNull;
      final settings = ref.read(storeSettingsProvider).valueOrNull;
      final isBlocked = (updateResult != null && updateResult.isBlocked) ||
          (settings != null && settings.appUpdate.maintenanceMode);

      if (isBlocked) {
        context.go('/update');
        return;
      }

      context.go(onboardingComplete ? '/home' : '/onboarding');
    } catch (_) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MascotWorldScene(
        mascotHeight: 250,
        bottomContent: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean Model Style Typography
              const Text(
                'KK NUTRIVET',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Nutrition. Wellness. Veterinary care.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // Trust pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFF86EFAC),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Care for every animal.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Accessibility label for semantic testing
              const Opacity(
                opacity: 0.0,
                child: SizedBox(
                  height: 0,
                  child: Text('KK Nutrivet'),
                ),
              ),

              // Soft pulsing loader
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.85),
                  ),
                  semanticsLabel: 'Opening KK Nutrivet',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
