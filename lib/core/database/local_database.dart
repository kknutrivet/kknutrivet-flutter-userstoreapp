import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a cached HTTP response entry with its ETag and metadata.
class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.etag,
    required this.data,
    required this.savedAt,
    this.isUserScoped = false,
    this.path = '',
  });

  final String key;
  final String etag;
  final dynamic data;
  final DateTime savedAt;
  final bool isUserScoped;
  final String path;

  Map<String, dynamic> toJson() => {
        'key': key,
        'etag': etag,
        'data': data,
        'savedAt': savedAt.toIso8601String(),
        'isUserScoped': isUserScoped,
        'path': path,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String? ?? '',
      etag: json['etag'] as String? ?? '',
      data: json['data'],
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
      isUserScoped: json['isUserScoped'] as bool? ?? false,
      path: json['path'] as String? ?? '',
    );
  }
}

/// High-performance local database for KK Nutrivet:
/// 1. Level-1: In-memory cache for sub-millisecond (0ms) access.
/// 2. Level-2: Persistent local storage (SharedPreferences) for fast cold starts.
/// 3. ETag store: Handles HTTP entity tags, 304 revalidations, and offline fallbacks.
/// 4. Generic document store: Fast key-value persistence across the app.
class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String _etagPrefix = 'kknv_etag_';
  static const String _docPrefix = 'kknv_doc_';
  static const String _indexKey = 'kknv_etag_keys_v1';
  static const int _maxCacheEntries = 160;

  // L1 In-Memory Caches for ultra-fast zero-latency reads
  final Map<String, CacheEntry> _etagMemoryCache = <String, CacheEntry>{};
  final Map<String, dynamic> _docMemoryCache = <String, dynamic>{};
  final Set<String> _persistedEtagKeys = <String>{};

  bool _initialized = false;
  SharedPreferences? _prefs;

  /// Initializes the local database and primes the in-memory index from disk.
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final keysList = _prefs?.getStringList(_indexKey) ?? [];
      _persistedEtagKeys.addAll(keysList);
      _initialized = true;
    } catch (e) {
      // In unit tests without mock SharedPreferences, fallback gracefully to in-memory
      _initialized = true;
      debugPrint('[LocalDatabase] Running with in-memory store: $e');
    }
  }

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    await init();
    return _prefs;
  }

  // ===========================================================================
  // ETAG & HTTP CACHE OPERATIONS
  // ===========================================================================

  /// Retrieves an ETag cache entry by deterministic key.
  /// Checks L1 memory first (instant), falls back to L2 disk if needed.
  Future<CacheEntry?> getCacheEntry(String key) async {
    // 1. L1 Memory Lookup (microsecond response)
    if (_etagMemoryCache.containsKey(key)) {
      return _etagMemoryCache[key];
    }

    // 2. L2 Disk Lookup
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;

      final raw = prefs.getString('$_etagPrefix$key');
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final entry = CacheEntry.fromJson(Map<String, dynamic>.from(decoded));
      _etagMemoryCache[key] = entry; // Promote to L1
      return entry;
    } catch (_) {
      return null;
    }
  }

  /// Saves or updates an ETag cache entry.
  /// Writes to L1 memory immediately, and persists to L2 disk asynchronously.
  Future<void> saveCacheEntry({
    required String key,
    required String etag,
    required dynamic data,
    required String path,
    bool isUserScoped = false,
  }) async {
    final cleanEtag = etag.trim();
    if (cleanEtag.isEmpty) return;

    final entry = CacheEntry(
      key: key,
      etag: cleanEtag,
      data: data,
      savedAt: DateTime.now(),
      isUserScoped: isUserScoped,
      path: path,
    );

    // 1. Instant L1 memory write
    _etagMemoryCache[key] = entry;

    // 2. Asynchronous L2 persistence (non-blocking)
    unawaited(_persistEntry(key, entry));
  }

  Future<void> _persistEntry(String key, CacheEntry entry) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;

      final jsonStr = jsonEncode(entry.toJson());

      // Skip disk serialization for massive payloads (> 450 KB) to prevent memory pressure
      if (jsonStr.length > 450 * 1024) return;

      await prefs.setString('$_etagPrefix$key', jsonStr);

      _persistedEtagKeys.add(key);

      // LRU Eviction: Prune oldest entries if size exceeds limit
      if (_persistedEtagKeys.length > _maxCacheEntries) {
        await _pruneOldestEntries(prefs);
      } else {
        await prefs.setStringList(_indexKey, _persistedEtagKeys.toList());
      }
    } catch (_) {
      // Best-effort disk persistence
    }
  }

  Future<void> _pruneOldestEntries(SharedPreferences prefs) async {
    try {
      // Keep most recently added half
      final toRemoveCount = _persistedEtagKeys.length - (_maxCacheEntries - 20);
      if (toRemoveCount <= 0) return;

      final removeKeys = _persistedEtagKeys.take(toRemoveCount).toList();
      for (final k in removeKeys) {
        _persistedEtagKeys.remove(k);
        _etagMemoryCache.remove(k);
        await prefs.remove('$_etagPrefix$k');
      }
      await prefs.setStringList(_indexKey, _persistedEtagKeys.toList());
    } catch (_) {}
  }

  /// Fast helper to get a cached payload for a path + query.
  Future<dynamic> getCachedPayload(
    String path, {
    Map<String, dynamic>? query,
    bool isAuth = false,
  }) async {
    final key = buildCacheKey(
      method: 'GET',
      path: path,
      queryParameters: query,
      isAuth: isAuth,
    );
    final entry = await getCacheEntry(key);
    return entry?.data;
  }

  /// Deterministically builds a cache key from HTTP parameters.
  static String buildCacheKey({
    required String method,
    required String path,
    Map<String, dynamic>? queryParameters,
    bool isAuth = false,
  }) {
    final m = method.toUpperCase();
    final p = path.startsWith('/') ? path : '/$path';

    String queryStr = '';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sortedKeys = queryParameters.keys.toList()..sort();
      queryStr =
          '?${sortedKeys.map((k) => '$k=${queryParameters[k]}').join('&')}';
    }

    final scope = isAuth ? 'user' : 'public';
    return '$scope:$m:$p$queryStr';
  }

  /// Invalidates all cached entries related to a mutated path (e.g. /cart, /orders, /pets).
  Future<void> invalidateMatching(String pathPattern) async {
    final normalized = pathPattern.toLowerCase();

    // 1. Clear matching keys from L1
    _etagMemoryCache.removeWhere((k, entry) =>
        k.toLowerCase().contains(normalized) ||
        entry.path.toLowerCase().contains(normalized));

    // 2. Clear matching keys from L2
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;

      final toDelete = _persistedEtagKeys
          .where((k) => k.toLowerCase().contains(normalized))
          .toList();

      for (final k in toDelete) {
        _persistedEtagKeys.remove(k);
        await prefs.remove('$_etagPrefix$k');
      }
      await prefs.setStringList(_indexKey, _persistedEtagKeys.toList());
    } catch (_) {}
  }

  /// Clears all user-scoped data upon logout while preserving public product/catalogue data.
  Future<void> clearUserScoped() async {
    // 1. Clear user keys from L1
    _etagMemoryCache.removeWhere((k, entry) => entry.isUserScoped || k.startsWith('user:'));

    // 2. Clear user keys from L2
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;

      final toDelete = _persistedEtagKeys
          .where((k) => k.startsWith('user:'))
          .toList();

      for (final k in toDelete) {
        _persistedEtagKeys.remove(k);
        await prefs.remove('$_etagPrefix$k');
      }
      await prefs.setStringList(_indexKey, _persistedEtagKeys.toList());
    } catch (_) {}
  }

  /// Completely clears the local database cache.
  Future<void> clearAll() async {
    _etagMemoryCache.clear();
    _docMemoryCache.clear();
    _persistedEtagKeys.clear();
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;

      final allKeys = prefs.getKeys();
      for (final k in allKeys) {
        if (k.startsWith(_etagPrefix) || k.startsWith(_docPrefix) || k == _indexKey) {
          await prefs.remove(k);
        }
      }
    } catch (_) {}
  }

  // ===========================================================================
  // GENERIC FAST DOCUMENT / KEY-VALUE STORE
  // ===========================================================================

  /// Reads a document/value by key with L1 memory acceleration.
  Future<T?> get<T>(String key) async {
    if (_docMemoryCache.containsKey(key)) {
      return _docMemoryCache[key] as T?;
    }
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return null;

      final raw = prefs.getString('$_docPrefix$key');
      if (raw == null) return null;

      final decoded = jsonDecode(raw);
      _docMemoryCache[key] = decoded;
      return decoded as T?;
    } catch (_) {
      return null;
    }
  }

  /// Puts a document/value by key with instant L1 write and async L2 persist.
  Future<void> put<T>(String key, T value) async {
    _docMemoryCache[key] = value;
    unawaited(_persistDoc(key, value));
  }

  Future<void> _persistDoc(String key, dynamic value) async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      if (value == null) {
        await prefs.remove('$_docPrefix$key');
      } else {
        final encoded = jsonEncode(value);
        await prefs.setString('$_docPrefix$key', encoded);
      }
    } catch (_) {}
  }

  /// Deletes a document/value by key.
  Future<void> delete(String key) async {
    _docMemoryCache.remove(key);
    try {
      final prefs = await _getPrefs();
      await prefs?.remove('$_docPrefix$key');
    } catch (_) {}
  }

  /// Checks whether a document key exists.
  Future<bool> containsKey(String key) async {
    if (_docMemoryCache.containsKey(key)) return true;
    final prefs = await _getPrefs();
    return prefs?.containsKey('$_docPrefix$key') ?? false;
  }
}
