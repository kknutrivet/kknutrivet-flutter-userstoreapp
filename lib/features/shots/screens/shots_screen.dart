import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_card.dart' show formatInr;
import '../../../models/content.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';
import '../../home/widgets/home_models_and_data.dart';

/// Full-screen vertical Reels-style Product Shots screen matching
/// `src/app/shots/ShotsClient.tsx` in the web mobile application.
class ShotsScreen extends ConsumerStatefulWidget {
  const ShotsScreen({
    super.key,
    this.initialProductId,
    this.initialShotId,
    this.initialAnimal,
  });

  final String? initialProductId;
  final String? initialShotId;
  final String? initialAnimal;

  @override
  ConsumerState<ShotsScreen> createState() => _ShotsScreenState();
}

class _AnimalFilterItem {
  const _AnimalFilterItem(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;
}

class _ShotsScreenState extends ConsumerState<ShotsScreen>
    with WidgetsBindingObserver {
  late String _selectedAnimal;
  bool _muted = false;
  final Set<String> _likedIds = <String>{};
  final Set<String> _addedIds = <String>{};
  String? _addingId;
  late final PageController _pageController;
  int _activeIndex = 0;
  GoRouterDelegate? _routerDelegate;
  bool _isShotsRouteActive = true;
  bool _isAppResumed = true;

  static const _animalFilters = [
    _AnimalFilterItem('all', 'All', '✨'),
    _AnimalFilterItem('Dog', 'Dogs', '🐶'),
    _AnimalFilterItem('Cat', 'Cats', '🐱'),
    _AnimalFilterItem('Cattle', 'Cattle', '🐮'),
    _AnimalFilterItem('Poultry', 'Poultry', '🐔'),
    _AnimalFilterItem('Goat/Sheep', 'Goat/Sheep', '🐐'),
    _AnimalFilterItem('Exotic & Small Pets', 'Birds & Pets', '🦜'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    _isAppResumed =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
    _selectedAnimal = widget.initialAnimal ?? 'all';
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.maybeOf(context)?.routerDelegate;
    if (_routerDelegate != delegate) {
      _routerDelegate?.removeListener(_handleRouterChanged);
      _routerDelegate = delegate;
      _routerDelegate?.addListener(_handleRouterChanged);
    }
    _isShotsRouteActive = _computeIsShotsRouteActive();
  }

  bool _computeIsShotsRouteActive() {
    final delegate = _routerDelegate;
    if (delegate == null) return true;
    try {
      final path = delegate.currentConfiguration.uri.path;
      return path == '/shots';
    } catch (_) {
      return true;
    }
  }

  void _handleRouterChanged() {
    if (!mounted) return;
    final nextActive = _computeIsShotsRouteActive();
    if (nextActive != _isShotsRouteActive) {
      setState(() => _isShotsRouteActive = nextActive);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final resumed = state == AppLifecycleState.resumed;
    if (resumed != _isAppResumed) {
      setState(() => _isAppResumed = resumed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routerDelegate?.removeListener(_handleRouterChanged);
    _pageController.dispose();
    super.dispose();
  }

  String _resolveMediaUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final origin = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$origin${raw.startsWith('/') ? '' : '/'}$raw';
  }

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
    return '${views > 0 ? views : 1}';
  }

  bool _matchesAnimalFilter(ShotItem shot, String animalId) {
    if (animalId.isEmpty || animalId == 'all') return true;
    final target = animalId.toLowerCase();
    final types = shot.animalTypes.map((t) => t.toLowerCase()).toList();
    if (types.isNotEmpty) {
      if (target == 'cat') {
        return types.any(
          (t) => t == 'cat' || t.contains('kitten') || t.contains('feline'),
        );
      }
      if (target == 'dog') {
        return types.any(
          (t) => t == 'dog' || t.contains('puppy') || t.contains('canine'),
        );
      }
      if (target == 'cattle') {
        return types.any(
          (t) =>
              t.contains('cattle') ||
              t.contains('cow') ||
              t.contains('buffalo') ||
              t.contains('dairy') ||
              t.contains('bovine') ||
              t.contains('calf'),
        );
      }
      if (target == 'poultry') {
        return types.any(
          (t) =>
              t.contains('poultry') ||
              t.contains('chicken') ||
              t.contains('broiler') ||
              t.contains('layer'),
        );
      }
      if (target.contains('goat') || target.contains('sheep')) {
        return types.any((t) => t.contains('goat') || t.contains('sheep'));
      }
      if (target.contains('exotic')) {
        return types.any(
          (t) =>
              t.contains('exotic') ||
              t.contains('fish') ||
              t.contains('bird') ||
              t.contains('small pet') ||
              t.contains('rabbit'),
        );
      }
      return types.any((t) => t == target);
    }

    final text = '${shot.name} ${shot.description ?? ''}'.toLowerCase();
    if (target == 'cat') {
      if (text.contains('cattle') || text.contains('dairy')) return false;
      return text.contains('cat') || text.contains('kitten');
    }
    if (target == 'dog') {
      if (text.contains('cattle') || text.contains('dairy')) return false;
      return text.contains('dog') ||
          text.contains('puppy') ||
          text.contains('byno');
    }
    if (target == 'cattle') {
      return text.contains('cattle') ||
          text.contains('cow') ||
          text.contains('dairy') ||
          text.contains('livol') ||
          text.contains('fat raise');
    }
    return text.contains(target);
  }

  List<ShotItem> _filterAndOrder(List<ShotItem> raw) {
    var list = raw
        .where((s) => _matchesAnimalFilter(s, _selectedAnimal))
        .toList();

    final targetId = widget.initialShotId ?? widget.initialProductId;
    if (targetId != null && targetId.isNotEmpty) {
      final idx = list.indexWhere(
        (s) =>
            s.id == targetId || s.productId == targetId || s.slug == targetId,
      );
      if (idx > 0) {
        final target = list.removeAt(idx);
        list.insert(0, target);
      }
    }
    return list;
  }

  Future<void> _showAnimalFilterDialog() async {
    AppHaptics.tap();
    final picked = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.80),
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by Animal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Select which videos you want to watch',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 14),
                // Full-width All Animals option
                _buildAnimalOptionTile(
                  ctx,
                  item: const _AnimalFilterItem('all', 'All Animals', '✨'),
                  subtitle: 'Watch all product videos',
                  selected: _selectedAnimal == 'all',
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: [
                    for (final item in _animalFilters.where((a) => a.id != 'all'))
                      _buildAnimalOptionTile(
                        ctx,
                        item: item,
                        selected: _selectedAnimal == item.id,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedAnimal = picked;
        _activeIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  Widget _buildAnimalOptionTile(
    BuildContext ctx, {
    required _AnimalFilterItem item,
    String? subtitle,
    required bool selected,
  }) {
    return Material(
      color: selected
          ? const Color(0x3310B981)
          : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(ctx).pop(item.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF34D399)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(ShotItem shot) async {
    if (_addingId == shot.id) return;
    setState(() => _addingId = shot.id);
    try {
      final productId = shot.productId ?? shot.id;
      final product = Product(
        id: productId,
        name: shot.name,
        slug: shot.slug ?? productId,
        price: shot.price,
        mrp: shot.mrp,
        offerPrice: shot.offerPrice,
        image: shot.image,
        category: shot.category,
        brand: shot.brand,
        animalTypes: shot.animalTypes,
      );
      await ref.read(cartProvider.notifier).addItem(
            productId: productId,
            quantity: 1,
            product: product,
          );
      AppHaptics.cart();
      if (mounted) {
        setState(() => _addedIds.add(shot.id));
        showToast('${shot.name} added to cart!');
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) setState(() => _addedIds.remove(shot.id));
        });
      }
    } catch (e) {
      if (mounted) showToast('Could not add product to cart.', isError: true);
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  Future<void> _handleAskWhatsApp(ShotItem shot) async {
    AppHaptics.tap();
    final param = shot.isMarketing ? 'shot' : 'product';
    final slugOrId = Uri.encodeComponent(shot.slug ?? shot.id);
    final url = 'https://kknutrivet.in/shots?$param=$slugOrId';
    final message =
        'Hello KK Nutrivet, I watched the video for "${shot.name}" and have a query:\n$url';
    final waUri = Uri.parse(
      'https://wa.me/917846932453?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(waUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final shotsAsync = ref.watch(homeShotsProvider);
    final cartCount = ref.watch(cartCountProvider);
    final shellIndex = StatefulNavigationShell.maybeOf(context)?.currentIndex;
    final isTabActive = shellIndex == null || shellIndex == 3;
    final isTickerEnabled = TickerMode.valuesOf(context).enabled;
    final isRouteCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    final isScreenActive = _isAppResumed &&
        _isShotsRouteActive &&
        isTabActive &&
        isTickerEnabled &&
        isRouteCurrent;

    final currentAnimalObj = _animalFilters.firstWhere(
      (a) => a.id == _selectedAnimal,
      orElse: () => _animalFilters.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070A0E),
      body: shotsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF34D399)),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.movie_creation_outlined,
                color: Colors.white54,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load Product Shots',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(homeShotsProvider),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087E58),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (rawShots) {
          final shots = _filterAndOrder(rawShots);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (shots.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentAnimalObj.icon,
                          style: const TextStyle(fontSize: 38),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No ${_selectedAnimal == 'all' ? 'Product' : _selectedAnimal} Videos Yet',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We are curating video demonstrations for $_selectedAnimal. Tap below to browse all pet shots.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {
                            _selectedAnimal = 'all';
                            _activeIndex = 0;
                          }),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                          ),
                          child: const Text('View All Videos'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (idx) {
                    AppHaptics.selection();
                    setState(() => _activeIndex = idx);
                  },
                  itemCount: shots.length,
                  itemBuilder: (context, index) {
                    final shot = shots[index];
                    final isActive = isScreenActive && (index == _activeIndex);
                    return _ShotVideoSlide(
                      key: ValueKey('shot-slide-${shot.id}'),
                      shot: shot,
                      imageUrl: _resolveMediaUrl(shot.image),
                      videoUrl: _resolveMediaUrl(shot.videoUrl),
                      isActive: isActive,
                      muted: _muted,
                      isLiked: _likedIds.contains(shot.id),
                      likeCount:
                          shot.videoLikes + (_likedIds.contains(shot.id) ? 1 : 0),
                      formattedViews: _formatViews(shot.videoViews),
                      isAdding: _addingId == shot.id,
                      isAdded: _addedIds.contains(shot.id),
                      onToggleLike: () {
                        AppHaptics.tap();
                        setState(() {
                          if (_likedIds.contains(shot.id)) {
                            _likedIds.remove(shot.id);
                          } else {
                            _likedIds.add(shot.id);
                          }
                        });
                      },
                      onDoubleTapLike: () {
                        AppHaptics.tap();
                        if (!_likedIds.contains(shot.id)) {
                          setState(() => _likedIds.add(shot.id));
                        }
                      },
                      onAskWhatsApp: () => _handleAskWhatsApp(shot),
                      onShare: () {
                        AppHaptics.tap();
                        AppShare.shareText(
                          context,
                          text:
                              'Watch video for "${shot.name}" on KK Nutrivet: https://kknutrivet.in/shots?${shot.isMarketing ? "shot" : "product"}=${Uri.encodeComponent(shot.slug ?? shot.id)}',
                        );
                      },
                      onAddToCart: () => _handleAddToCart(shot),
                    );
                  },
                ),

              // Top Floating Overlay Bar (matches ShotsClient.tsx lines 790-840)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xD9000000),
                        Color(0x66000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: Back Navigation to Store
                          _topCircleButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Back to store',
                            onTap: () {
                              AppHaptics.tap();
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/products');
                              }
                            },
                          ),

                          // Center: Animal Type Filter Dialog Trigger
                          Material(
                            color: _selectedAnimal != 'all'
                                ? const Color(0xE610B981)
                                : Colors.black.withValues(alpha: 0.50),
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _showAnimalFilterDialog,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _selectedAnimal != 'all'
                                        ? const Color(0x666EE7B7)
                                        : Colors.white24,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currentAnimalObj.icon,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentAnimalObj.label,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Right: Sound & Cart Controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _topCircleButton(
                                icon: _muted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                iconColor: _muted
                                    ? Colors.white
                                    : const Color(0xFF34D399),
                                tooltip: _muted ? 'Unmute audio' : 'Mute audio',
                                onTap: () {
                                  AppHaptics.tap();
                                  setState(() => _muted = !_muted);
                                },
                              ),
                              const SizedBox(width: 8),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _topCircleButton(
                                    icon: Icons.shopping_bag_outlined,
                                    tooltip: 'View shopping cart',
                                    onTap: () {
                                      AppHaptics.tap();
                                      context.push('/cart');
                                    },
                                  ),
                                  if (cartCount > 0)
                                    Positioned(
                                      top: -3,
                                      right: -3,
                                      child: IgnorePointer(
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$cartCount',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _topCircleButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _ShotVideoSlide extends StatefulWidget {
  const _ShotVideoSlide({
    super.key,
    required this.shot,
    required this.imageUrl,
    required this.videoUrl,
    required this.isActive,
    required this.muted,
    required this.isLiked,
    required this.likeCount,
    required this.formattedViews,
    required this.isAdding,
    required this.isAdded,
    required this.onToggleLike,
    required this.onDoubleTapLike,
    required this.onAskWhatsApp,
    required this.onShare,
    required this.onAddToCart,
  });

  final ShotItem shot;
  final String imageUrl;
  final String videoUrl;
  final bool isActive;
  final bool muted;
  final bool isLiked;
  final int likeCount;
  final String formattedViews;
  final bool isAdding;
  final bool isAdded;
  final VoidCallback onToggleLike;
  final VoidCallback onDoubleTapLike;
  final VoidCallback onAskWhatsApp;
  final VoidCallback onShare;
  final VoidCallback onAddToCart;

  @override
  State<_ShotVideoSlide> createState() => _ShotVideoSlideState();
}

class _ShotVideoSlideState extends State<_ShotVideoSlide> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _userPaused = false;
  bool _showHeartBurst = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant _ShotVideoSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initController();
      return;
    }
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _userPaused = false;
        _syncPlaybackState(resetPosition: true);
      } else {
        _syncPlaybackState();
      }
      return;
    }
    if (oldWidget.muted != widget.muted) {
      _syncPlaybackState();
    }
  }

  @override
  void deactivate() {
    final c = _controller;
    if (c != null) {
      c.setVolume(0.0);
      c.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      c.removeListener(_onControllerUpdated);
      c.setVolume(0.0);
      c.pause();
      c.dispose();
    }
  }

  void _onControllerUpdated() {
    final c = _controller;
    if (c == null || !mounted) return;
    if (!widget.isActive && (c.value.isPlaying || c.value.volume > 0)) {
      c.setVolume(0.0);
      c.pause();
    }
  }

  void _syncPlaybackState({bool resetPosition = false}) {
    final c = _controller;
    if (c == null || !_initialized) return;
    if (!widget.isActive) {
      c.setVolume(0.0);
      c.pause();
      return;
    }
    c.setVolume(widget.muted ? 0.0 : 1.0);
    if (resetPosition) {
      c.seekTo(Duration.zero);
    }
    if (!_userPaused) {
      c.play();
    }
  }

  Future<void> _initController() async {
    final rawUrl = widget.videoUrl.trim();
    if (rawUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    // Strip any query/hash fragment editor params when passing to native player if needed,
    // though Uri.parse handles query params cleanly.
    final cleanUrl = rawUrl.split('#').first;
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    controller.addListener(_onControllerUpdated);

    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.setLooping(true);
      if (!mounted || _controller != controller) return;
      setState(() {
        _initialized = true;
        _hasError = false;
      });
      _syncPlaybackState();
    } catch (_) {
      if (!mounted || _controller != controller) return;
      setState(() => _hasError = true);
    }
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !_initialized) return;
    AppHaptics.tap();
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _userPaused = true;
      } else {
        c.play();
        _userPaused = false;
      }
    });
  }

  void _triggerDoubleTapLike() {
    widget.onDoubleTapLike();
    setState(() => _showHeartBurst = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shot = widget.shot;
    final displayPrice = shot.effectivePrice;
    final hasDiscount = shot.mrp != null && shot.mrp! > displayPrice;
    final discountPct = hasDiscount
        ? (((shot.mrp! - displayPrice) / shot.mrp!) * 100).round()
        : 0;
    final controller = _controller;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      onDoubleTap: _triggerDoubleTapLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient blurred poster glow in background
          if (widget.imageUrl.isNotEmpty)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Opacity(
                opacity: 0.30,
                child: Transform.scale(
                  scale: 1.25,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        const ColoredBox(color: Colors.black),
                  ),
                ),
              ),
            )
          else
            const ColoredBox(color: Colors.black),

          // 2. Main fullscreen video or poster fallback while loading
          if (_initialized &&
              controller != null &&
              controller.value.size.width > 0 &&
              controller.value.size.height > 0)
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else if (widget.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF162721)),
            ),

          // Subtle vignette for legibility
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000),
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top Video Progress Scrub Line (Reels / Stories style)
          if (_initialized && controller != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 3,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: false,
                    padding: EdgeInsets.zero,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF34D399),
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),

          // Loading spinner while video initializes
          if (!_initialized && !_hasError)
            const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF34D399),
                ),
              ),
            ),

          // Error retry card if video failed
          if (_hasError)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "This video couldn't load",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Check your connection or try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _initialized = false;
                        });
                        _disposeController();
                        _initController();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text(
                        'Retry video',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Center Play Indicator when Paused
          if (_userPaused && _initialized)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),

          // Double-tap Floating Heart Burst
          if (_showHeartBurst)
            const IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.favorite_rounded,
                  size: 88,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),

          // 4. Mobile Right Floating Action Rail (Views, Like, Ask on WhatsApp, Share)
          Positioned(
            right: 12,
            bottom: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionPill(
                  icon: Icons.visibility_outlined,
                  iconColor: const Color(0xFF6EE7B7),
                  bgColor: Colors.black.withValues(alpha: 0.40),
                  label: widget.formattedViews,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _actionPill(
                  icon: widget.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: Colors.white,
                  bgColor: widget.isLiked
                      ? const Color(0xFFDC2626)
                      : Colors.black.withValues(alpha: 0.40),
                  borderColor: widget.isLiked
                      ? const Color(0xFFEF4444)
                      : Colors.white24,
                  label: '${widget.likeCount}',
                  onTap: widget.onToggleLike,
                ),
                const SizedBox(height: 10),
                _actionPill(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF25D366),
                  bgColor: Colors.black.withValues(alpha: 0.40),
                  label: 'Ask',
                  onTap: widget.onAskWhatsApp,
                ),
                const SizedBox(height: 10),
                _actionPill(
                  icon: Icons.share_outlined,
                  iconColor: Colors.white,
                  bgColor: Colors.black.withValues(alpha: 0.40),
                  label: 'Share',
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),

          // 5. Bottom Shoppable Capsule Pill (matches ShotsClient.tsx lines 1012-1090)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptics.tap();
                        final target = shot.slug?.isNotEmpty == true
                            ? shot.slug!
                            : (shot.productId ?? shot.id);
                        if (!shot.isMarketing && target.isNotEmpty) {
                          context.push('/product/$target');
                        } else if (shot.ctaLink != null &&
                            shot.ctaLink!.startsWith('/')) {
                          context.push(shot.ctaLink!);
                        } else {
                          context.push('/products');
                        }
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: Colors.white10,
                              child: widget.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.imageUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Container(
                                        color: AppColors.primaryWash,
                                        child: const Icon(Icons.pets, size: 20),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.primaryWash,
                                      child: const Icon(Icons.pets, size: 20),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shot.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (shot.isMarketing && displayPrice <= 0)
                                  const Text(
                                    'Featured Campaign',
                                    style: TextStyle(
                                      color: Color(0xFF6EE7B7),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Text(
                                        '₹${formatInr(displayPrice)}',
                                        style: const TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '₹${formatInr(shot.mrp!)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0x33FBBF24),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '$discountPct% OFF',
                                            style: const TextStyle(
                                              color: Color(0xFFFCD34D),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (shot.isMarketing && shot.productId == null)
                    FilledButton(
                      onPressed: () {
                        AppHaptics.tap();
                        if (shot.ctaLink != null &&
                            shot.ctaLink!.startsWith('/')) {
                          context.push(shot.ctaLink!);
                        } else {
                          context.push('/products');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF087E58),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(76, 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            shot.ctaLabel.isNotEmpty
                                ? shot.ctaLabel
                                : 'Explore',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 13),
                        ],
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: widget.isAdding ? null : widget.onAddToCart,
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.isAdded
                            ? const Color(0xFF10B981)
                            : const Color(0xFF07583F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(76, 38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: widget.isAdding
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isAdded
                                      ? Icons.check_rounded
                                      : Icons.shopping_bag_outlined,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.isAdded ? 'Added' : 'Add',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    Color borderColor = Colors.white24,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
