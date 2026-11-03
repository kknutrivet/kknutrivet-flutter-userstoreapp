import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/welcome_art.dart';
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
 {
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeCanvas,
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const WelcomeArt(icon: Icons.pets_rounded),
        const SizedBox(height: 32),
        Text('KK Nutrivet', style: AppTheme.serif(fontSize: 32)),
        const SizedBox(height: 12),
        const Text('Nutrition. Wellness. Veterinary care.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        const SizedBox(height: 40),
        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Opening KK Nutrivet')),
      ])),
    ))),
  );
}
