import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared mobile typography. The legacy serif helper uses the same sans family
/// so headings and controls remain consistent across screens.
class AppTypography {
  AppTypography._();

  /// Display font for headings, hero & section titles (matches `--font-serif` in `globals.css`).
  static TextStyle serif({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height ?? 1.2,
    letterSpacing: letterSpacing ?? -0.25,
  );

  /// Clean body font for body copy, titles, labels, chips, and buttons.
  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height ?? 1.45,
    letterSpacing: letterSpacing ?? -0.1,
  );

  // Type Scale Constants (matching CSS --text-* tokens)
  static const double textMicro = 11.0; // --text-micro
  static const double textCaption = 12.0; // --text-caption
  static const double textLabel = 13.0; // --text-label
  static const double textBody = 15.0; // --text-body
  static const double textBodyLg = 17.0; // --text-body-lg
  static const double textTitle = 20.0; // --text-title
  static const double textHeadline = 25.0; // --text-headline
  static const double textDisplay = 32.0; // --text-display

  // Quick text style presets
  static TextStyle get display => serif(
    fontSize: textDisplay,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.6,
  );
  static TextStyle get headline => serif(
    fontSize: textHeadline,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static TextStyle get title => serif(
    fontSize: textTitle,
    fontWeight: FontWeight.w700,
    height: 1.28,
    letterSpacing: -0.25,
  );
  static TextStyle get bodyLg => sans(
    fontSize: textBodyLg,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: -0.15,
  );
  static TextStyle get body => sans(
    fontSize: textBody,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.1,
  );
  static TextStyle get label => sans(
    fontSize: textLabel,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.1,
  );
  static TextStyle get caption => sans(
    fontSize: textCaption,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: 0.0,
  );
  static TextStyle get micro => sans(
    fontSize: textMicro,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.15,
  );
  static TextStyle get price => sans(
    fontSize: 16.0,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryDeep,
    letterSpacing: -0.3,
  );
  static TextStyle get mrp => sans(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.mrp,
    letterSpacing: -0.1,
  );
}
