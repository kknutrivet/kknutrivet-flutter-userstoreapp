import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.imagePath,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.highlights,
    required this.accentColor,
    required this.badge1,
    required this.badge2,
  });

  final String imagePath;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> highlights;
  final Color accentColor;
  final ({String text, IconData icon}) badge1;
  final ({String text, IconData icon}) badge2;
}

const _slides = [
  _OnboardingSlide(
    imagePath: 'assets/images/mobile-shop-hero-v3.png',
    fallbackIcon: Icons.local_hospital_outlined,
    title: 'Authentic Veterinary Care',
    subtitle: 'CERTIFIED MEDICINES & CLINICAL DIETS',
    description:
        'Shop 100% genuine prescription medicines, clinical nutrition, and wellness supplements for dogs, cats, cattle, poultry, and goats.',
    highlights: [
      'Cold-chain maintained storage',
      'Govt-licensed veterinary pharmacy',
      'Doorstep express delivery',
    ],
    accentColor: AppColors.primary,
    badge1: (text: '100% Genuine', icon: Icons.verified_rounded),
    badge2: (text: 'Cold Chain', icon: Icons.ac_unit_rounded),
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/online-vet-consultation-v1.webp',
    fallbackIcon: Icons.chat_bubble_outline_rounded,
    title: 'Consult Certified Vets',
    subtitle: 'VET CARE CHAT & DIGITAL RX',
    description:
        'Chat directly with verified veterinary doctors. Share symptom photos or videos and receive certified digital prescriptions from home.',
    highlights: [
      'Experienced veterinary specialists',
      'Photo & video diagnostic review',
      'Instant digital prescriptions',
    ],
    accentColor: Color(0xFF1B6B93),
    badge1: (text: 'Licensed Doctors', icon: Icons.medical_services_rounded),
    badge2: (text: 'Instant Digital Rx', icon: Icons.bolt_rounded),
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/prescription-img.png',
    fallbackIcon: Icons.receipt_long_outlined,
    title: 'Prescription Concierge',
    subtitle: 'FREE PRESCRIPTION REVIEW',
    description:
        'Simply snap a photo of your vet prescription. Our pharmacology team verifies every dosage, matches exact compositions, and prepares your cart.',
    highlights: [
      'Photo or PDF upload support',
      'Dosage and generic composition check',
      'Dedicated pharmacist follow-up',
    ],
    accentColor: Color(0xFFC4933C),
    badge1: (text: 'Photo or PDF', icon: Icons.camera_alt_rounded),
    badge2: (text: 'Pharmacist Review', icon: Icons.fact_check_rounded),
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/pet-profile-care-v1.png',
    fallbackIcon: Icons.pets_outlined,
    title: 'Smart Pet Care & Reminders',
    subtitle: 'VACCINATIONS & DR. PAW AI',
    description:
        'Manage digital health records for all your pets and farm animals. Track vaccination dates, deworming schedules, and get 24/7 AI guidance.',
    highlights: [
      'Vaccination & deworming alerts',
      'Multi-animal digital health passports',
      '24/7 Dr. Paw AI instant triage',
    ],
    accentColor: Color(0xFF6954A2),
    badge1: (text: 'Smart Reminders', icon: Icons.alarm_on_rounded),
    badge2: (text: 'Dr. Paw 24/7', icon: Icons.smart_toy_rounded),
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    AppHaptics.selection();
    await ref.read(onboardingProvider.notifier).complete();
    if (!mounted) return;
    context.go('/home');
  }

  void _next() {
    AppHaptics.light();
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    AppHaptics.light();
    _controller.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
    final currentSlide = _slides[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header: Brand Identity + Step Progress Bars + Skip Action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Brand Identity Pill
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2EBE5),
                                  width: 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.pets_rounded,
                                    size: 16,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'KK NUTRIVET',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Skip to Store Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _finish,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5EDE8),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Skip to Store',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Segmented Stories-style Progress Indicator
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final isPassed = i < _index;
                      final isCurrent = i == _index;
                      return Expanded(
                        child: Container(
                          height: 3.5,
                          margin: EdgeInsets.only(
                            right: i < _slides.length - 1 ? 6 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isPassed
                                ? AppColors.primaryDeep
                                : isCurrent
                                    ? currentSlide.accentColor
                                    : const Color(0xFFE2E5E3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Paged Tutorial Content with Carousel
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  AppHaptics.selection();
                  setState(() => _index = i);
                },
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 4,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Hero Illustrated Stage Card
                              _HeroIllustrationStage(slide: slide),
                              const SizedBox(height: 18),

                              // Category Chip Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: slide.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: slide.accentColor.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  slide.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: slide.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Main Slide Headline
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: AppTheme.serif(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Informative Subtitle Copy
                              Text(
                                slide.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Feature Highlights Checklist
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE9EFEA),
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: slide.highlights.map((highlight) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3.5,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: BoxDecoration(
                                              color: slide.accentColor
                                                  .withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_rounded,
                                              size: 11,
                                              color: slide.accentColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              highlight,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bottom Navigation & Action Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F8F5),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFEAEFEB),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators & Slide Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Expanding Active Pill Indicator
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(right: 6),
                            width: active ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? currentSlide.accentColor
                                  : const Color(0xFFD6DBD8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      // Step Label
                      Text(
                        'Step ${_index + 1} of ${_slides.length}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons Row: Back (if > 0) + Primary Next/Finish
                  Row(
                    children: [
                      if (_index > 0) ...[
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _previous,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFDCE4DF),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: AppButton(
                          label: isLast ? 'Explore KK Nutrivet' : 'Continue',
                          trailingIcon: Icon(
                            isLast
                                ? Icons.storefront_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.lg,
                          fullWidth: true,
                          borderRadius: 16,
                          onPressed: isLast ? _finish : _next,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Artistic Visual Stage for each onboarding slide
class _HeroIllustrationStage extends StatelessWidget {
  const _HeroIllustrationStage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2EBE5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Tinted Aura
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      slide.accentColor.withValues(alpha: 0.08),
                      slide.accentColor.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: slide.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        slide.fallbackIcon,
                        size: 46,
                        color: slide.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Badge 1 (Top Right)
          Positioned(
            top: 10,
            right: 10,
            child: _FloatingTag(
              icon: slide.badge1.icon,
              label: slide.badge1.text,
              accentColor: slide.accentColor,
            ),
          ),

          // Floating Badge 2 (Bottom Left)
          Positioned(
            bottom: 10,
            left: 10,
            child: _FloatingTag(
              icon: slide.badge2.icon,
              label: slide.badge2.text,
              accentColor: slide.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2EBE5),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
