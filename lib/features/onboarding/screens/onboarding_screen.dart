import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
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
    imagePath: 'assets/images/mobile-shop-hero-v3.webp',
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
    imagePath: 'assets/images/prescription-img.webp',
    fallbackIcon: Icons.receipt_long_outlined,
    title: 'Prescription Concierge',
    subtitle: 'FREE PRESCRIPTION REVIEW',
    description:
        'Simply snap a photo of your vet prescription. Our pharmacology team verifies every dosage, matches exact compositions, and prepares your cart.',
    highlights: [
      'Camera or gallery photo upload',
      'Dosage and generic composition check',
      'Dedicated pharmacist follow-up',
    ],
    accentColor: Color(0xFFC4933C),
    badge1: (text: 'Camera or gallery photo', icon: Icons.camera_alt_rounded),
    badge2: (text: 'Pharmacist Review', icon: Icons.fact_check_rounded),
  ),
  _OnboardingSlide(
    imagePath: 'assets/images/pet-profile-care-v1.webp',
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
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 38,
                            semanticLabel: 'KK Nutrivet',
                          ),
                        ),
                      ),
                      TextButton(onPressed: _finish, child: const Text('Skip')),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: AspectRatio(
                                aspectRatio: 1.12,
                                child: index == 2
                                    ? Container(
                                        color: const Color(0xFFE9F1E8),
                                        padding: const EdgeInsets.all(28),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.description_outlined,
                                                  size: 42,
                                                  color: AppColors.primaryDeep,
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Your prescription',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Photo → Review → Products',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        slide.imagePath,
                                        fit: BoxFit.cover,
                                        alignment: index == 0
                                            ? Alignment.centerRight
                                            : const Alignment(.45, 0),
                                        excludeFromSemantics: true,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              [
                                'SHOP WITH CONFIDENCE',
                                'CARE, WITH SUPPORT',
                                'PRESCRIPTIONS MADE SIMPLE',
                                'EVERYDAY WELLNESS',
                              ][index],
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              slide.title,
                              style: AppTheme.serif(fontSize: 30),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              [
                                'Find nutrition, medicines and everyday essentials for your pets and farm animals.',
                                'Share your concern with the care team and book veterinary support when you need it.',
                                'Upload a clear photo of your prescription. Our team will review it and help you find the products you need.',
                                'Keep animal profiles and care dates together, with Dr. Paw AI for everyday questions.',
                              ][index],
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Step ${_index + 1} of ${_slides.length}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _index ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? AppColors.primaryDeep
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (_index > 0) ...[
                            IconButton(
                              onPressed: _previous,
                              tooltip: 'Back',
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: FilledButton(
                              onPressed: isLast ? _finish : _next,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  isLast ? 'Explore KK Nutrivet' : 'Continue',
                                ),
                              ),
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
        ),
      ),
    );
  }
}
