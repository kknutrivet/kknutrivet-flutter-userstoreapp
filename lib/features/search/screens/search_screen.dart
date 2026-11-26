import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/storage/search_history_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/compact_product_card.dart' show formatInr;
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

/// Exact mobile counterpart of `kknutrivet-webapp/src/app/search/SearchClient.tsx`:
/// - Sticky white header with visible back arrow, rounded-full search input pill
///   (with focus ring + inline clear button), and solid emerald submit circle.
/// - State 1 (empty query): Recent Searches (individual remove + Clear all),
///   Popular Searches, 2-column Browse by Animal pastel cards, and Upload
///   Prescription emerald gradient card.
/// - State 2 (loading): Spinner header + 5 suggestion skeleton cards.
/// - State 3 (matches): Suggested Products card with 48x48 thumbnails, COMBO
///   tag, brand/category, live ₹price / ₹mrp / % OFF, and prominent
///   "View all results" button.
/// - State 4 (no results): Empty-state card with catalog fallback, Browse all,
///   WhatsApp product request, and Prescription upload alternative.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const List<String> _popularSearches = [
    'Tick & Flea',
    'Deworming',
    'Milk & Calcium',
    'Mastitis Care',
    'Dog Food',
    'Liver Tonics',
    'Skin & Wound Spray',
    'Digestive Care',
  ];

  static const List<_BrowseAnimalItem> _popularAnimals = [
    _BrowseAnimalItem(
      label: 'Dogs',
      emoji: '🐶',
      route: '/products?animalType=Dog',
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      fg: Color(0xFF78350F),
    ),
    _BrowseAnimalItem(
      label: 'Cats',
      emoji: '🐱',
      route: '/products?animalType=Cat',
      bg: Color(0xFFFFF7ED),
      border: Color(0xFFFED7AA),
      fg: Color(0xFF7C2D12),
    ),
    _BrowseAnimalItem(
      label: 'Cattle & Dairy',
      emoji: '🐄',
      route: '/products?animalType=Cattle',
      bg: Color(0xFFECFDF5),
      border: Color(0xFFA7F3D0),
      fg: Color(0xFF064E3B),
    ),
    _BrowseAnimalItem(
      label: 'Goats & Sheep',
      emoji: '🐐',
      route: '/products?animalType=Goat%2FSheep',
      bg: Color(0xFFEFF6FF),
      border: Color(0xFFBFDBFE),
      fg: Color(0xFF1E3A8A),
    ),
    _BrowseAnimalItem(
      label: 'Poultry',
      emoji: '🐔',
      route: '/products?animalType=Poultry',
      bg: Color(0xFFFFF1F2),
      border: Color(0xFFFECDD3),
      fg: Color(0xFF881337),
    ),
    _BrowseAnimalItem(
      label: 'Small Pets',
      emoji: '🐹',
      route: '/products?animalType=Exotic+%26+Small+Pets',
      bg: Color(0xFFF0FDFA),
      border: Color(0xFF99F6E4),
      fg: Color(0xFF134E4A),
    ),
  ];

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<SearchSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _searchError;
  bool _focused = false;
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _loadRecent();
    if ((widget.initialQuery ?? '').trim().length >= 2) {
      _fetchSuggestions(widget.initialQuery!);
    }
  }

  void _onFocusChange() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  Future<void> _loadRecent() async {
    final recent = await SearchHistoryStorage.instance.readAll();
    if (mounted) setState(() => _recent = recent);
  }

  void _fetchSuggestions(String raw) {
    _debounce?.cancel();
    _searchError = null;
    final clean = raw.trim();
    if (clean.length < 2) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      try {
        final results = await ref
            .read(catalogServiceProvider)
            .fetchSuggestions(clean);
        if (!mounted || _controller.text.trim() != clean) return;
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      } catch (_) {
        if (!mounted || _controller.text.trim() != clean) return;
        setState(() {
          _suggestions = const [];
          _searchError =
              'Could not load suggestions. Check your connection and retry.';
          _loading = false;
        });
      }
    });
  }

  void _onChanged(String value) {
    setState(() {});
    _fetchSuggestions(value);
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _suggestions = const [];
      _loading = false;
      _searchError = null;
    });
    _focusNode.requestFocus();
  }

  void _handleBack() {
    Haptics.tap();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _executeSearch(String searchTerm) async {
    final clean = searchTerm.trim();
    if (clean.isEmpty) return;
    _debounce?.cancel();
    await SearchHistoryStorage.instance.add(clean);
    await _loadRecent();
    if (!mounted) return;
    context.go('/products?search=${Uri.encodeComponent(clean)}');
  }

  Future<void> _openSuggestion(SearchSuggestion item) async {
    Haptics.tap();
    _debounce?.cancel();
    await SearchHistoryStorage.instance.add(item.name);
    if (!mounted) return;
    if (item.isCombo) {
      context.push('/combos/${item.id}');
    } else {
      context.push('/product/${item.targetId}');
    }
  }

  Future<void> _removeRecentItem(String term) async {
    Haptics.selection();
    final updated = await SearchHistoryStorage.instance.remove(term);
    if (mounted) setState(() => _recent = updated);
  }

  Future<void> _clearAllRecent() async {
    Haptics.selection();
    await SearchHistoryStorage.instance.clear();
    if (mounted) setState(() => _recent = const []);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final query = _controller.text.trim();
    final isQueryEmpty = query.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Sticky Header matching `SearchClient.tsx`
            Material(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 12, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Visible Back Arrow Button
                      Semantics(
                        button: true,
                        label: 'Go back',
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _handleBack,
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                size: 22,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Rounded-Full Search Input Pill
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _focused
                                  ? AppColors.brandPrimary
                                  : AppColors.borderStrong,
                              width: _focused ? 1.5 : 1,
                            ),
                            boxShadow: _focused
                                ? [
                                    BoxShadow(
                                      color: AppColors.brandPrimary.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 0,
                                      spreadRadius: 2.5,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  textInputAction: TextInputAction.search,
                                  onChanged: _onChanged,
                                  onSubmitted: _executeSearch,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: strings.searchHint,
                                    hintStyle: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_controller.text.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Semantics(
                                  button: true,
                                  label: 'Clear search',
                                  child: GestureDetector(
                                    onTap: _clearQuery,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: AppColors.border,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Solid Emerald Submit Circle Button
                      Semantics(
                        button: true,
                        label: 'Submit search',
                        child: Material(
                          color: AppColors.brandPrimary,
                          shape: const CircleBorder(),
                          elevation: 1,
                          shadowColor: AppColors.brandPrimary.withValues(
                            alpha: 0.3,
                          ),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _executeSearch(_controller.text),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 19,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: SafeArea(
                top: false,
                child: isQueryEmpty
                    ? _buildPreSearchContent(strings)
                    : _buildActiveSearchContent(query),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATE 1: EMPTY QUERY (PRE-SEARCH) ─────────────────────────────────────
  Widget _buildPreSearchContent(AppStrings strings) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.brandPrimary,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'RECENT SEARCHES',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _clearAllRecent,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
              for (final item in _recent)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      _controller.text = item;
                      _executeSearch(item);
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(11, 6, 7, 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              item,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _removeRecentItem(item),
                            child: Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],

        // Popular Searches
        const Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: Color(0xFFD97706),
            ),
            SizedBox(width: 5),
            Text(
              'POPULAR SEARCHES',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final term in _popularSearches)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    _controller.text = term;
                    _executeSearch(term);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      term,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 22),

        // Browse by Animal
        const Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: AppColors.brandPrimary,
            ),
            SizedBox(width: 5),
            Text(
              'BROWSE BY ANIMAL',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _popularAnimals.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 46,
          ),
          itemBuilder: (context, index) {
            final animal = _popularAnimals[index];
            return Material(
              color: animal.bg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Haptics.tap();
                  context.go(animal.route);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: animal.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        animal.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          strings.speciesLabel(animal.label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: animal.fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 22),

        // Prescription / Special Care Banner
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Haptics.tap();
              context.push('/prescriptions');
            },
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF07583F), Color(0xFF0B7454)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F07583F),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Vet Prescription',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share your care slip & our team will assist you',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── STATES 2, 3, 4: ACTIVE QUERY ──────────────────────────────────────────
  Widget _buildActiveSearchContent(String query) {
    // 1-character hint before min-2-char typeahead fires
    if (query.length < 2) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _executeSearch(query),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search for "$query"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // STATE 2: LOADING SKELETON (`SearchClient.tsx:375-390`)
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              const AppLoader(size: 15, strokeWidth: 2),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Searching products for "$query"...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  _SearchSkeletonBar(width: 48, height: 48, borderRadius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SearchSkeletonBar(
                          width: double.infinity,
                          height: 13,
                          borderRadius: 6,
                        ),
                        SizedBox(height: 8),
                        _SearchSkeletonBar(
                          width: 110,
                          height: 10,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    if (_searchError != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _searchError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => _fetchSuggestions(_controller.text),
                      child: const Text('Retry'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => _executeSearch(query),
                      child: const Text('Search catalog'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    // STATE 3: SUGGESTIONS / PRODUCT MATCHES (`SearchClient.tsx:393-491`)
    if (_suggestions.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'SUGGESTED PRODUCTS (${_suggestions.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _executeSearch(query),
                  child: const Text(
                    'View all results →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, thickness: 1, color: AppColors.border),
                  _buildSuggestionTile(_suggestions[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => _executeSearch(query),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'View all results for "$query"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // STATE 4: NO RESULTS FOUND (`SearchClient.tsx:494-541`)
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primaryWash,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_rounded,
                  size: 23,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No products found for "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Check for typos, try searching by animal type (e.g. Dog, Cattle), or browse our categories.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  onPressed: () => _executeSearch(query),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primaryWash,
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Search all catalog anyway',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton(
                  onPressed: () => context.go('/products'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Browse all products',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final msg = Uri.encodeComponent(
                      'Hi KK Nutrivet! I searched for "$query" and could not find it. Can you help me get this product?',
                    );
                    await launchUrl(
                      Uri.parse('https://wa.me/917846932453?text=$msg'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(
                    Icons.chat_rounded,
                    size: 15,
                    color: Color(0xFF15803D),
                  ),
                  label: Flexible(
                    child: Text(
                      'Request "$query" on WhatsApp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    backgroundColor: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),
              Material(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/prescriptions'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FAE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            size: 16,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need a hard-to-find medicine?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Upload prescription and our team will arrange it',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionTile(SearchSuggestion item) {
    final hasPrice = item.price != null && item.price! > 0;
    final hasDiscount =
        hasPrice && item.mrp != null && item.mrp! > item.price!;
    final discountPct = hasDiscount
        ? (((item.mrp! - item.price!) / item.mrp!) * 100).round()
        : 0;
    final subtitle = item.brand?.trim().isNotEmpty == true
        ? item.brand!.trim()
        : item.category;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openSuggestion(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.image?.isNotEmpty == true
                      ? AppColors.background
                      : AppColors.primaryWash,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.image?.isNotEmpty == true
                    ? AppNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.contain,
                        memCacheWidth: 140,
                        fallbackIcon: Icons.search_rounded,
                      )
                    : const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.brandPrimary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isCombo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'COMBO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (hasPrice) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${formatInr(item.price!)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₹${formatInr(item.mrp!)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            if (discountPct > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '$discountPct% OFF',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseAnimalItem {
  const _BrowseAnimalItem({
    required this.label,
    required this.emoji,
    required this.route,
    required this.bg,
    required this.border,
    required this.fg,
  });

  final String label;
  final String emoji;
  final String route;
  final Color bg;
  final Color border;
  final Color fg;
}

class _SearchSkeletonBar extends StatelessWidget {
  const _SearchSkeletonBar({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
