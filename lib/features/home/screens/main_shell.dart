import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
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
            if (showFloatingCart)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: CartFloatingBar(count: cartCount, total: cartTotal),
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

class WebsiteBottomNav extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final dark = currentIndex == 3;
    final selectedColor = dark ? const Color(0xFF81D8B5) : AppColors.primaryDeep;
    final idleColor = dark ? Colors.white60 : AppColors.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dark ? Colors.white12 : AppColors.borderSubtle)),
      ),
      child: NavigationBar(
        height: 68 + (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(0, 24),
        elevation: 0,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: dark ? const Color(0xFF101916) : Colors.white,
        indicatorColor: dark ? const Color(0xFF275345) : AppColors.primaryWash,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? selectedColor : idleColor);
        }),
        destinations: [
          for (final entry in const [
            (Icons.home_outlined, Icons.home_rounded, 'Home'),
            (Icons.storefront_outlined, Icons.storefront_rounded, 'Shop'),
            (Icons.medical_services_outlined, Icons.medical_services_rounded, 'Care'),
            (Icons.smart_display_outlined, Icons.smart_display_rounded, 'Shots'),
            (Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
          ])
            NavigationDestination(
              icon: Icon(entry.$1, size: 23, color: idleColor),
              selectedIcon: Icon(entry.$2, size: 23, color: selectedColor),
              label: entry.$3,
            ),
        ],
      ),
    );
  }
}

/// Floating cart pill matching the quick-commerce pill design (image thumbnail, two-line text, chevron).
class CartFloatingBar extends ConsumerWidget {
  const CartFloatingBar({super.key, required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider).value ?? const [];

    String? imageUrl;
    if (cartItems.isNotEmpty) {
      for (final item in cartItems.reversed) {
        final candidate =
            item.comboImage ??
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
                          AppTextSwitcher(
                            text: subtitle,
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
      ),
    );
  }
}
