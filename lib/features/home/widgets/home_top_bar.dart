import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

// ── 1. Mobile brand bar (Navbar.tsx mobile-app-header, h-14) ──────────────
class HomeBrandBar extends ConsumerWidget {
  const HomeBrandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      // Elevation shadow is drawn by the pinned search header directly below,
      // so the brand bar + search read as a single elevated app bar.
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 56,
      titleSpacing: 16,
      title: Image.asset(
        'assets/images/logo.png',
        height: 34,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (_, _, _) => const Text(
          'KK NUTRIVET',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            color: AppColors.primaryDeep,
          ),
        ),
      ),
      actions: [
        // Cart Action with Badge (40×40 circular button matching Navbar.tsx)
        Semantics(
          button: true,
          label: 'Shopping Cart${cartCount > 0 ? " ($cartCount items)" : ""}',
          child: Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8ECE9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C173C32),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Haptics.tap();
                        context.push('/cart');
                      },
                      child: const Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: IgnorePointer(
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF087E58),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 2. HomeTopBar: delivery line + search ──────────────────────────────────
class HomeTopBarCard extends ConsumerWidget {
  const HomeTopBarCard({super.key});

  void _showPincodeModalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomePincodeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pincode = ref.watch(deliveryPincodeProvider).value;
    final etaAsync = ref.watch(deliveryEtaProvider);
    final info = etaAsync.value;
    final settings = ref.watch(storeSettingsProvider).valueOrNull;
    final freeThreshold = (settings != null && pincode != null)
        ? settings.effectiveFreeDeliveryThreshold(pincode: pincode)
        : (settings?.freeDeliveryThreshold ?? 500.0);
    final cityLabel = (info?.city != null && info!.city!.trim().isNotEmpty)
        ? '${info.city} ($pincode)'
        : (pincode == null || pincode.isEmpty ? null : 'Pincode $pincode');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Haptics.tap();
                _showPincodeModalSheet(context);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 15,
                        color: AppColors.primaryDeep,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: cityLabel == null
                            ? const Row(
                                children: [
                                  Flexible(child: Text(
                                    'Set delivery location',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  )),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.primaryDeep,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'Delivering to ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          TextSpan(
                                            text: cityLabel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.primaryDeep,
                                  ),
                                ],
                              ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
          // Delivery Speed & Promise Pill
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (info != null && !info.serviceable)
                        ? const Color(0xFFFFF1F0)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (info != null && !info.serviceable)
                          ? const Color(0xFFFFA39E)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (info != null && !info.serviceable)
                            ? Icons.warning_amber_rounded
                            : Icons.bolt_rounded,
                        size: 13,
                        color: (info != null && !info.serviceable)
                            ? const Color(0xFFCF1322)
                            : const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (info != null && !info.serviceable)
                            ? 'Unserviceable Pincode'
                            : (info != null && info.etaLabel.isNotEmpty)
                                ? '${info.etaLabel} Delivery'
                                : 'Fast All-India Delivery',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: (info != null && !info.serviceable)
                              ? const Color(0xFFCF1322)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (info != null && !info.serviceable)
                        ? 'Try entering another delivery pincode'
                        : freeThreshold > 0
                            ? 'Free delivery on orders over ₹${freeThreshold.toInt()}'
                            : 'Genuine veterinary products guaranteed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2b. Pinned search bar — stays visible under the app bar while scrolling ──
class HomePinnedSearchBar extends StatelessWidget {
  const HomePinnedSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedSearchDelegate(),
    );
  }
}

class _PinnedSearchDelegate extends SliverPersistentHeaderDelegate {
  static const double _height = 62;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Elevate once content scrolls underneath the pinned header.
    final elevated = overlapsContent || shrinkOffset > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: _height,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(18)),
        border: elevated
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: elevated
                ? const Color(0x1F0B3D2C)
                : const Color(0x0A000000),
            blurRadius: elevated ? 14 : 16,
            offset: Offset(0, elevated ? 5 : 4),
          ),
        ],
      ),
      child: const HomeSearchField(),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSearchDelegate oldDelegate) => false;
}

/// Tappable search pill that opens the full search screen.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F7F5),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Haptics.tap();
          context.push('/search');
        },
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2EBE6)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.primaryWash,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Search products',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryDeep,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x2407583F),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Native Material 3 Pincode Checker Modal Bottom Sheet ───────────────────
class HomePincodeBottomSheet extends ConsumerStatefulWidget {
  const HomePincodeBottomSheet({super.key});

  @override
  ConsumerState<HomePincodeBottomSheet> createState() =>
      _HomePincodeBottomSheetState();
}

class _HomePincodeBottomSheetState extends ConsumerState<HomePincodeBottomSheet> {
  late final TextEditingController _controller;
  bool _checking = false;
  bool _detectingLocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(deliveryPincodeProvider).value ?? '';
    _controller = TextEditingController(text: existing);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _detectCurrentLocation() async {
    if (_detectingLocation || _checking) return;
    AppHaptics.selection();
    setState(() {
      _detectingLocation = true;
      _error = null;
    });

    try {
      final location = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;

      final zip = location.zipCode?.trim();
      if (zip != null && RegExp(r'^\d{6}$').hasMatch(zip)) {
        _controller.text = zip;
        showToast('Detected location: $zip');
        await _submitPincode();
      } else {
        setState(() => _error = 'Could not find 6-digit pincode for GPS location');
        showToast('Could not find 6-digit pincode for current GPS location', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      showToast(msg, isError: true);
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<void> _submitPincode() async {
    final pin = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _error = 'Please enter a valid 6-digit pincode');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      Haptics.success();
      await ref.read(deliveryPincodeProvider.notifier).setPincode(pin);
      ref.invalidate(deliveryEtaProvider);
      await ref.read(deliveryEtaProvider.future);
    } catch (_) {
      // DeliveryPincodeNotifier still persists the pincode locally.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final currentPincode = ref.watch(deliveryPincodeProvider).value;
    final etaAsync = ref.watch(deliveryEtaProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryWash,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check delivery & speed',
                        style: AppTheme.serif(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Enter your 6-digit pincode for dispatch ETA & COD availability',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close delivery check',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _submitPincode(),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'e.g. 760004',
                      errorText: _error,
                      prefixIcon: const Icon(
                        Icons.pin_drop_outlined,
                        size: 18,
                        color: AppColors.primaryDeep,
                      ),
                      suffixIcon: _detectingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: 'Use current location',
                              icon: const Icon(
                                Icons.my_location_rounded,
                                size: 19,
                                color: AppColors.primaryDeep,
                              ),
                              onPressed: _detectCurrentLocation,
                            ),
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderStrong),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderStrong),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryDeep,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _checking ? null : _submitPincode,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Check',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in const [
                  ('Brahmapur · 760004', '760004'),
                  ('Bhubaneswar · 751001', '751001'),
                  ('Cuttack · 753001', '753001'),
                ])
                  ActionChip(
                    label: Text(
                      preset.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppColors.primaryWashFaint,
                    side: const BorderSide(color: AppColors.primaryWashDeep),
                    onPressed: () {
                      _controller.text = preset.$2;
                      _submitPincode();
                    },
                  ),
              ],
            ),
            if (currentPincode != null && currentPincode.length == 6) ...[
              const SizedBox(height: 14),
              etaAsync.when(
                data: (info) {
                  final isBrahmapur = currentPincode.startsWith('7600');
                  final serviceable = info?.serviceable ?? true;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: serviceable
                          ? AppColors.primaryWashFaint
                          : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: serviceable
                            ? AppColors.primaryWashDeep
                            : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          serviceable
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 20,
                          color: serviceable
                              ? AppColors.primaryDeep
                              : AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBrahmapur
                                    ? '⚡ 24h Local Dispatch to $currentPincode'
                                    : serviceable
                                        ? 'Delivering to ${info?.city ?? currentPincode} (${info?.etaLabel.isNotEmpty == true ? info!.etaLabel : "Fast courier delivery"})'
                                        : 'Currently unserviceable for $currentPincode',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (info != null && info.message.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  info.message,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(
                    color: AppColors.primaryDeep,
                    backgroundColor: AppColors.primaryWash,
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
