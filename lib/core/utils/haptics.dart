import 'package:flutter/services.dart';

/// Centralized haptic feedback controller adhering to native interaction standards.
class AppHaptics {
  AppHaptics._();

  /// Subtle click — tabs, segment controls, dropdowns, radio buttons.
  static void selection() => HapticFeedback.selectionClick();

  /// Light impact — standard button tap, icon click, pill press.
  static void tap() => HapticFeedback.lightImpact();
  static void light() => HapticFeedback.lightImpact();

  /// Medium tactile click — quantity stepper (+ / -), add to cart, toggle wishlist.
  static void step() => HapticFeedback.mediumImpact();
  static void cart() => HapticFeedback.mediumImpact();

  /// Confirmed success — order placed, Rx submitted, address saved.
  static void success() => HapticFeedback.mediumImpact();

  /// Warning or error — validation failed, network error, out-of-stock.
  static void error() => HapticFeedback.heavyImpact();
  static void warn() => HapticFeedback.mediumImpact();
}

/// Convenience alias
typedef Haptics = AppHaptics;
