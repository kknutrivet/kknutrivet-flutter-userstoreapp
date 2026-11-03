import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/database/local_database.dart';
import 'package:nvit_app/core/network/etag_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestRequestHandler extends RequestInterceptorHandler {
  final completer = Completer<RequestOptions>();
  @override
  void next(RequestOptions requestOptions) {
    if (!completer.isCompleted) completer.complete(requestOptions);
  }
}

class _TestResponseHandler extends ResponseInterceptorHandler {
  final completer = Completer<Response>();
  @override
  void next(Response response) {
    if (!completer.isCompleted) completer.complete(response);
  }

  @override
  void resolve(Response response) {
    if (!completer.isCompleted) completer.complete(response);
  }
}

class _TestErrorHandler extends ErrorInterceptorHandler {
  final completer = Completer<Response>();
  @override
  void resolve(Response response) {
    if (!completer.isCompleted) completer.complete(response);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.instance.clearAll();
  });

  group('LocalDatabase Tests', () {
    test('L1/L2 generic document store puts, gets, and deletes', () async {
      final db = LocalDatabase.instance;

      expect(await db.get<String>('user_pref'), isNull);
      expect(await db.containsKey('user_pref'), isFalse);

      await db.put('user_pref', 'dark_theme');
      expect(await db.get<String>('user_pref'), 'dark_theme');
      expect(await db.containsKey('user_pref'), isTrue);

      await db.delete('user_pref');
      expect(await db.get<String>('user_pref'), isNull);
      expect(await db.containsKey('user_pref'), isFalse);
    });

    test('Stores and retrieves ETag cache entries', () async {
      final db = LocalDatabase.instance;
      const key = 'public:GET:/products';
      const etag = '"prod-hash-123"';
      final payload = {
        'products': [
          {'id': 'p1', 'name': 'Calcium Tonic'}
        ]
      };

      await db.saveCacheEntry(
        key: key,
        etag: etag,
        data: payload,
        path: '/products',
        isUserScoped: false,
      );

      final entry = await db.getCacheEntry(key);
      expect(entry, isNotNull);
      expect(entry!.etag, etag);
      expect(entry.data, payload);
      expect(entry.path, '/products');
      expect(entry.isUserScoped, isFalse);
    });

    test('Invalidates matching paths on mutation', () async {
      final db = LocalDatabase.instance;
      await db.saveCacheEntry(
        key: 'user:GET:/cart',
        etag: '"cart-1"',
        data: {'items': []},
        path: '/cart',
        isUserScoped: true,
      );
      await db.saveCacheEntry(
        key: 'public:GET:/products',
        etag: '"prod-1"',
        data: {'items': []},
        path: '/products',
        isUserScoped: false,
      );

      expect(await db.getCacheEntry('user:GET:/cart'), isNotNull);
      expect(await db.getCacheEntry('public:GET:/products'), isNotNull);

      // Invalidate cart
      await db.invalidateMatching('/cart');

      expect(await db.getCacheEntry('user:GET:/cart'), isNull);
      expect(await db.getCacheEntry('public:GET:/products'), isNotNull);
    });

    test('clearUserScoped removes user data and keeps public catalog', () async {
      final db = LocalDatabase.instance;
      await db.saveCacheEntry(
        key: 'user:GET:/orders',
        etag: '"order-tag"',
        data: [
          {'id': '101'}
        ],
        path: '/orders',
        isUserScoped: true,
      );
      await db.saveCacheEntry(
        key: 'public:GET:/brands',
        etag: '"brands-tag"',
        data: [
          {'id': 'b1'}
        ],
        path: '/brands',
        isUserScoped: false,
      );

      await db.clearUserScoped();

      expect(await db.getCacheEntry('user:GET:/orders'), isNull);
      expect(await db.getCacheEntry('public:GET:/brands'), isNotNull);
    });
  });

  group('ETagInterceptor Tests', () {
    test('Attaches If-None-Match header when ETag exists in local DB', () async {
      final db = LocalDatabase.instance;
      const key = 'public:GET:/products';
      await db.saveCacheEntry(
        key: key,
        etag: '"etag-xyz-999"',
        data: {'data': 'cached'},
        path: '/products',
      );

      final interceptor = ETagInterceptor(database: db);
      final options = RequestOptions(
        path: '/products',
        method: 'GET',
        headers: {},
      );

      final handler = _TestRequestHandler();
      interceptor.onRequest(options, handler);

      final modifiedOptions = await handler.completer.future;
      expect(modifiedOptions.headers['If-None-Match'], '"etag-xyz-999"');
    });

    test('Handles 304 Not Modified response by serving cached data', () async {
      final db = LocalDatabase.instance;
      const key = 'public:GET:/products';
      final cachedPayload = {
        'code': 'SUCCESS',
        'data': [
          {'id': 'item-1'}
        ]
      };

      await db.saveCacheEntry(
        key: key,
        etag: '"tag-304"',
        data: cachedPayload,
        path: '/products',
      );

      final interceptor = ETagInterceptor(database: db);
      final requestOptions = RequestOptions(
        path: '/products',
        method: 'GET',
        headers: {},
      );
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 304,
        data: null, // Server returns empty body on 304
      );

      final handler = _TestResponseHandler();
      interceptor.onResponse(response, handler);

      final resolved = await handler.completer.future;

      expect(resolved.statusCode, 200);
      expect(resolved.data, cachedPayload);
      expect(resolved.extra['from_etag_cache'], isTrue);
    });

    test('Saves new ETag and payload into local DB on 200 OK', () async {
      final db = LocalDatabase.instance;
      final interceptor = ETagInterceptor(database: db);

      final requestOptions = RequestOptions(
        path: '/products',
        method: 'GET',
        headers: {},
      );
      final response = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        headers: Headers.fromMap({
          'etag': ['"new-etag-200"'],
        }),
        data: {
          'code': 'SUCCESS',
          'data': [
            {'id': 'p200'}
          ]
        },
      );

      interceptor.onResponse(
        response,
        _TestResponseHandler(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final key = LocalDatabase.buildCacheKey(
        method: 'GET',
        path: '/products',
      );
      final entry = await db.getCacheEntry(key);
      expect(entry, isNotNull);
      expect(entry!.etag, '"new-etag-200"');
      expect(entry.data, {
        'code': 'SUCCESS',
        'data': [
          {'id': 'p200'}
        ]
      });
    });

    test('Invalidates related caches on successful mutation', () async {
      final db = LocalDatabase.instance;
      await db.saveCacheEntry(
        key: 'user:GET:/cart',
        etag: '"cart-tag"',
        data: {'items': []},
        path: '/cart',
      );

      final interceptor = ETagInterceptor(database: db);
      final mutationResponse = Response(
        requestOptions: RequestOptions(
          path: '/cart',
          method: 'POST',
        ),
        statusCode: 200,
        data: {'status': 'updated'},
      );

      interceptor.onResponse(
        mutationResponse,
        _TestResponseHandler(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final cachedCart = await db.getCacheEntry('user:GET:/cart');
      expect(cachedCart, isNull);
    });

    test('Offline fallback resolves with cached data when connection fails',
        () async {
      final db = LocalDatabase.instance;
      const key = 'public:GET:/health-concerns';
      final cachedConcerns = [
        {'name': 'Digestion'},
        {'name': 'Joints'}
      ];

      await db.saveCacheEntry(
        key: key,
        etag: '"concerns-tag"',
        data: cachedConcerns,
        path: '/health-concerns',
      );

      final interceptor = ETagInterceptor(database: db);
      final requestOptions = RequestOptions(
        path: '/health-concerns',
        method: 'GET',
      );
      final dioErr = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        message: 'No internet connection',
      );

      final handler = _TestErrorHandler();
      interceptor.onError(dioErr, handler);

      final resolvedResponse = await handler.completer.future;

      expect(resolvedResponse.statusCode, 200);
      expect(resolvedResponse.data, cachedConcerns);
      expect(resolvedResponse.extra['from_offline_cache'], isTrue);
    });
  });
}
