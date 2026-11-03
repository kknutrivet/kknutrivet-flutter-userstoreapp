import '../database/local_database.dart';

class SearchHistoryStorage {
  SearchHistoryStorage._();
  static final SearchHistoryStorage instance = SearchHistoryStorage._();

  static const _key = 'recent_searches';
  static const _max = 8;

  Future<List<String>> readAll() async {
    final list = await LocalDatabase.instance.get<List>(_key);
    return list?.map((e) => e.toString()).toList() ?? const [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final current = (await readAll()).toList();
    current.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    await LocalDatabase.instance.put(_key, current.take(_max).toList());
  }

  Future<void> clear() => LocalDatabase.instance.delete(_key);
}
