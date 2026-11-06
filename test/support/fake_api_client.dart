/// A route-aware fake for [ApiClient] used by widget, journey and route tests.
///
/// Unlike ad-hoc fakes in individual tests, this one understands the API's
/// resource shapes, so overriding only [apiClientProvider] lets the real
/// services, notifiers and screens run end-to-end without a network.
library;

import 'dart:async';

import 'package:nvit_app/core/network/api_client.dart';

import 'fixtures.dart';

class ApiCall {
  ApiCall({
    required this.method,
    required this.path,
    this.query,
    this.data,
    this.filePath,
  });

  final String method;
  final String path;
  final Map<String, dynamic>? query;
  final dynamic data;
  final String? filePath;

  @override
  String toString() => '$method $path query=$query';
}

/// Values may be a plain response, or a callback receiving the [ApiCall].
typedef FakeResponseBuilder = dynamic Function(ApiCall call);

class _ErrorRoute {
  _ErrorRoute(this.pattern, this.error);
  final Pattern pattern;
  final ApiException error;

  bool matches(ApiCall call) {
    final haystack = '${call.method} ${call.path}';
    final pattern = this.pattern;
    if (pattern is RegExp) {
      return pattern.hasMatch(haystack) || pattern.hasMatch(call.path);
    }
    final text = pattern.toString();
    return haystack == text ||
        call.path == text ||
        haystack.startsWith('$text ') ||
        haystack.startsWith('$text?');
  }
}

class FakeApiClient implements ApiClient {
  FakeApiClient({
    Map<String, dynamic>? routes,
    Map<Pattern, dynamic>? patternRoutes,
    this.handler,
    this.delay,
  })  : _routes = routes ?? {},
        _patternRoutes = patternRoutes ?? {};

  final Map<String, dynamic> _routes;
  final Map<Pattern, dynamic> _patternRoutes;
  final dynamic Function(ApiCall call)? handler;
  final Duration? delay;

  final List<ApiCall> calls = [];
  final List<_ErrorRoute> _errorRoutes = [];

  @override
  void updateBaseUrl(String newBaseUrl) {}

  /// Makes every matching request throw [error] (e.g. to test 401/500 flows).
  void failOn(Pattern pattern, ApiException error) {
    _errorRoutes.add(_ErrorRoute(pattern, error));
  }

  void clearCalls() => calls.clear();

  List<ApiCall> callsTo(String path, {String? method}) => calls
      .where((c) => c.path == path && (method == null || c.method == method))
      .toList();

  Future<dynamic> _handle(
    String method,
    String path, {
    Map<String, dynamic>? query,
    dynamic data,
    String? filePath,
  }) async {
    final call = ApiCall(
      method: method,
      path: path,
      query: query,
      data: data,
      filePath: filePath,
    );
    calls.add(call);

    if (delay != null) await Future<void>.delayed(delay!);

    for (final errorRoute in _errorRoutes) {
      if (errorRoute.matches(call)) throw errorRoute.error;
    }

    final resolved = _resolve(call);
    // Allow tests to return Futures/Throws from custom handlers.
    return await Future<dynamic>.value(resolved);
  }

  dynamic _resolve(ApiCall call) {
    final exact = _routes['${call.method} ${call.path}'];
    if (exact != null) return _materialize(exact, call);

    final byPath = _routes[call.path];
    if (byPath != null) return _materialize(byPath, call);

    for (final entry in _patternRoutes.entries) {
      final pattern = entry.key;
      if (pattern is RegExp && pattern.hasMatch(call.path)) {
        return _materialize(entry.value, call);
      }
      if (pattern is String && pattern == call.path) {
        return _materialize(entry.value, call);
      }
    }

    final custom = handler?.call(call);
    if (custom != null) return custom;

    return _defaultResponse(call);
  }

  dynamic _materialize(dynamic value, ApiCall call) {
    if (value is FakeResponseBuilder) return value(call);
    return value;
  }

  dynamic _defaultResponse(ApiCall call) {
    final method = call.method;
    final path = call.path;
    final query = call.query ?? const <String, dynamic>{};

    if (method != 'GET') {
      return <String, dynamic>{};
    }

    switch (path) {
      case '/settings':
        return settingsJson();
      case '/auth/profile':
        return userJson();
      case '/referral':
        return referralJson();
      case '/delivery':
        return deliveryJson(pincode: (query['pincode'] ?? '751007').toString());
      case '/products/facets':
        return productFacetsJson();
      case '/orders/tracking':
        return <String, dynamic>{
          'trackingStatus': 'In transit',
          'courierName': 'NimbusPost',
          'awbNumber': 'AWB123',
        };
      case '/consultations/slots':
        return <String, dynamic>{
          'date': query['date'] ?? 'today',
          'slots': const <Map<String, dynamic>>[],
        };
      case '/search/suggestions':
        return <String, dynamic>{'suggestions': const <Map<String, dynamic>>[]};
      case '/homepage-sections':
        return <String, dynamic>{'sections': const <Map<String, dynamic>>[]};
      case '/announcements':
        return <String, dynamic>{
          'announcements': const <Map<String, dynamic>>[],
        };
      case '/payments/cashfree/availability':
        return <String, dynamic>{
          'available': true,
          'enabled': true,
          'message': 'Available',
        };
      case '/payments/cashfree/create':
        return <String, dynamic>{
          'paymentSessionId': 'session-1',
          'orderId': 'cf-1',
          'paymentLink': 'https://example.com/pay',
        };
      case '/payments/cashfree/verify':
        return <String, dynamic>{'status': 'PAID', 'paid': true};
      case '/cart':
        return const <Map<String, dynamic>>[];
      case '/orders':
        return [orderJson()];
      case '/products':
        if (query['ids'] != null) return testProducts;
        return testProducts;
      case '/categories':
        return testCategories;
      case '/brands':
        return const <Map<String, dynamic>>[];
      case '/health-concerns':
        return testHealthConcerns;
      case '/combos':
        if (query['id'] != null) {
          return comboJson(id: query['id'].toString());
        }
        return [comboJson()];
      case '/blog':
        if (query['slug'] != null) {
          return blogPostJson(slug: query['slug'].toString());
        }
        return <String, dynamic>{'posts': [blogPostJson()]};
      case '/vet-insights':
        return const <Map<String, dynamic>>[];
      case '/shots':
        return <String, dynamic>{'shots': const <Map<String, dynamic>>[]};
      case '/addresses':
        return testAddresses;
      case '/pets':
        return testPets;
      case '/consultations':
        return [consultationJson()];
      case '/prescriptions':
        return [prescriptionJson()];
      case '/coupons':
        return const <Map<String, dynamic>>[];
      case '/notifications':
        return const <Map<String, dynamic>>[];
    }

    // Dynamic resources.
    final ordersMatch = RegExp(r'^/orders/([^/]+)$').firstMatch(path);
    if (ordersMatch != null) {
      return orderJson(id: ordersMatch.group(1)!);
    }

    final consultMessagesMatch =
        RegExp(r'^/consultations/([^/]+)/messages$').firstMatch(path);
    if (consultMessagesMatch != null) {
      return <String, dynamic>{
        'messages': const <Map<String, dynamic>>[],
        'canMessage': true,
        'hasMore': false,
      };
    }

    final consultMatch = RegExp(r'^/consultations/([^/]+)$').firstMatch(path);
    if (consultMatch != null) {
      return consultationJson(id: consultMatch.group(1)!);
    }

    final petsMatch = RegExp(r'^/pets/([^/]+)$').firstMatch(path);
    if (petsMatch != null) {
      return petJson(id: petsMatch.group(1)!);
    }

    final prescriptionMatch =
        RegExp(r'^/prescriptions/([^/]+)$').firstMatch(path);
    if (prescriptionMatch != null) {
      return prescriptionJson(id: prescriptionMatch.group(1)!);
    }

    final productMatch =
        RegExp(r'^/products/([^/]+)$').firstMatch(path);
    if (productMatch != null && productMatch.group(1) != 'facets') {
      final id = productMatch.group(1)!;
      final match = testProducts.where((p) => p['id'] == id || p['slug'] == id);
      if (match.isNotEmpty) return match.first;
      return productJson(id: id, slug: id);
    }

    // Listing endpoints are the common case; empty lists render empty states.
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _handle('GET', path, query: query);

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) =>
      _handle('POST', path, data: data, query: query);

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) =>
      _handle('PUT', path, data: data, query: query);

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) =>
      _handle('PATCH', path, data: data, query: query);

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _handle('DELETE', path, query: query);

  @override
  Future<dynamic> upload(
    String path,
    String filePath, {
    String fileField = 'file',
    Map<String, dynamic>? fields,
  }) =>
      _handle('UPLOAD', path, data: fields, filePath: filePath);
}
