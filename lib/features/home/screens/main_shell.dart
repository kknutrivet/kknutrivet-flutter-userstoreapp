import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/lottie_nav_icon.dart';
import '../../../providers/app_providers.dart';

/// Single Source of Truth: `src/components/MobileBottomNav.tsx`
///
/// Exact 5 primary navigation tabs:
/// 1. Home (/home)
/// 2. Shop (/products)
/// 3. Consult (/consultations) — Raised 52×52dp circular emerald button
/// 4. Health (/diseases)
/// 5. Account (/profile)
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final user = ref.watch(authProvider).value;
    final rawName = user?.name?.trim() ?? '';
    final isRealAccount = user != null &&
        rawName.isNotEmpty &&
        rawName.toLowerCase() != 'guest';
    final displayUserName =
        isRealAccount ? rawName.split(RegExp(r'\s+')).first : null;

    final showFloatingCart = cartCount > 0 &&
        navigationShell.currentIndex != 2 &&
        navigationShell.currentIndex != 3 &&
        navigationShell.currentIndex != 4;

    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && navigationShell.currentIndex != 0) {
          AppHaptics.tap();
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: IgnorePointer(
                ignoring: !showFloatingCart,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  offset:
                      showFloatingCart ? Offset.zero : const Offset(0, 1.4),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    opacity: showFloatingCart ? 1.0 : 0.0,
                    child: CartFloatingBar(
                      count: cartCount,
                      total: cartTotal,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: WebsiteBottomNav(
          currentIndex: navigationShell.currentIndex,
          userFirstName: displayUserName,
          onTap: (i) {
            AppHaptics.selection();
            if (i == 4 && !isRealAccount) {
              ref.read(pendingAuthRedirectProvider.notifier).state = '/profile';
              context.push('/login');
              return;
            }
            navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class WebsiteBottomNav extends StatefulWidget {
  const WebsiteBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userFirstName,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? userFirstName;

  @override
  State<WebsiteBottomNav> createState() => _WebsiteBottomNavState();
}

class _WebsiteBottomNavState extends State<WebsiteBottomNav> {
  final List<int> _tapCounts = [0, 0, 0, 0, 0];

  static const _labels = ['Home', 'Shop', 'Consult', 'Shots', 'Account'];
  static const _lottieIcons = [
    NavLottieIcon.home,
    NavLottieIcon.shop,
    NavLottieIcon.consult,
    NavLottieIcon.shots,
    NavLottieIcon.account,
  ];

  void _handleTap(int index) {
    setState(() {
      _tapCounts[index]++;
    });
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isShots = widget.currentIndex == 3;
    return Container(
      decoration: BoxDecoration(
        color: isShots ? const Color(0xD9000000) : AppColors.surface,
        borderRadius: isShots
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(
          top: BorderSide(
            color: isShots
                ? Colors.white.withValues(alpha: 0.10)
                : AppColors.textPrimary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14173C32),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(5, (i) {
                  if (i == 2) {
                    return Expanded(
                      child: _consultNavItem(context),
                    );
                  }
                  return Expanded(child: _standardNavItem(context, i));
                }),
              ),
              Positioned(
                top: -18,
                child: _floatingConsultButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _standardNavItem(BuildContext context, int i) {
    final selected = widget.currentIndex == i;
    final isShots = widget.currentIndex == 3;
    final isAccount = i == 4;
    final hasRealAccount =
        widget.userFirstName != null && widget.userFirstName!.isNotEmpty;
    final displayLabel =
        isAccount ? (widget.userFirstName ?? 'Sign in') : _labels[i];

    return Semantics(
      button: true,
      selected: selected,
      label: displayLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(i),
          splashColor: AppColors.primaryWash,
          highlightColor: AppColors.primaryWashFaint,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 24,
                decoration: BoxDecoration(
                  color: selected
                      ? (isShots
                          ? const Color(0x3310B981)
                          : AppColors.primaryWash)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (isAccount && hasRealAccount) ? 0.0 : 1.0,
                        child: LottieNavIcon(
                          icon: _lottieIcons[i],
                          isSelected: selected,
                          size: 22,
                          color: selected
                              ? (isShots
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF137656))
                              : (isShots
                                  ? Colors.white60
                                  : AppColors.textSecondary),
                          playOnTapTrigger: _tapCounts[i],
                        ),
                      ),
                      if (isAccount && hasRealAccount)
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.successBg,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            widget.userFirstName![0].toUpperCase(),
                            style: AppTheme.sans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                  color: selected
                      ? (isShots
                          ? const Color(0xFF34D399)
                          : const Color(0xFF137656))
                      : (isShots ? Colors.white60 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingConsultButton(BuildContext context) {
    final selected = widget.currentIndex == 2;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Consult a Vet',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _handleTap(2),
          splashColor: Colors.white24,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF064A37)
                  : const Color(0xFF07583F),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF07583F)
                      .withValues(alpha: selected ? 0.45 : 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: LottieNavIcon(
                icon: NavLottieIcon.consult,
                isSelected: selected,
                size: 25,
                color: Colors.white,
                playOnTapTrigger: _tapCounts[2],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _consultNavItem(BuildContext context) {
    final selected = widget.currentIndex == 2;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Consult a Vet',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(2),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Consult',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.sans(
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                  color: selected
                      ? const Color(0xFF137656)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating cart pill matching the quick-commerce pill design (image thumbnail, two-line text, chevron).
class CartFloatingBar extends ConsumerWidget {
  const CartFloatingBar({
    super.key,
    required this.count,
    required this.total,
  });

  final int count;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider).value ?? const [];

    String? imageUrl;
    if (cartItems.isNotEmpty) {
      for (final item in cartItems.reversed) {
        final candidate = item.comboImage ??
            item.product?.image ??
            (item.product?.images.isNotEmpty == true
                ? item.product!.images.first
                : null);
        if (candidate != null && candidate.trim().isNotEmpty) {
          imageUrl = candidate;
          break;
        }
      }
    }

    final String itemLabel = count == 1 ? '1 item' : '$count items';
    final String subtitle =
        total > 0 ? '$itemLabel · ₹${total.toStringAsFixed(0)}' : itemLabel;

    return Semantics(
      button: true,
      label:
          'View cart, $count ${count == 1 ? "item" : "items"}, total ₹${total.toStringAsFixed(0)}',
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E7E26),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.90),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF07583F).withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () {
                AppHaptics.tap();
                context.push('/cart');
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.all(2.5),
                      child: ClipOval(
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, _) => const Center(
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Color(0xFF1E7E26),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 18,
                                  color: Color(0xFF1E7E26),
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag_outlined,
                                size: 18,
                                color: Color(0xFF1E7E26),
                              ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'View cart',
                          style: AppTheme.sans(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          subtitle,
                          style: AppTheme.sans(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 20,
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
