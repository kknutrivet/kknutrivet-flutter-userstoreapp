import 'package:flutter/material.dart';

/// Centralized Corner Radius tokens extracted from `src/app/globals.css`.
class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 8.0; // --radius-chip (chips, badges, small inputs)
  static const double md = 10.0; // --radius-control (buttons, inputs)
  static const double card = 14.0; // --radius-card (cards, panels)
  static const double lg = 16.0;
  static const double modal = 18.0; // --radius-modal (sheets, bottom nav)
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double pill = 9999.0; // --radius-pill

  // Pre-built BorderRadius helpers
  static final BorderRadius radiusSm = BorderRadius.circular(sm);
  static final BorderRadius radiusMd = BorderRadius.circular(md);
  static final BorderRadius radiusCard = BorderRadius.circular(card);
  static final BorderRadius radiusLg = BorderRadius.circular(lg);
  static final BorderRadius radiusModal = BorderRadius.circular(modal);
  static final BorderRadius radiusXl = BorderRadius.circular(xl);
  static final BorderRadius radiusXxl = BorderRadius.circular(xxl);
  static final BorderRadius radiusPill = BorderRadius.circular(pill);
}
