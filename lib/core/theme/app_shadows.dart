import 'package:flutter/material.dart';

/// Centralized BoxShadow tokens extracted from `src/app/globals.css`.
class AppShadows {
  AppShadows._();

  /// --shadow-soft: 0 1px 2px rgba(0, 0, 0, 0.03)
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> subtle = soft;

  /// Standard card elevation
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// --shadow-lifted: 0 8px 22px rgba(16, 47, 39, 0.08)
  static const List<BoxShadow> lifted = [
    BoxShadow(
      color: Color(0x14102F27),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];

  /// Mobile Bottom Nav Bar shadow: shadow-[0_-6px_20px_rgba(23,60,50,0.10)]
  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x1A173C32),
      blurRadius: 20,
      offset: Offset(0, -6),
    ),
  ];

  /// Raised Center Button shadow: shadow-[0_10px_22px_rgba(7,88,63,.32)]
  static const List<BoxShadow> raisedButton = [
    BoxShadow(
      color: Color(0x5207583F),
      blurRadius: 22,
      offset: Offset(0, 10),
    ),
  ];
}
