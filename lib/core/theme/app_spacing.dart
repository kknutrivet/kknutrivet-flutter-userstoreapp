/// Centralized Spacing tokens extracted from `src/app/globals.css`.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0; // --spacing-stack (gap between items inside card)
  static const double lg = 16.0; // --spacing-gutter (standard card padding)
  static const double xl = 20.0; // --spacing-gutter-lg (roomier cards, modals)
  static const double xxl = 24.0;
  static const double xxxl = 32.0; // --spacing-section (gap between page sections)

  // Semantic Aliases from CSS
  static const double stack = md; // 12px
  static const double gutter = lg; // 16px
  static const double gutterLg = xl; // 20px
  static const double section = xxxl; // 32px
}
