import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized Firebase Crashlytics service for Flutter crash and error reporting.
///
/// Captures:
/// 1. Uncaught Flutter framework errors (`FlutterError.onError`)
/// 2. Uncaught asynchronous errors (`PlatformDispatcher.instance.onError`)
/// 3. Non-fatal caught errors (`recordError`)
/// 4. User identity and custom breadcrumbs (`setUserId`, `setCustomKey`, `log`)
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  FirebaseCrashlytics? get _crashlytics {
    if (!_initialized || Firebase.apps.isEmpty) return null;
    try {
      return FirebaseCrashlytics.instance;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Crashlytics error handlers. Must be called after
  /// Firebase has initialized.
  Future<void> init({
    required bool firebaseAvailable,
    bool enableInDebug = true,
  }) async {
    if (!firebaseAvailable || Firebase.apps.isEmpty) {
      debugPrint('[Crashlytics] Firebase not available, skipping Crashlytics setup.');
      return;
    }
    try {
      final crashlytics = FirebaseCrashlytics.instance;

      // Crashlytics collection is enabled by default. In debug mode,
      // enableInDebug controls whether collection is active.
      final shouldEnable = !kDebugMode || enableInDebug;
      await crashlytics.setCrashlyticsCollectionEnabled(shouldEnable);

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        crashlytics.recordFlutterFatalError(details);
        originalOnError?.call(details);
      };

      // Pass all uncaught asynchronous errors that aren't handled by Flutter to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      _initialized = true;
      debugPrint('[Crashlytics] Initialized successfully (collection: $shouldEnable)');
    } catch (e, st) {
      debugPrint('[Crashlytics] Failed to initialize Crashlytics: $e\n$st');
    }
  }

  /// Record a caught non-fatal exception
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
    bool? printDetails,
  }) async {
    try {
      await _crashlytics?.recordError(
        exception,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
        printDetails: printDetails,
      );
    } catch (_) {}
  }

  /// Add custom log message to the crash report
  Future<void> log(String message) async {
    try {
      await _crashlytics?.log(message);
    } catch (_) {}
  }

  /// Associate user identifier with crash reports
  Future<void> setUserId(String? userId) async {
    try {
      if (userId != null && userId.isNotEmpty) {
        await _crashlytics?.setUserIdentifier(userId);
      }
    } catch (_) {}
  }

  /// Set custom key-value pairs to annotate crash reports
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (_) {}
  }
}
