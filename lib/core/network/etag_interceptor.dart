import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../database/local_database.dart';

/// Dio Interceptor that implements ETag HTTP caching (RFC 7232) and local DB storage:
/// 1. Sends `If-None-Match: <etag>` for cached endpoints on GET requests.
/// 2. When server returns `304 Not Modified`, serves from the ultra-fast local database (0 bytes over wire).
/// 3. When server returns `200 OK`, extracts and persists the new ETag and JSON payload in the local DB.
/// 4. When offline or connection drops, gracefully serves cached data from the local DB.
/// 5. Automatically invalidates related cache keys on successful mutations (POST, PUT, PATCH, DELETE).
class ETagInterceptor extends Interceptor {
  ETagInterceptor({LocalDatabase? database})
      : _db = database ?? LocalDatabase.instance;

  final LocalDatabase _db;

  static const String _cacheKeyField = 'etag_cache_key';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final method = options.method.toUpperCase();

    // Only GET and HEAD requests use ETag caching
    if (method != 'GET' && method != 'HEAD') {
      return handler.next(options);
    }

    // Skip bypassed or sensitive routes (login, OTP, payments)
    if (_isBypassedPath(options.path)) {
      return handler.next(options);
    }

    // Check for explicit no-cache header
    final cacheControl = options.headers['Cache-Control']?.toString().toLowerCase();
    if (cacheControl != null && (cacheControl.contains('no-cache') || cacheControl.contains('no-store'))) {
      return handler.next(options);
    }

    try {
      final isAuth = options.headers.containsKey('Authorization');
      final key = LocalDatabase.buildCacheKey(
        method: method,
        path: options.path,
        queryParameters: options.queryParameters,
        isAuth: isAuth,
      );

      options.extra[_cacheKeyField] = key;

      final entry = await _db.getCacheEntry(key);
      if (entry != null && entry.etag.isNotEmpty) {
        // Attach strong or weak ETag for server conditional validation
        options.headers['If-None-Match'] = entry.etag;
      }
    } catch (e) {
      debugPrint('[ETagInterceptor] onRequest error: $e');
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final method = response.requestOptions.method.toUpperCase();
    final path = response.requestOptions.path;

    // 1. Handle HTTP 304 Not Modified -> Serve from local database
    if (response.statusCode == 304) {
      final key = (response.requestOptions.extra[_cacheKeyField] as String?) ??
          LocalDatabase.buildCacheKey(
            method: method,
            path: path,
            queryParameters: response.requestOptions.queryParameters,
            isAuth: response.requestOptions.headers.containsKey('Authorization'),
          );

      final cached = await _db.getCacheEntry(key);
      if (cached != null) {
        final resolved = Response<dynamic>(
          requestOptions: response.requestOptions,
          data: cached.data,
          statusCode: 200,
          headers: response.headers,
          isRedirect: response.isRedirect,
          redirects: response.redirects,
          statusMessage: 'Not Modified (Served from ETag Cache)',
          extra: Map<String, dynamic>.from(response.extra)
            ..['from_etag_cache'] = true,
        );
        return handler.resolve(resolved);
      }
    }

    // 2. Handle HTTP 200 OK -> Save new ETag & Payload into local database
    if (response.statusCode == 200 && method == 'GET' && !_isBypassedPath(path)) {
      final etag = _extractEtag(response.headers);
      if (etag != null && etag.isNotEmpty) {
        final key = (response.requestOptions.extra[_cacheKeyField] as String?) ??
            LocalDatabase.buildCacheKey(
              method: method,
              path: path,
              queryParameters: response.requestOptions.queryParameters,
              isAuth: response.requestOptions.headers.containsKey('Authorization'),
            );

        final isUserScoped = _isUserScoped(path) ||
            response.requestOptions.headers.containsKey('Authorization');

        await _db.saveCacheEntry(
          key: key,
          etag: etag,
          data: response.data,
          path: path,
          isUserScoped: isUserScoped,
        );
      }
    }

    // 3. Handle Mutations -> Invalidate related cached collections
    if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
      await _invalidateRelatedCaches(path);
    }

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final method = err.requestOptions.method.toUpperCase();
    final path = err.requestOptions.path;

    // Mutations that return 404 (e.g. item/combo already deleted on server)
    // must still invalidate local cached collections so stale data isn't served.
    if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method) &&
        err.response?.statusCode == 404) {
      await _invalidateRelatedCaches(path);
    }

    // Check if server replied with 304 inside an error (fallback if validateStatus didn't catch)
    if (err.response?.statusCode == 304) {
      final key = (err.requestOptions.extra[_cacheKeyField] as String?) ??
          LocalDatabase.buildCacheKey(
            method: method,
            path: path,
            queryParameters: err.requestOptions.queryParameters,
            isAuth: err.requestOptions.headers.containsKey('Authorization'),
          );

      final cached = await _db.getCacheEntry(key);
      if (cached != null) {
        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: cached.data,
            statusCode: 200,
            extra: {'from_etag_cache': true},
          ),
        );
      }
    }

    // Offline / Connection error fallback: serve stale cached data if available
    final isConnectionFailure =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (isConnectionFailure && method == 'GET' && !_isBypassedPath(path)) {
      final key = (err.requestOptions.extra[_cacheKeyField] as String?) ??
          LocalDatabase.buildCacheKey(
            method: method,
            path: path,
            queryParameters: err.requestOptions.queryParameters,
            isAuth: err.requestOptions.headers.containsKey('Authorization'),
          );

      final cached = await _db.getCacheEntry(key);
      if (cached != null && cached.data != null) {
        debugPrint('📦 [ETagInterceptor] Offline fallback used for $path');
        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            data: cached.data,
            statusCode: 200,
            extra: {'from_offline_cache': true},
          ),
        );
      }
    }

    handler.next(err);
  }

  String? _extractEtag(Headers headers) {
    final raw = headers.value('etag') ?? headers.value('ETag');
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isNotEmpty ? trimmed : null;
  }

  bool _isBypassedPath(String path) {
    final lower = path.toLowerCase();
    return lower.contains('/auth/login') ||
        lower.contains('/auth/send-otp') ||
        lower.contains('/auth/verify-otp') ||
        lower.contains('/payments/cashfree') ||
        lower.contains('/payments/order-session');
  }

  bool _isUserScoped(String path) {
    final lower = path.toLowerCase();
    return lower.startsWith('/cart') ||
        lower.startsWith('/auth/profile') ||
        lower.startsWith('/orders') ||
        lower.startsWith('/pets') ||
        lower.startsWith('/prescriptions') ||
        lower.startsWith('/addresses') ||
        lower.startsWith('/referral') ||
        lower.startsWith('/coupons') ||
        lower.startsWith('/consultations');
  }

  Future<void> _invalidateRelatedCaches(String mutationPath) async {
    final lower = mutationPath.toLowerCase();

    if (lower.contains('/cart')) {
      await _db.invalidateMatching('/cart');
    } else if (lower.contains('/addresses')) {
      await _db.invalidateMatching('/addresses');
    } else if (lower.contains('/orders')) {
      await _db.invalidateMatching('/orders');
      await _db.invalidateMatching('/cart');
    } else if (lower.contains('/pets')) {
      await _db.invalidateMatching('/pets');
    } else if (lower.contains('/prescriptions')) {
      await _db.invalidateMatching('/prescriptions');
    } else if (lower.contains('/consultations')) {
      await _db.invalidateMatching('/consultations');
    } else if (lower.contains('/auth/profile')) {
      await _db.invalidateMatching('/auth/profile');
    } else if (lower.contains('/products')) {
      await _db.invalidateMatching('/products');
      await _db.invalidateMatching('/homepage-sections');
    }
  }
}
