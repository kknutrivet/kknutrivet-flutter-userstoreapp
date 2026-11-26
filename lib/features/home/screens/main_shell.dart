import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../providers/app_providers.dart';

/// Persistent mobile navigation with a cart dock outside page content.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final user = ref.watch(authProvider).value;
    final rawName = user?.name?.trim() ?? '';
    final isRealAccount =
        user != null && rawName.isNotEmpty && rawName.toLowerCase() != 'guest';
    final displayUserName = isRealAccount
        ? rawName.split(RegExp(r'\s+')).first
        : null;

    final showFloatingCart =
        cartCount > 0 &&
        navigationShell.currentIndex != 2 &&
        navigationShell.currentIndex != 3 &&
        navigationShell.currentIndex != 4;

    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          AppHaptics.tap();
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: navigationShell),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: AnimatedSwitcher(
                duration: AppMotion.normal,
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeIn,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: showFloatingCart
                    ? CartFloatingBar(
                        key: const ValueKey('floating_cart_bar'),
                        count: cartCount,
                        total: cartTotal,
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('floating_cart_empty'),
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

class WebsiteBottomNav extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final dark = currentIndex == 3;
    final selectedColor = dark ? const Color(0xFFC9FF67) : Colors.white;
    final idleColor = dark ? Colors.white70 : AppColors.textSecondary;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final useCompactMargins = screenWidth < 350 || textScale > 1.3;

    return ColoredBox(
      color: dark ? const Color(0xFF0A1411) : AppColors.homeBackground,
      child: SafeArea(
        top: false,
        minimum: useCompactMargins
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF14241E) : Colors.white,
            borderRadius: useCompactMargins
                ? BorderRadius.zero
                : BorderRadius.circular(28),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.10)
                  : const Color(0xFFDCE7E1),
              width: 1,
            ),
            boxShadow: useCompactMargins
                ? const []
                : [
                    BoxShadow(
                      color: dark
                          ? Colors.black.withValues(alpha: 0.45)
                          : const Color(0x1807271F),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 64 +
                (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 24),
            elevation: 0,
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: dark ? const Color(0xFF14241E) : Colors.white,
            indicatorColor:
                dark ? const Color(0xFF275345) : AppColors.primaryDeep,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? (dark ? const Color(0xFFC9FF67) : AppColors.primaryDeep)
                    : idleColor,
              );
            }),
            destinations: [
              for (final entry in [
                (Icons.home_outlined, Icons.home_rounded, strings.navHome),
                (Icons.storefront_outlined, Icons.storefront_rounded, strings.navShop),
                (
                  Icons.medical_services_outlined,
                  Icons.medical_services_rounded,
                  strings.navCare,
                ),
                (
                  Icons.smart_display_outlined,
                  Icons.smart_display_rounded,
                  strings.navShots,
                ),
                (
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  strings.navAccount,
                ),
              ])
                NavigationDestination(
                  icon: Icon(entry.$1, size: 22, color: idleColor),
                  selectedIcon: Icon(entry.$2, size: 22, color: selectedColor),
                  label: entry.$3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating cart pill matching the quick-commerce pill design (overlapping circular thumbnails, two-line text, circular chevron).
class CartFloatingBar extends ConsumerWidget {
  const CartFloatingBar({super.key, required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider).value ?? const [];

    final List<String> imageUrls = [];
    for (final item in cartItems.reversed) {
      final candidate =
          item.comboImage ??
          item.product?.image ??
          (item.product?.images.isNotEmpty == true
              ? item.product!.images.first
              : null);
      if (candidate != null &&
          candidate.trim().isNotEmpty &&
          !imageUrls.contains(candidate.trim())) {
        imageUrls.add(candidate.trim());
        if (imageUrls.length >= 2) break;
      }
    }

    final String itemLabel = count == 1 ? '1 item' : '$count items';
    final String subtitle = total > 0
        ? '$itemLabel · ₹${total.toStringAsFixed(0)}'
        : itemLabel;

    return Semantics(
      button: true,
      label:
          'View cart, $count ${count == 1 ? "item" : "items"}, total ₹${total.toStringAsFixed(0)}',
      child: Center(
        child: AppBounce(
          pressedScale: 0.95,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0C7A43),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C7A43).withValues(alpha: 0.34),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  AppHaptics.tap();
                  context.push('/cart');
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (imageUrls.isEmpty)
                        _thumbCircle(null)
                      else if (imageUrls.length == 1)
                        _thumbCircle(imageUrls.first)
                      else
                        SizedBox(
                          width: 54,
                          height: 34,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                child: _thumbCircle(imageUrls[0]),
                              ),
                              Positioned(
                                left: 20,
                                child: _thumbCircle(imageUrls[1]),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 10),
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
                              height: 1.15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          AppTextSwitcher(
                            text: subtitle,
                            style: AppTheme.sans(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbCircle(String? url) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const AppLoader(
                  size: 14,
                  strokeWidth: 1.5,
                  color: AppColors.primaryDeep,
                ),
                errorWidget: (_, _, _) => const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: Color(0xFF0C7A43),
                ),
              )
            : const Icon(
                Icons.shopping_bag_outlined,
                size: 16,
                color: Color(0xFF0C7A43),
              ),
      ),
    );
  }
}
