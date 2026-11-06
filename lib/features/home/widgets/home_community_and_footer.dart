import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../providers/app_providers.dart';
import 'home_models_and_data.dart';

// ── 14. KnowledgeRail ("Pet Care Knowledge") ───────────────────────────────
class HomeKnowledgeRail extends ConsumerWidget {
  const HomeKnowledgeRail({super.key, this.selectedAnimal});
  final String? selectedAnimal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(homeBlogPostsProvider);
    return postsAsync.maybeWhen(
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();
        final filtered = selectedAnimal != null && selectedAnimal!.isNotEmpty
            ? posts.where((p) {
                final needle =
                    selectedAnimal!.toLowerCase().split('/').first.trim();
                return p.title.toLowerCase().contains(needle) ||
                    (p.category?.toLowerCase().contains(needle) ?? false) ||
                    (p.excerpt?.toLowerCase().contains(needle) ?? false);
              }).toList()
            : posts;
        final shown = (filtered.isNotEmpty ? filtered : posts).take(4).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const HomeSectionTitle(
                  title: 'Pet Care Knowledge',
                  route: '/blog',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final post = shown[i];
                      final first = i == 0;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Haptics.tap();
                            context.push('/blog/${post.slug}');
                          },
                          child: Container(
                            width: first ? 292 : 258,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: first
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 104,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryWashFaint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: AppNetworkImage(
                                    imageUrl: post.coverImage,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 200,
                                    fallbackIcon: Icons.article_outlined,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (post.category != null)
                                        Text(
                                          post.category!.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 8,
                                            letterSpacing: 0.8,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        post.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.serif(
                                          fontSize: first ? 12.5 : 11.5,
                                          height: 1.25,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Read more →',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── 15. CareSpaceCard (after KnowledgeRail, hidden for livestock) ──────────
class HomeCareSpaceCard extends ConsumerWidget {
  const HomeCareSpaceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final petsAsync = ref.watch(homePetsProvider);

    if (user == null) {
      return _careSpaceEmpty(
        context,
        title: 'Start your care space',
        body:
            'Create a pet profile to keep growth, reminders and records together.',
        route: '/login',
      );
    }
    return petsAsync.maybeWhen(
      data: (pets) {
        if (pets.isEmpty) {
          return _careSpaceEmpty(
            context,
            title: 'Start your care space',
            body:
                'Create a pet profile to keep growth, reminders and records together.',
            route: '/pets/new',
          );
        }
        final pet = pets.first;
        final ageMonths = pet.ageInMonths;
        final ageLabel = ageMonths == null
            ? null
            : ageMonths >= 12
                ? '${ageMonths ~/ 12} yr'
                : '$ageMonths mo';
        final meta = [
          if (pet.breed?.isNotEmpty == true)
            pet.breed
          else if (pet.animalType.isNotEmpty)
            pet.animalType,
          ?ageLabel,
          if (pet.weightKg != null) '${pet.weightKg} kg',
        ].join(' · ');
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Haptics.tap();
                context.push('/pets/${pet.id}');
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryWashFaint,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                          ? AppNetworkImage(
                              imageUrl: pet.photoUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              fallbackIcon: Icons.pets,
                            )
                          : Image.asset(
                              'assets/images/animal-categories/dog.webp',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.pets,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR CARE SPACE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pet.name.isNotEmpty ? pet.name : 'Your pet',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (meta.isNotEmpty)
                            Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'My Pets',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => _careSpaceEmpty(
        context,
        title: 'Start your care space',
        body:
            'Create a pet profile to keep growth, reminders and records together.',
        route: '/pets/new',
      ),
    );
  }

  Widget _careSpaceEmpty(
    BuildContext context, {
    required String title,
    required String body,
    required String route,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.tap();
            context.push(route);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryWash,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 22,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 16. MemberBenefitsRail ("More with KK Nutrivet") ───────────────────────
class HomeMemberBenefits extends StatelessWidget {
  const HomeMemberBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    const cards = [
      (
        Icons.history_rounded,
        'Your care history in one place',
        'Past orders, prescriptions and consultations kept together, ready to reorder.',
        "See what's saved",
        '/orders',
        AppColors.infoBg,
        AppColors.borderSubtle,
        AppColors.infoBg,
        AppColors.info,
        AppColors.info,
      ),
      (
        Icons.card_giftcard_outlined,
        'Earn 100 referral coins',
        'Share your personal link. Your friend gets 50 coins and you get 100 after they join and shop.',
        'See referral rewards',
        '/referral',
        AppColors.homeLavender,
        AppColors.borderSubtle,
        AppColors.homeLavender,
        AppColors.homeLavenderInk,
        AppColors.homeLavenderInk,
      ),
      (
        Icons.monetization_on_outlined,
        'KK Coins on every order',
        'Earn 1 coin per ₹10 after delivery. Each coin gives ₹1 off a future order.',
        'Learn about coins',
        '/referral',
        AppColors.homeSoftYellow,
        AppColors.borderWarmSoft,
        AppColors.homeSoftYellow,
        AppColors.homeYellowInk,
        AppColors.homeYellowInk,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 13,
                color: AppColors.primaryDeep,
              ),
              SizedBox(width: 6),
              Text(
                'MORE THAN A MEDICINE STORE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'More with KK Nutrivet',
            style: AppTheme.serif(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: cards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = cards[i];
                return Material(
                  color: c.$6,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Haptics.tap();
                      context.push(c.$5);
                    },
                    child: Container(
                      width: 232,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.$7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c.$8,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(c.$1, size: 20, color: c.$9),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            c.$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              c.$3,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.$4,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: c.$10,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 13,
                                color: c.$10,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 17. BrandsRail ("Top brands you can trust") ────────────────────────────
class HomeBrandsRail extends ConsumerWidget {
  const HomeBrandsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(homeBrandsProvider);
    return brandsAsync.maybeWhen(
      data: (brands) {
        final withLogos =
            brands.where((b) => b.logo != null).take(10).toList();
        if (withLogos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const HomeSectionTitle(
                  title: 'Top brands you can trust',
                  route: '/products',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: withLogos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final brand = withLogos[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Haptics.tap();
                            context.push(
                              '/products?search=${Uri.encodeComponent(brand.name)}',
                            );
                          },
                          child: Container(
                            width: 104,
                            height: 56,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AppNetworkImage(
                              imageUrl: brand.logo,
                              height: 28,
                              fit: BoxFit.contain,
                              memCacheWidth: 200,
                              errorWidget: (_, _, _) => Text(
                                brand.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ── 18. HelpRails (WhatsApp gradient rail) ─────────────────────────────────
class HomeHelpRail extends StatelessWidget {
  const HomeHelpRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Haptics.tap();
            launchUrl(
              Uri.parse(
                'https://wa.me/917846932453?text=${Uri.encodeComponent('Hi KK Nutrivet, I need help choosing the right product.')}',
              ),
              mode: LaunchMode.externalApplication,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDeepest, AppColors.primaryDeep],
              ),
              border: Border.all(color: AppColors.primaryDeep),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.cartBarBadgeBg,
                  child: Icon(
                    Icons.chat_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need help choosing?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Get help finding the right food, medicine or supplement.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 19. MobileSiteFooter (dark, #1A1D1C) ─────────────────────────────────────
class HomeMobileFooter extends StatefulWidget {
  const HomeMobileFooter({super.key});

  @override
  State<HomeMobileFooter> createState() => _HomeMobileFooterState();
}

class _HomeMobileFooterState extends State<HomeMobileFooter> {
  static const _columns = [
    (
      'Shop',
      [
        ('All Products', '/products'),
        ('Dogs', '/products?animalType=Dog'),
        ('Cats', '/products?animalType=Cat'),
        ('Cattle', '/products?animalType=Cattle'),
        ('Poultry', '/products?animalType=Poultry'),
      ],
    ),
    (
      'Vet Care',
      [
        ('Consult a Vet', '/consultations'),
        ('Pet Profiles', '/pets'),
        ('Dr. Paw AI', '/vet'),
      ],
    ),
    (
      'Help',
      [
        ('Shipping', '/info/shipping'),
        ('Returns & Refunds', '/info/returns'),
        ('FAQ', '/help'),
        ('Contact', '/help'),
      ],
    ),
    (
      'Company',
      [
        ('About', '/info/about'),
        ('Blog', '/blog'),
        ('Terms', '/info/terms'),
        ('Privacy Policy', '/info/privacy'),
      ],
    ),
  ];

  String? _open;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: const BoxDecoration(color: AppColors.footerBg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 36,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            color: Colors.white,
            errorBuilder: (_, _, _) => const Text(
              'KK NUTRIVET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Genuine veterinary medicines, nutrition and care essentials for every animal in your family and farm.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.footerText,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('mailto:kknutrivet@gmail.com'),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 15,
                    color: AppColors.footerText,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'kknutrivet@gmail.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.footerText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => launchUrl(Uri.parse('tel:+917846932453')),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 15,
                    color: AppColors.footerText,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '+91 78469 32453',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.footerText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bapuji Nagar 5th Lane, Tower Lane, Brahmapur, Odisha 760004',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.footerText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              children: _columns.map((col) {
                final open = _open == col.$1;
                return Column(
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _open = open ? null : col.$1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                col.$1.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: open ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: col.$2
                              .map(
                                (link) => InkWell(
                                  onTap: () => context.push(link.$2),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(
                                        link.$1,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.footerText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      crossFadeState: open
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© ${DateTime.now().year} KK Nutrivet · GSTIN 21BTUPP5889C1Z5',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.footerMuted,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }
}
