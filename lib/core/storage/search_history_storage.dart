import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStorage {
  SearchHistoryStorage._();
  static final SearchHistoryStorage instance = SearchHistoryStorage._();

  static const _key = 'recent_searches';
  static const _max = 8;

  Future<List<String>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    await prefs.setStringList(_key, current.take(_max).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
