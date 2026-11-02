import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../models/homepage_section.dart';
import 'home_models_and_data.dart';

// ── 3b. HeroBanner: Native-feel ViewPager Carousel (HeroBanner.tsx) ──────────
class HomeHeroCarousel extends ConsumerStatefulWidget {
  const HomeHeroCarousel({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  @override
  ConsumerState<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HeroSlide {
  const _HeroSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.cta,
    required this.icon,
    required this.image,
    required this.imageCover,
    required this.route,
    required this.bg,
    required this.chipBg,
    required this.chipText,
    required this.bodyColor,
    required this.accent,
  });
  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final IconData icon;
  final String image;
  final bool imageCover;
  final String route;
  final List<Color> bg;
  final Color chipBg;
  final Color chipText;
  final Color bodyColor;
  final Color accent;
}

class _HomeHeroCarouselState extends ConsumerState<HomeHeroCarousel> {
  static const int _kLoopMultiplier = 1000;
  static const double _kViewportFraction = 0.92;
  static const Duration _kAutoAdvanceInterval = Duration(milliseconds: 4000);
  static const Duration _kPageTransitionDuration = Duration(milliseconds: 550);

  List<_HeroSlide> _getSlides(HeroSectionContent? dynamicHero) {
    final shopRoute = widget.selectedAnimal != null &&
            widget.selectedAnimal!.isNotEmpty
        ? '/products?animalType=${Uri.encodeComponent(widget.selectedAnimal!)}'
        : '/products';

    if (dynamicHero != null && dynamicHero.slides.isNotEmpty) {
      return dynamicHero.slides.map((s) {
        final route = (s.route == '/products' &&
                widget.selectedAnimal != null &&
                widget.selectedAnimal!.isNotEmpty)
            ? shopRoute
            : s.route;
        return _HeroSlide(
          eyebrow: s.eyebrow,
          title: s.title,
          body: s.body,
          cta: s.cta,
          icon: s.icon,
          image: s.image,
          imageCover: s.imageCover,
          route: route,
          bg: s.bg,
          chipBg: s.chipBg,
          chipText: s.chipText,
          bodyColor: s.bodyColor,
          accent: s.accent,
        );
      }).toList();
    }

    return [
      _HeroSlide(
        eyebrow: 'Health · Care · Trust',
        title: 'Care for all animals.',
        body: 'Genuine food, medicines and daily care.',
        cta: 'Shop Now',
        icon: Icons.shopping_bag_outlined,
        image: 'assets/marketing_image/hero-animals-cutout-v1.png',
        imageCover: false,
        route: shopRoute,
        bg: const [Color(0xFFF4F8EE), Color(0xFFE0EFE2)],
        chipBg: const Color(0xB2FFFFFF),
        chipText: AppColors.primaryDeep,
        bodyColor: const Color(0xFF38594C),
        accent: const Color(0xFFB9412E),
      ),
      const _HeroSlide(
        eyebrow: 'Veterinarian',
        title: 'Care without the travel.',
        body: 'Chat with a certified vet — share photos or videos & get digital Rx.',
        cta: 'Consult a Vet',
        icon: Icons.medical_services_outlined,
        image: 'assets/marketing_image/online-vet-consultation-v1.webp',
        imageCover: true,
        route: '/consultations',
        bg: [Color(0xFFF4F8EE), Color(0xFFE0EFE2)],
        chipBg: Color(0xB2FFFFFF),
        chipText: AppColors.primaryDeep,
        bodyColor: Color(0xFF38594C),
        accent: Color(0xFFB9412E),
      ),
      const _HeroSlide(
        eyebrow: 'Daily Nutrition',
        title: "Estimate today's bowl.",
        body: "A starting portion for today's healthy meal.",
        cta: 'Calculate Portion',
        icon: Icons.calculate_outlined,
        image: 'assets/marketing_image/hero-animals-cutout-v1.png',
        imageCover: false,
        route: '/calculator',
        bg: [Color(0xFFEEF8F0), Color(0xFFC5E4CE)],
        chipBg: Color(0xCCFFFFFF),
        chipText: Color(0xFF0B4A3A),
        bodyColor: Color(0xCC123F33),
        accent: AppColors.primaryDeep,
      ),
    ];
  }

  late final PageController _controller;
  late int _currentPage;
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    const initialPage = (3 * (_kLoopMultiplier ~/ 2));
    _currentPage = initialPage;
    _controller = PageController(
      initialPage: initialPage,
      viewportFraction: _kViewportFraction,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_kAutoAdvanceInterval, (_) {
      if (!mounted || _isUserInteracting || !_controller.hasClients) return;
      _controller.nextPage(
        duration: _kPageTransitionDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onPointerDown() {
    _isUserInteracting = true;
    _timer?.cancel();
  }

  void _onPointerUp() {
    _isUserInteracting = false;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroSection = ref.watch(homeHeroSectionProvider);
    final slides = _getSlides(heroSection);
    final activeIndex = slides.isEmpty ? 0 : _currentPage % slides.length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // ViewPager with native touch listener
          Listener(
            onPointerDown: (_) => _onPointerDown(),
            onPointerUp: (_) => _onPointerUp(),
            onPointerCancel: (_) => _onPointerUp(),
            child: SizedBox(
              height: 184,
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  final slideIndex = index % slides.length;
                  final slide = slides[slideIndex];

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double diff = 0.0;
                      if (_controller.position.haveDimensions) {
                        final page = _controller.page ?? _currentPage.toDouble();
                        diff = (page - index).abs().clamp(0.0, 1.0);
                      } else {
                        diff = (_currentPage - index).abs().clamp(0.0, 1.0).toDouble();
                      }

                      final scale = 1.0 - (diff * 0.045);
                      final opacity = 1.0 - (diff * 0.12);

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      );
                    },
                    child: _slideCard(context, slide, slideIndex, slides.length),
                  );
                },
              ),
            ),
          ),

          // Clean native pill indicators
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final isSelected = activeIndex == i;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: 'Slide ${i + 1} of ${slides.length}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Haptics.selection();
                      final offset = i - activeIndex;
                      _controller.animateToPage(
                        _currentPage + offset,
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFCAD7D0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slideCard(
    BuildContext context,
    _HeroSlide slide,
    int index,
    int total,
  ) {
    return Semantics(
      label: '${index + 1} of $total: ${slide.title}. Tap to open.',
      button: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.bg,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: slide.accent.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            const BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AppBounce(
          pressedScale: 0.985,
          onTap: () {
            Haptics.tap();
            context.push(slide.route);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
                // Ambient decorative background circle
                Positioned(
                  right: -30,
                  top: 15,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
                  ),
                ),

                // Responsive two-column content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Text Column
                    Expanded(
                      flex: 58,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Eyebrow badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: slide.chipBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: slide.accent.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                slide.eyebrow.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w800,
                                  color: slide.chipText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Title
                            Text(
                              slide.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.15,
                                letterSpacing: -0.4,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Body
                            Text(
                              slide.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: slide.bodyColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // CTA Pill
                            Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: slide.accent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.accent.withValues(alpha: 0.28),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    slide.icon,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      slide.cta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Illustration / Photo Column
                    Expanded(
                      flex: 42,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(22),
                            bottomRight: Radius.circular(22),
                          ),
                          child: (slide.image.startsWith('http') ||
                                  slide.image.startsWith('/'))
                              ? AppNetworkImage(
                                  imageUrl: slide.image,
                                  fit: slide.imageCover
                                      ? BoxFit.cover
                                      : BoxFit.contain,
                                  alignment: slide.imageCover
                                      ? const Alignment(0.32, 0)
                                      : Alignment.bottomRight,
                                  fallbackIcon: Icons.pets_outlined,
                                )
                              : Image.asset(
                                  slide.image,
                                  fit: slide.imageCover
                                      ? BoxFit.cover
                                      : BoxFit.contain,
                                  alignment: slide.imageCover
                                      ? const Alignment(0.32, 0)
                                      : Alignment.bottomRight,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
  }
}
