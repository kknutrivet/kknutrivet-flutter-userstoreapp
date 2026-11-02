import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_theme.dart';

class LocationSearchBottomSheet extends StatefulWidget {
  const LocationSearchBottomSheet({super.key});

  static Future<LocationSearchResult?> show(BuildContext context) {
    return showModalBottomSheet<LocationSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationSearchBottomSheet(),
    );
  }

  @override
  State<LocationSearchBottomSheet> createState() =>
      _LocationSearchBottomSheetState();
}

class _LocationSearchBottomSheetState extends State<LocationSearchBottomSheet> {
  final _searchController = TextEditingController();
  List<LocationSearchResult> _results = [];
  bool _searching = false;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = [];
        _searching = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(trimmed);
    });
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final items = await LocationService.instance.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _results = items;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not search location. Check your internet connection.';
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Search Location or Area',
                style: AppTheme.serif(fontSize: 16.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onQueryChanged,
            onSubmitted: _executeSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Enter city, locality, area, or pincode...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onQueryChanged('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.error),
                ),
              ),
            )
          else if (_results.isEmpty && _searchController.text.trim().length >= 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined, size: 32, color: AppColors.textTertiary),
                    SizedBox(height: 8),
                    Text(
                      'No matching locations found',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Try typing your town, district, or 6-digit pincode.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 8),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderWarm),
                itemBuilder: (context, i) {
                  final item = _results[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWash,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.place_rounded, color: AppColors.primaryDeep, size: 20),
                    ),
                    title: Text(
                      item.title ?? item.displayName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.subtitle != null && item.subtitle!.isNotEmpty)
                          Text(
                            item.subtitle!,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (item.zipCode != null && item.zipCode!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                'PIN: ${item.zipCode}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
