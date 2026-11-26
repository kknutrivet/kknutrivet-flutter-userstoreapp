import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/language_switcher.dart';
import '../../../models/address.dart';
import '../../../providers/app_providers.dart';
import 'home_models_and_data.dart';

/// Tracks whether we have already auto-detected GPS location during this app launch
/// so we don't repeatedly re-trigger GPS every time the Home screen rebuilds,
/// while ensuring a fresh app launch in a new city (e.g. Hyderabad) updates the PIN.
final _sessionGpsCheckedProvider = StateProvider<bool>((ref) => false);

// ── 1. Mobile brand bar (Matches webview mobile HomeTopBar.tsx Row 1) ────────
class HomeBrandBar extends ConsumerWidget {
  const HomeBrandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final animalTheme = homeAnimalThemeFor(selectedAnimal);
    final cartCount = ref.watch(cartCountProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final customerName =
        user != null && !user.isAnonymous && (user.name?.trim().isNotEmpty ?? false)
            ? user.name!.trim()
            : null;
    final firstName = customerName != null
        ? customerName.split(RegExp(r'\s+')).first
        : strings.there;
    final greetingWord = strings.greetingForHour(DateTime.now().hour);

    final pin = ref.watch(deliveryPincodeProvider).value;
    final addresses = user != null
        ? (ref.watch(addressesProvider).valueOrNull ?? const <Address>[])
        : const <Address>[];
    final selectedAddressId = ref.watch(selectedDeliveryAddressIdProvider);

    Address? activeAddress;
    if (addresses.isNotEmpty) {
      if (selectedAddressId != null) {
        activeAddress =
            addresses.where((a) => a.id == selectedAddressId).firstOrNull;
      } else if (pin != null && pin.isNotEmpty) {
        final trimmedPin = pin.trim();
        activeAddress = addresses
                .where((a) => a.isDefault && a.zipCode.trim() == trimmedPin)
                .firstOrNull ??
            addresses.where((a) => a.zipCode.trim() == trimmedPin).firstOrNull;
      }
    }

    final effectivePin = activeAddress?.zipCode.trim().isNotEmpty == true
        ? activeAddress!.zipCode.trim()
        : pin?.trim();
    final rawCity = activeAddress?.city.trim().isNotEmpty == true
        ? activeAddress!.city.trim()
        : null;
    final cityLabel = rawCity != null && rawCity.isNotEmpty
        ? _HomeTopBarCardState._formatCityName(rawCity)
        : (effectivePin != null && effectivePin.isNotEmpty
            ? 'Pincode $effectivePin'
            : null);
    final locationText = cityLabel != null
        ? (effectivePin != null &&
                effectivePin.isNotEmpty &&
                !cityLabel.contains(effectivePin)
            ? '$cityLabel, $effectivePin'
            : cityLabel)
        : strings.setDeliveryLocation;

    return SliverAppBar(
      pinned: false,
      floating: false,
      primary: false,
      backgroundColor: animalTheme.headerBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 54,
      titleSpacing: 14,
      flexibleSpace: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        color: animalTheme.headerBg,
      ),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      color: Color(0xFF374151),
                    ),
                    children: [
                      TextSpan(text: '$greetingWord '),
                      TextSpan(
                        text: firstName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                      const TextSpan(text: ','),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Haptics.tap();
                    showModalBottomSheet<void>(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => const HomePincodeBottomSheet(),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12.5,
                        color: Color(0xFF07583F),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 6),
            child: LanguageSwitcher(compact: true),
          ),
        ),
        // Dr. Paw AI Companion Action
        Semantics(
          button: true,
          label: 'Ask Dr. Paw AI veterinary assistant',
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Haptics.tap();
                      AnalyticsService.instance.logDrPawChatStarted();
                      context.push('/vet');
                    },
                    child: Center(
                      child: Image.asset(
                        'assets/marketing_image/dr-paw-genz-avatar.webp',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.support_agent_rounded,
                          size: 19,
                          color: Color(0xFF07583F),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07583F),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pets_rounded,
                          size: 7,
                          color: Color(0xFFC9FF67),
                        ),
                        SizedBox(width: 1),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC9FF67),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cart Action with Badge
        Semantics(
          button: true,
          label: 'Shopping Cart${cartCount > 0 ? " ($cartCount items)" : ""}',
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 14),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE4E2DC),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Haptics.tap();
                        context.push('/cart');
                      },
                      child: const Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 18,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                    ),
                  ),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF07583F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
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

// ── 2. HomeTopBar: Integrated Delivery Capsule & Promise Strip ─────────────
class HomeTopBarCard extends ConsumerStatefulWidget {
  const HomeTopBarCard({super.key});
  @override
  ConsumerState<HomeTopBarCard> createState() => _HomeTopBarCardState();
}

class _HomeTopBarCardState extends ConsumerState<HomeTopBarCard> {
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final alreadyChecked = ref.read(_sessionGpsCheckedProvider);
      final selectedAddressId = ref.read(selectedDeliveryAddressIdProvider);
      if (alreadyChecked || selectedAddressId != null) return;
      ref.read(_sessionGpsCheckedProvider.notifier).state = true;
      final savedPin = await ref.read(deliveryPincodeProvider.future);
      if (!mounted) return;
      await _useCurrentLocation(silent: savedPin != null && savedPin.isNotEmpty);
    });
  }

  void _showPincodeModalSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const HomePincodeBottomSheet(),
    );
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() {
      _locating = true;
      if (!silent) _error = null;
    });
    try {
      final location = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;
      final pin = location.zipCode?.trim() ?? '';
      if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
        if (!silent) {
          throw Exception('Could not detect your PIN. Please enter it manually.');
        }
        return;
      }
      ref.read(selectedDeliveryAddressIdProvider.notifier).state = null;
      await ref.read(deliveryPincodeProvider.notifier).setPincode(pin);
      ref.invalidate(deliveryEtaProvider);
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Title-cases an uppercase city name (`"BERHAMPUR"` -> `"Berhampur"`, `"HYDERABAD"` -> `"Hyderabad"`).
  static String _formatCityName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final pin = ref.watch(deliveryPincodeProvider).value;
    final delivery = ref.watch(deliveryEtaProvider).value;
    final settings = ref.watch(storeSettingsProvider).valueOrNull;
    final addresses = ref.watch(addressesProvider).valueOrNull ?? const <Address>[];
    final selectedAddressId = ref.watch(selectedDeliveryAddressIdProvider);

    Address? activeAddress;
    if (addresses.isNotEmpty) {
      if (selectedAddressId != null) {
        activeAddress =
            addresses.where((a) => a.id == selectedAddressId).firstOrNull;
      } else if (pin != null && pin.isNotEmpty) {
        final trimmedPin = pin.trim();
        activeAddress = addresses
                .where(
                  (a) => a.isDefault && a.zipCode.trim() == trimmedPin,
                )
                .firstOrNull ??
            addresses
                .where((a) => a.zipCode.trim() == trimmedPin)
                .firstOrNull;
      }
    }

    final effectivePin = activeAddress?.zipCode.trim().isNotEmpty == true
        ? activeAddress!.zipCode.trim()
        : pin;
    final threshold = settings != null && effectivePin != null
        ? settings.effectiveFreeDeliveryThreshold(pincode: effectivePin)
        : settings?.freeDeliveryThreshold;
    final hasPin = effectivePin != null && effectivePin.isNotEmpty;
    final confirmed = hasPin && delivery?.serviceable == true;
    final unavailable = hasPin && delivery?.serviceable == false;
    final eta = confirmed ? delivery?.etaLabel.trim() ?? '' : '';
    final rawCity = activeAddress?.city.trim().isNotEmpty == true
        ? activeAddress!.city.trim()
        : delivery?.city?.trim();
    final city = rawCity != null && rawCity.isNotEmpty
        ? _formatCityName(rawCity)
        : null;
    final addressTag = activeAddress?.label?.trim().isNotEmpty == true
        ? activeAddress!.label!.trim()
        : null;

    final String label;
    if (hasPin) {
      if (addressTag != null && city != null) {
        label = '$addressTag: $city · $effectivePin';
      } else if (city != null) {
        label = '$city · $effectivePin';
      } else {
        label = effectivePin;
      }
    } else if (_locating) {
      label = 'Detecting location…';
    } else {
      label = 'Set delivery location';
    }

    return ColoredBox(
      color: const Color(0xFF07583F),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _showPincodeModalSheet,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 34),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrowConstraint =
                                  constraints.maxWidth < 160;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Color(0xFFC9FF67),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    confirmed
                                        ? Icons.check_circle
                                        : unavailable
                                            ? Icons.error_outline
                                            : Icons.keyboard_arrow_down_rounded,
                                    size: 13,
                                    color: unavailable
                                        ? const Color(0xFFFECDD3)
                                        : const Color(0xFFC9FF67),
                                  ),
                                  if (eta.isNotEmpty) ...[
                                    const SizedBox(width: 3),
                                    if (isNarrowConstraint)
                                      Flexible(
                                        child: Text(
                                          '· $eta',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFD8F7A8),
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        '· $eta',
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFD8F7A8),
                                        ),
                                      ),
                                  ],
                                  if (!isNarrowConstraint &&
                                      (addresses.length > 1 || confirmed)) ...[
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (!unavailable && threshold != null && threshold > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Free delivery ₹${threshold.toInt()}+',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (unavailable)
                  const Text(
                    'Not serviceable',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFECDD3),
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 2b. Pinned search bar — stays visible under the app bar while scrolling ──
class HomePinnedSearchBar extends ConsumerWidget {
  const HomePinnedSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAnimal = ref.watch(selectedHomeAnimalProvider);
    final animalTheme = homeAnimalThemeFor(selectedAnimal);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedSearchDelegate(
        headerBg: animalTheme.headerBg,
        storeTitle: animalTheme.storeTitle,
      ),
    );
  }
}

/// Emerald trust ribbon directly below the species tab strip — exact parity
/// with `src/components/home/FreeDeliveryTrustLine.tsx` across all 5 languages.
class HomeFreeDeliveryTrustRibbon extends ConsumerWidget {
  const HomeFreeDeliveryTrustRibbon({super.key});

  static String _copyFor(AppLocale locale, String amount) {
    switch (locale) {
      case AppLocale.hi:
        return '₹$amount+ के ऑनलाइन और Partial COD ऑर्डर पर FREE डिलीवरी';
      case AppLocale.or_:
        return '₹$amount+ ଅନଲାଇନ୍ ଓ Partial COD ଅର୍ଡରରେ ମାଗଣା ଡେଲିଭରି';
      case AppLocale.te:
        return '₹$amount+ ఆన్‌లైన్ & Partial COD ఆర్డర్లపై ఉచిత డెలివరీ';
      case AppLocale.ta:
        return '₹$amount+ ஆன்லைன் & Partial COD ஆர்டர்களுக்கு இலவச டெலிவரி';
      case AppLocale.en:
        return 'FREE Delivery on Online & Partial COD orders ₹$amount+';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(storeSettingsProvider).valueOrNull;
    final locale = ref.watch(languageProvider);
    final standard = settings?.freeDeliveryThreshold ?? 499;
    final prepaid = settings?.prepaidFreeDeliveryThreshold ?? 299;
    final threshold = prepaid > 0
        ? (standard > 0 && standard < prepaid ? standard : prepaid)
        : standard;
    if (threshold <= 0) return const SizedBox.shrink();

    final amountLabel = threshold.toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEAF7F0), Color(0xFFF3FAF6), Color(0xFFEAF7F0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFCFE6DA), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFF07583F).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 12.5,
              color: Color(0xFF07583F),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _copyFor(locale, amountLabel),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: Color(0xFF07583F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedSearchDelegate extends SliverPersistentHeaderDelegate {
  _PinnedSearchDelegate({
    required this.headerBg,
    required this.storeTitle,
  });

  final Color headerBg;
  final String storeTitle;
  static const double _height = 60;

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      height: _height,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      color: headerBg,
      child: HomeSearchField(storeTitle: storeTitle),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSearchDelegate oldDelegate) =>
      oldDelegate.headerBg != headerBg || oldDelegate.storeTitle != storeTitle;
}

/// Tappable search pill that opens the full search screen (matches cream Blinkit-style HomeTopBar.tsx).
class HomeSearchField extends ConsumerWidget {
  const HomeSearchField({super.key, this.storeTitle = ''});
  final String storeTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final placeholder = strings.locale == AppLocale.en
        ? (storeTitle.isNotEmpty ? 'Search in $storeTitle…' : 'Search products')
        : strings.searchHint;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Haptics.tap();
          context.push('/search');
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(13, 0, 8, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCD6C9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1217322B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 19,
                color: Color(0xFF07583F),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mic_none_rounded,
                  size: 17,
                  color: Color(0xFF07583F),
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
  late final ScrollController _addressScrollController;
  bool _checking = false;
  bool _detectingLocation = false;
  bool _editingPincode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(deliveryPincodeProvider).value ?? '';
    _controller = TextEditingController(text: existing);
    _addressScrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _addressScrollController.dispose();
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

  Future<void> _selectSavedAddress(Address addr) async {
    AppHaptics.selection();
    ref.read(selectedDeliveryAddressIdProvider.notifier).state = addr.id;
    final zip = addr.zipCode.trim();
    if (RegExp(r'^\d{6}$').hasMatch(zip)) {
      _controller.text = zip;
      await ref.read(deliveryPincodeProvider.notifier).setPincode(zip);
      ref.invalidate(deliveryEtaProvider);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitPincode({bool clearSelectedAddress = true}) async {
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
      if (clearSelectedAddress) {
        ref.read(selectedDeliveryAddressIdProvider.notifier).state = null;
      }
      await ref.read(deliveryPincodeProvider.notifier).setPincode(pin);
      ref.invalidate(deliveryEtaProvider);
      await ref.read(deliveryEtaProvider.future);
      if (mounted) {
        setState(() => _editingPincode = false);
      }
    } catch (_) {
      // DeliveryPincodeNotifier still persists the pincode locally.
      if (mounted) {
        setState(() => _editingPincode = false);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openAddNewAddress() async {
    Navigator.of(context).pop();
    final newAddr = await context.push<Address?>('/addresses/new');
    ref.invalidate(addressesProvider);
    if (newAddr != null) {
      ref.read(selectedDeliveryAddressIdProvider.notifier).state = newAddr.id;
      if (RegExp(r'^\d{6}$').hasMatch(newAddr.zipCode.trim())) {
        await ref
            .read(deliveryPincodeProvider.notifier)
            .setPincode(newAddr.zipCode.trim());
        ref.invalidate(deliveryEtaProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final currentPincode = ref.watch(deliveryPincodeProvider).value?.trim();
    final hasValidPincode =
        currentPincode != null && RegExp(r'^\d{6}$').hasMatch(currentPincode);
    final showPincodeEditor = !hasValidPincode || _editingPincode;
    final etaAsync = ref.watch(deliveryEtaProvider);
    final addresses =
        ref.watch(addressesProvider).valueOrNull ?? const <Address>[];
    final selectedAddressId = ref.watch(selectedDeliveryAddressIdProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final isLoggedIn = user != null;
    final String? effectiveSelectedAddressId = selectedAddressId ??
        (hasValidPincode
            ? (addresses
                        .where(
                          (a) =>
                              a.isDefault &&
                              a.zipCode.trim() == currentPincode,
                        )
                        .firstOrNull ??
                    addresses
                        .where(
                          (a) => a.zipCode.trim() == currentPincode,
                        )
                        .firstOrNull)
                ?.id
            : null);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle + web-style header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2DED8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF5EF),
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
                              addresses.isNotEmpty
                                  ? 'Select delivery location'
                                  : 'Check delivery & speed',
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.2,
                                color: Color(0xFF102A23),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              addresses.isNotEmpty
                                  ? 'Choose a saved address or enter a 6-digit pincode'
                                  : 'Enter your 6-digit pincode for dispatch ETA & COD availability',
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: Color(0xFF5B7268),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: const Color(0xFFF3F8F5),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Color(0xFF4A6359),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFEDF3EF),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  20 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (addresses.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SAVED ADDRESSES (${addresses.length})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                          if (isLoggedIn)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryDeep,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _openAddNewAddress,
                              icon: const Icon(Icons.add_rounded, size: 15),
                              label: const Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 245),
                        child: Scrollbar(
                          controller: _addressScrollController,
                          thumbVisibility: addresses.length > 2,
                          radius: const Radius.circular(4),
                          thickness: 4,
                          child: ListView.separated(
                            controller: _addressScrollController,
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(right: 6),
                            itemCount: addresses.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 9),
                            itemBuilder: (context, index) {
                              final addr = addresses[index];
                              final isSelected =
                                  effectiveSelectedAddressId != null &&
                                      effectiveSelectedAddressId == addr.id;
                              final titleLabel = (addr.label != null &&
                                      addr.label!.trim().isNotEmpty)
                                  ? '${addr.label!.trim()} · ${addr.fullName}'
                                  : addr.fullName;
                              return Material(
                                color: isSelected
                                    ? const Color(0xFFF1F8F4)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _selectSavedAddress(addr),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primaryDeep
                                            : const Color(0xFFDCE6E0),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 1.5),
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primaryDeep
                                                    : const Color(0xFFB7C7BF),
                                                width: 1.5,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: isSelected
                                                ? Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color:
                                                          AppColors.primaryDeep,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      titleLabel,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13.5,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w800
                                                            : FontWeight.w700,
                                                        color: const Color(
                                                          0xFF102A23,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (addr.zipCode
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      addr.zipCode.trim(),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF5B7268,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${addr.formattedAddress}, ${addr.city}${addr.state.trim().isNotEmpty ? ", ${addr.state.trim()}" : ""}, ${addr.zipCode}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  height: 1.35,
                                                  color: Color(0xFF5B7268),
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
                      ),
                      if (isLoggedIn) ...[
                        const SizedBox(height: 12),
                        CustomPaint(
                          painter: _DashedRRectPainter(
                            color: AppColors.primaryDeep.withValues(alpha: 0.5),
                            radius: 14,
                          ),
                          child: Material(
                            color: const Color(0xFFF4FAF6),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _openAddNewAddress,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    '+ Add new address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                    // Compact web-style pincode status bar OR expandable 6-digit editor
                    if (!showPincodeEditor) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDCE6E0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D102A23),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.primaryDeep,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Delivering to $currentPincode',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF102A23),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: AppColors.primaryDeep,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                _controller.text = currentPincode;
                                setState(() {
                                  _editingPincode = true;
                                  _error = null;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDeep,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primaryDeep,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      if (addresses.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CHECK BY PINCODE / GPS',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Color(0xFF5B7268),
                              ),
                            ),
                            if (hasValidPincode)
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () => setState(() {
                                  _editingPincode = false;
                                  _error = null;
                                }),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5B7268),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              autofocus: addresses.isEmpty || _editingPincode,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onSubmitted: (_) => _submitPincode(),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'Enter 6-digit pincode',
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
                                fillColor: const Color(0xFFF6FAF8),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDCE6E0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDCE6E0),
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
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
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.my_location_rounded,
                              size: 14,
                              color: AppColors.primaryDeep,
                            ),
                            label: Text(
                              _detectingLocation
                                  ? 'Detecting GPS…'
                                  : 'Use Current GPS Location',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                            backgroundColor: AppColors.primaryWash,
                            side: const BorderSide(
                              color: AppColors.primaryWashDeep,
                            ),
                            onPressed: _detectingLocation
                                ? null
                                : _detectCurrentLocation,
                          ),
                          for (final preset in const [
                            ('Hyderabad · 500081', '500081'),
                            ('Brahmapur · 760004', '760004'),
                            ('Bhubaneswar · 751001', '751001'),
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
                              side: const BorderSide(
                                color: AppColors.primaryWashDeep,
                              ),
                              onPressed: () {
                                _controller.text = preset.$2;
                                _submitPincode();
                              },
                            ),
                        ],
                      ),
                      if (hasValidPincode) ...[
                        const SizedBox(height: 12),
                        etaAsync.when(
                          data: (info) {
                            final isBrahmapur =
                                currentPincode.startsWith('7600');
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isBrahmapur
                                              ? '⚡ 24h Local Dispatch to $currentPincode'
                                              : serviceable
                                                  ? 'Delivering to ${info?.city ?? currentPincode} (${info?.etaLabel.isNotEmpty == true ? info!.etaLabel : "5-7 days"})'
                                                  : 'Currently unserviceable for $currentPincode',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (info != null &&
                                            info.message.isNotEmpty) ...[
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dashLength = 5.0;
    const gapLength = 3.5;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
