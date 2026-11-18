import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/search_history_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

const _popularSearches = [
  'Dog food',
  'Cat litter',
  'Deworming tablets',
  'Tick spray',
  'Calcium supplement',
  'Grooming shampoo',
  'Cattle feed',
  'Poultry vaccine',
];

/// Search with live suggestions — replica of the website's mobile search
/// (`useSearchSuggestions` + `SearchSuggestionsList` + `HomeTopBar`):
/// 300ms debounced `/api/search/suggestions` typeahead (min 2 chars),
/// loading row, suggestion rows linking to product pages, no-match block,
/// and a "View all results" footer. Recent + popular searches show while
/// the query is short.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<SearchSuggestion> _suggestions = [];
  bool _loading = false;
  String? _searchError;
  bool _showSuggestions = false;
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await SearchHistoryStorage.instance.readAll();
    if (mounted) setState(() => _recent = recent);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _searchError = null;
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _loading = false;
        _showSuggestions = false;
      });
      return;
    }
    setState(() {
      _suggestions = [];
      _loading = true;
      _showSuggestions = true;
    });
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await ref
            .read(catalogServiceProvider)
            .fetchSuggestions(query);
        if (!mounted || _controller.text.trim() != query) return;
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      } catch (_) {
        if (!mounted || _controller.text.trim() != query) return;
        setState(() {
          _searchError =
              'Could not load suggestions. Check your connection and retry.';
          _loading = false;
        });
      }
    });
  }

  Future<void> _submit(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    setState(() => _showSuggestions = false);
    await SearchHistoryStorage.instance.add(q);
    if (!mounted) return;
    context.go('/products?search=${Uri.encodeComponent(q)}');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.borderStrong),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 15,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: _onChanged,
                    onSubmitted: _submit,
                    decoration: const InputDecoration(
                      hintText: 'Search products or brands',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => _submit(_controller.text),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _showSuggestions
            ? _suggestionsPanel()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Browse by animal',
                    style: AppTheme.serif(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final entry in const [
                          ('Dog', 'dog', Icons.pets_rounded),
                          ('Cat', 'cat', Icons.pets_outlined),
                          ('Cattle', 'cattle', Icons.grass_rounded),
                          ('Poultry', 'poultry', Icons.egg_outlined),
                          ('Goat', 'goat', Icons.spa_outlined),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: Icon(
                                entry.$3,
                                size: 15,
                                color: AppColors.primaryDeep,
                              ),
                              label: Text(
                                entry.$1,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                              backgroundColor: AppColors.primaryWashFaint,
                              shape: const StadiumBorder(
                                side: BorderSide(
                                  color: AppColors.primaryWashDeep,
                                ),
                              ),
                              onPressed: () => context.push(
                                '/products?animalType=${Uri.encodeComponent(entry.$2)}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_recent.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent searches',
                          style: AppTheme.serif(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await SearchHistoryStorage.instance.clear();
                            _loadRecent();
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recent
                          .map(
                            (q) => ActionChip(
                              avatar: const Icon(
                                Icons.history_rounded,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              label: Text(
                                q,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              backgroundColor: Colors.white,
                              shape: const StadiumBorder(
                                side: BorderSide(color: AppColors.borderWarm),
                              ),
                              onPressed: () {
                                _controller.text = q;
                                _submit(q);
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    'Popular searches',
                    style: AppTheme.serif(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularSearches
                        .map(
                          (q) => ActionChip(
                            avatar: const Icon(
                              Icons.trending_up_rounded,
                              size: 15,
                              color: AppColors.primaryDeep,
                            ),
                            label: Text(
                              q,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            shape: const StadiumBorder(
                              side: BorderSide(color: AppColors.borderWarm),
                            ),
                            onPressed: () {
                              _controller.text = q;
                              _submit(q);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CURATED COLLECTIONS',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Explore by care need',
                    style: AppTheme.serif(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.18,
                    children: [
                      _SearchEditorialTile(
                        eyebrow: 'DAIRY & CATTLE',
                        titleLine1: 'Peak milk',
                        titleLine2: '& herd vitality',
                        bgColor: const Color(0xFFFFF4DC),
                        accentColor: const Color(0xFF7A4B0A),
                        badgeText: '3×',
                        badgeSub: 'MINERALS',
                        onTap: () =>
                            context.go('/products?animalType=Cattle'),
                      ),
                      _SearchEditorialTile(
                        eyebrow: 'PARASITE SHIELD',
                        titleLine1: 'Tick, flea',
                        titleLine2: '& deworming',
                        bgColor: const Color(0xFFE6F5EC),
                        accentColor: const Color(0xFF0A4733),
                        badgeText: '360°',
                        badgeSub: 'SHIELD',
                        onTap: () =>
                            context.go('/products?category=Medicine'),
                      ),
                      _SearchEditorialTile(
                        eyebrow: 'DAILY NUTRITION',
                        titleLine1: 'Dog & cat',
                        titleLine2: 'wholesome feed',
                        bgColor: const Color(0xFFFFEDE6),
                        accentColor: const Color(0xFF7C2D12),
                        badgeText: 'A+',
                        badgeSub: 'PROTEIN',
                        onTap: () => context.go('/products?category=Feed'),
                      ),
                      _SearchEditorialTile(
                        eyebrow: 'CLINICAL TONICS',
                        titleLine1: 'Liver, gut',
                        titleLine2: '& immunity',
                        bgColor: const Color(0xFFEDE9FE),
                        accentColor: const Color(0xFF3B1D7A),
                        badgeText: 'Vet',
                        badgeSub: 'GRADE',
                        onTap: () =>
                            context.go('/products?category=Supplement'),
                      ),
                      _SearchEditorialTile(
                        eyebrow: 'FLOCK HEALTH',
                        titleLine1: 'Poultry growth',
                        titleLine2: '& egg boosters',
                        bgColor: const Color(0xFFFEF3C7),
                        accentColor: const Color(0xFF78350F),
                        badgeText: 'Pro',
                        badgeSub: 'FLOCK',
                        onTap: () =>
                            context.go('/products?animalType=Poultry'),
                      ),
                      _SearchEditorialTile(
                        eyebrow: '24/7 AI & VET',
                        titleLine1: 'Ask Dr. Paw',
                        titleLine2: 'symptom check',
                        bgColor: const Color(0xFF10382C),
                        accentColor: const Color(0xFFE2F8EC),
                        badgeText: 'AI',
                        badgeSub: 'INSTANT',
                        isDark: true,
                        onTap: () => context.push('/vet'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _suggestionsPanel() {
    final query = _controller.text.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: _searchError != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_searchError!),
                      TextButton(
                        onPressed: () => _onChanged(_controller.text),
                        child: const Text('Retry'),
                      ),
                      TextButton(
                        onPressed: () => _submit(query),
                        child: const Text('View all results'),
                      ),
                    ],
                  ),
                )
              : _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppLoader(size: 16, strokeWidth: 2),
                      SizedBox(width: 8),
                      Text(
                        'Finding matching products...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_suggestions.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Text(
                          'SUGGESTED PRODUCTS',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      for (var i = 0; i < _suggestions.length; i++)
                        _suggestionRow(_suggestions[i]),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Center(
                          child: Text(
                            'No close matches yet',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Center(
                          child: Text(
                            'Try a product name, animal type, brand, or category.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    GestureDetector(
                      onTap: () => _submit(query),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'View all results for "$query"',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Text(
                              '→',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _suggestionRow(SearchSuggestion item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _debounce?.cancel();
          setState(() => _showSuggestions = false);
          SearchHistoryStorage.instance.add(item.name);
          context.push('/product/${item.targetId}');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.image == null
                      ? AppColors.primaryWash
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.image != null
                    ? CachedNetworkImage(
                        imageUrl: item.image!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.medication_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.medication_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.brand?.isNotEmpty == true
                          ? item.brand!
                          : item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
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
  }
}

class _SearchEditorialTile extends StatelessWidget {
  const _SearchEditorialTile({
    required this.eyebrow,
    required this.titleLine1,
    required this.titleLine2,
    required this.bgColor,
    required this.accentColor,
    required this.badgeText,
    required this.badgeSub,
    required this.onTap,
    this.isDark = false,
  });

  final String eyebrow;
  final String titleLine1;
  final String titleLine2;
  final Color bgColor;
  final Color accentColor;
  final String badgeText;
  final String badgeSub;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF14241E);
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -12,
              bottom: -12,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.only(right: 12, bottom: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badgeText,
                      style: AppTheme.serif(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      badgeSub,
                      style: TextStyle(
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    titleLine1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.serif(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      color: textColor,
                    ),
                  ),
                  Text(
                    titleLine2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.serif(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                      color: accentColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'By KK Nutrivet',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.72)
                          : AppColors.textSecondary,
                    ),
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
