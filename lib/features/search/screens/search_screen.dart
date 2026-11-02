import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/search_history_storage.dart';
import '../../../core/theme/app_theme.dart';
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
  bool _showSuggestions = false;
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await SearchHistoryStorage.instance.readAll();
    if (mounted) setState(() => _recent = recent);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
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
      final results = await ref
          .read(catalogServiceProvider)
          .fetchSuggestions(query);
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  Future<void> _submit(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    _debounce?.cancel();
    setState(() => _showSuggestions = false);
    await SearchHistoryStorage.instance.add(q);
    if (!mounted) return;
    context.push('/products?search=${Uri.encodeComponent(q)}');
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
            height: 44,
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
                      hintText:
                          'Search by product, animal, brand, or category',
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
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      _onChanged('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _submit(_controller.text),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
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
                if (_recent.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent searches',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
                              color: AppColors.primary,
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
                            avatar: const Icon(Icons.history, size: 15),
                            label: Text(q),
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
                const Text(
                  'Popular searches',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
                            Icons.trending_up,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          label: Text(q),
                          onPressed: () {
                            _controller.text = q;
                            _submit(q);
                          },
                        ),
                      )
                      .toList(),
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
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
