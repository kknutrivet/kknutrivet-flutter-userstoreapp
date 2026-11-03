import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../crashlytics/crashlytics_service.dart';
import '../device/device_info_service.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// Custom interceptor that prints detailed HTTP logs to Android Studio Logcat and Console.
class _ApiLoggingInterceptor extends Interceptor {
  final _stopwatches = Expando<Stopwatch>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _stopwatches[options] = Stopwatch()..start();

    final token = options.headers['Authorization']?.toString();
    final authSummary = token != null && token.length > 20
        ? '${token.substring(0, 15)}...${token.substring(token.length - 6)}'
        : (token ?? 'None');

    debugPrint('─────────────────────────────────────────────────────────────────');
    debugPrint('🚀 [HTTP-REQ] ${options.method} ${options.uri}');
    debugPrint('   Auth: $authSummary');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('   Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('   Body: ${options.data}');
    }
    debugPrint('─────────────────────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final sw = _stopwatches[response.requestOptions];
    final elapsed = sw != null ? ' (${sw.elapsedMilliseconds}ms)' : '';

    debugPrint('✅ [HTTP-RES] [${response.statusCode}] ${response.requestOptions.method} ${response.requestOptions.uri}$elapsed');
    debugPrint('   Data: ${response.data}');
    debugPrint('─────────────────────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sw = _stopwatches[err.requestOptions];
    final elapsed = sw != null ? ' (${sw.elapsedMilliseconds}ms)' : '';

    debugPrint('❌ [HTTP-ERR] [${err.response?.statusCode ?? err.type.name}] ${err.requestOptions.method} ${err.requestOptions.uri}$elapsed');
    if (err.response?.data != null) {
      debugPrint('   Error Body: ${err.response?.data}');
    } else {
      debugPrint('   Error Message: ${err.message}');
    }
    debugPrint('─────────────────────────────────────────────────────────────────');
    handler.next(err);
  }
}

/// Thin wrapper around Dio that talks to the nvit-frontend Next.js API.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final deviceHeaders = DeviceInfoService.instance.getApiHeaders();
          options.headers.addAll(deviceHeaders);

          final token = await TokenStorage.instance.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) => handler.next(error),
      ),
    );

    // Network logging interceptor for Android Studio Logcat & Run console.
    _dio.interceptors.add(_ApiLoggingInterceptor());
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  ApiClient.withDio(this._dio);

  /// Allows switching the active API base URL at runtime (e.g. prod vs test environment).
  void updateBaseUrl(String newBaseUrl) {
    final cleanUrl = newBaseUrl.endsWith('/')
        ? newBaseUrl.substring(0, newBaseUrl.length - 1)
        : newBaseUrl;
    _dio.options.baseUrl = '$cleanUrl/api';
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? query}) =>
      _request(() => _dio.post(path, data: data, queryParameters: query));

  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? query}) =>
      _request(() => _dio.put(path, data: data, queryParameters: query));

  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? query}) =>
      _request(() => _dio.patch(path, data: data, queryParameters: query));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _request(() => _dio.delete(path, queryParameters: query));

  Future<dynamic> upload(String path, String filePath,
      {String fileField = 'file', Map<String, dynamic>? fields}) async {
    try {
      final lower = filePath.toLowerCase();
      MediaType? contentType;
      if (lower.endsWith('.mp4')) {
        contentType = MediaType('video', 'mp4');
      } else if (lower.endsWith('.mov') || lower.endsWith('.qt')) {
        contentType = MediaType('video', 'quicktime');
      } else if (lower.endsWith('.webm')) {
        contentType = MediaType('video', 'webm');
      } else if (lower.endsWith('.3gp') || lower.endsWith('.3gpp')) {
        contentType = MediaType('video', '3gpp');
      } else if (lower.endsWith('.png')) {
        contentType = MediaType('image', 'png');
      } else if (lower.endsWith('.webp')) {
        contentType = MediaType('image', 'webp');
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
        contentType = MediaType('image', 'jpeg');
      } else if (lower.endsWith('.pdf')) {
        contentType = MediaType('application', 'pdf');
      }

      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(
          filePath,
          contentType: contentType,
        ),
        ...?fields,
      });
      final response = await _dio.post(path, data: formData);
      final body = response.data;
      if (body is Map &&
          body.containsKey('data') &&
          (body.containsKey('code') || body.containsKey('message'))) {
        return body['data'];
      }
      return body;
    } on DioException catch (e) {
      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        CrashlyticsService.instance.recordError(
          e,
          e.stackTrace,
          reason: 'Server error ${e.response?.statusCode} on upload $path',
          fatal: false,
        );
      }
      final data = e.response?.data;
      String message = 'Upload failed. Please try again.';
      if (data is Map && data['error'] != null) {
        message = data['error'].toString();
      } else if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        message = 'Could not connect. Check your internet connection.';
      }
      throw ApiException(message, statusCode: e.response?.statusCode);
    }
  }

  Future<dynamic> _request(Future<Response> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map &&
          body.containsKey('data') &&
          (body.containsKey('code') || body.containsKey('message'))) {
        return body['data'];
      }
      return body;
    } on DioException catch (e) {
      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        CrashlyticsService.instance.recordError(
          e,
          e.stackTrace,
          reason: 'Server error ${e.response?.statusCode} on ${e.requestOptions.uri}',
          fatal: false,
        );
      }
      final data = e.response?.data;
      String message = 'Something went wrong. Please try again.';
      String? code;
      if (data is Map && data['error'] != null) {
        message = data['error'].toString();
        code = data['code']?.toString();
      } else if (data is Map && data['message'] != null) {
        message = data['message'].toString();
        code = data['code']?.toString();
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        message = 'Could not connect. Check your internet connection.';
      }
      throw ApiException(message, statusCode: e.response?.statusCode, code: code);
    }
  }
}
