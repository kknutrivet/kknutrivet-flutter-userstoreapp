import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Centralized haptic feedback controller adhering to native interaction standards.
///
/// On Android, Flutter's [HapticFeedback] maps to `View.performHapticFeedback`
/// (CLOCK_TICK / VIRTUAL_KEY), which many OEM devices ignore or which is
/// suppressed when system "Touch feedback" is off. So on Android we call the
/// native Vibrator via a platform channel (see MainActivity.kt) and fall back
/// to [HapticFeedback] if the channel is unavailable. iOS uses the Taptic
/// Engine through [HapticFeedback] directly.
class AppHaptics {
  AppHaptics._();

  static const MethodChannel _channel =
      MethodChannel('com.kknutrivet.shop/haptics');

  static bool get _useNative =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static void _fire(String type, Future<void> Function() fallback) {
    if (_useNative) {
      _channel.invokeMethod<bool>(type).then((ok) {
        if (ok != true) fallback();
      }).catchError((Object _) {
        fallback();
      });
    } else {
      fallback();
    }
  }

  /// Subtle click — tabs, segment controls, dropdowns, radio buttons.
  static void selection() =>
      _fire('selection', HapticFeedback.selectionClick);

  /// Light impact — standard button tap, icon click, pill press.
  static void tap() => _fire('light', HapticFeedback.lightImpact);
  static void light() => _fire('light', HapticFeedback.lightImpact);

  /// Medium tactile click — quantity stepper (+ / -), add to cart, toggle wishlist.
  static void step() => _fire('medium', HapticFeedback.mediumImpact);
  static void cart() => _fire('medium', HapticFeedback.mediumImpact);

  /// Confirmed success — order placed, Rx submitted, address saved.
  static void success() => _fire('success', HapticFeedback.mediumImpact);

  /// Warning or error — validation failed, network error, out-of-stock.
  static void error() => _fire('heavy', HapticFeedback.heavyImpact);
  static void warn() => _fire('medium', HapticFeedback.mediumImpact);
}

/// Convenience alias
typedef Haptics = AppHaptics;
