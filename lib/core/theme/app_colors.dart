import 'package:flutter/material.dart';

/// Centralized KK Nutrivet mobile design tokens extracted directly from
/// the Next.js website (`src/app/globals.css`).
///
/// Single Source of Truth: https://kknutrivet.in
class AppColors {
  AppColors._();

  // Core Brand Colors
  static const brandPrimary = Color(0xFF126B50); // --brand-primary
  static const primary = Color(0xFF16845F); // --color-green-600
  static const primaryDark = Color(0xFF126B50); // --color-green-700
  static const primaryDeep = Color(0xFF07583F); // --color-primary-deep (Website CTA & Consult)
  static const primaryDeepest = Color(0xFF17322B); // --color-green-900 / --color-text

  // Background & Surfaces
  static const background = Color(0xFFF3F6F5); // --color-bg
  static const homeCanvas = Color(0xFFFFFCF8); // --color-home-canvas (Mobile Homepage)
  static const homeBackground = Color(0xFFFFFCF8);
  static const homeHero = Color(0xFFFFF9F5); // --color-home-hero
  static const warmCream = Color(0xFFFFF9F1); // --color-cream
  static const creamDeep = Color(0xFFEEE7DC); // --color-cream-deep
  static const surface = Colors.white; // --color-bg-elevated
  static const surfaceAlt = Color(0xFFFCFCFB); // --color-surface
  static const surfaceWarm = Color(0xFFFFF7EE); // --color-surface-warm
  static const white = Color(0xFFFFFFFF);

  // Typography
  static const textPrimary = Color(0xFF17322B); // --color-text
  static const textSecondary = Color(0xFF5A615F); // --color-text-secondary
  static const textTertiary = Color(0xFF5F6866); // --color-text-tertiary
  static const mrp = Color(0xFF5F6866);

  // Borders & Dividers
  static const border = Color(0xFFDDE3E0); // --color-border
  static const borderWarm = Color(0xFFE7E1D8); // --color-border-warm
  static const borderWarmSoft = Color(0xFFE7DED2); // --color-border-warm-soft
  static const borderStrong = Color(0xFFD1D6D4); // --color-border-strong
  static const borderSubtle = Color(0xFFEAF0EC);
  static const cardBorder = Color(0xFFDDE3E0);
  static const cardBorderSubtle = Color(0xFFEFF3F1);

  // Wash Tones (subtle tints for cards, chips, and backgrounds)
  static const primaryWash = Color(0xFFE6F1EA); // --color-primary-wash
  static const primaryWashFaint = Color(0xFFF2F7F4); // --color-primary-wash-faint
  static const primaryWashDeep = Color(0xFFC7E7D8); // --color-primary-wash-deep

  // Accent Colors
  static const accentAmber = Color(0xFFC4933C); // --color-accent-amber
  static const accentCoral = Color(0xFFB9412E); // --color-accent-coral (Hero CTA & Discount)
  static const accentCoralDeep = Color(0xFFC1462E); // --color-accent-coral-deep
  static const accentTeal = Color(0xFF237E73); // --color-accent-teal
  static const accentTealSoft = Color(0xFFDEEEEC); // --color-accent-teal-soft
  static const accentViolet = Color(0xFF6954A2); // --color-accent-violet (Dr. Paw AI surfaces)
  static const accent = Color(0xFFB9412E);
  static const accentGradientEnd = Color(0xFFFF9A40);

  // Functional Status
  static const success = Color(0xFF15803D); // --color-success
  static const successBg = Color(0xFFDCFCE7); // --color-success-bg
  static const warning = Color(0xFFB45309); // --color-warning
  static const warningBg = Color(0xFFFEF9E6); // --color-warning-bg
  static const warningBorder = Color(0xFFFDE68A);
  static const error = Color(0xFFB91C1C); // --color-danger
  static const errorBg = Color(0xFFFEE2E2); // --color-danger-bg
  static const info = Color(0xFF0284C7); // --color-info
  static const infoBg = Color(0xFFE0F2FE); // --color-info-bg
  static const infoDeep = Color(0xFF075985); // --color-info-deep

  // KK Coins & Rewards
  static const coinsBg = Color(0xFFFFF9EB);
  static const coinsBorder = Color(0xFFFDE68A);
  static const coinsIcon = Color(0xFFB45309);

  // Rx Prescription badge tokens
  static const rxBg = Color(0xFFEBF3FB);
  static const rxText = Color(0xFF1E5B99);
  static const rxBorder = Color(0xFFCCE0F5);

  // Catalogue & Shadows
  static const catalogueGreen = Color(0xFF16845F);
  static const catalogueGreenDark = Color(0xFF07583F);

  // Restrained, soft ambient shadows
  static const cardShadow = Color(0x0A000000);
  static const cardShadowLifted = Color(0x14102F27);

  // Pastel wash tokens for sections
  static const homePeach = Color(0xFFFFE9DC);
  static const homePeachInk = Color(0xFFC1462E);
  static const homeLavender = Color(0xFFEDE6FF);
  static const homeLavenderInk = Color(0xFF5B44A6);
  static const homeMintInk = Color(0xFF07583F);
  static const homeSoftYellow = Color(0xFFFFF7EE);
  static const homeYellowInk = Color(0xFF7A4A10);
  static const coralSoft = Color(0xFFFFB98F);
  static const peachWash = Color(0xFFFFF4E8);

  // Interactive buttons & heart
  static const favoriteRed = Color(0xFFE0245E);
  static const favoriteHeartInactive = Color(0xFF7A8882);
  static const stepperBorder = Color(0xFF8EBDAA);
  static const stepperBorderActive = Color(0xFF07583F);
  static const stepperBgActive = Color(0xFFE6F1EA);
  static const stepperBg = Color(0xFFF8FAF8);
  static const cartBarBadgeBg = Color(0x33FFFFFF);
  static const whatsAppGreen = Color(0xFF25D366);
  static const starGold = Color(0xFFFAB400);

  // Shimmer skeleton tokens
  static const shimmerBase = Color(0xFFEEF2EF);
  static const shimmerHighlight = Color(0xFFF8FAF8);
  static const shimmerBorder = Color(0xFFE4ECE7);

  // Animal category rails (exact match with `src/lib/animal-category-images.ts`)
  static const featuredRailBg = Color(0xFFFFFDF6);
  static const featuredRailBorder = Color(0xFFF1E7D4);
  static const featuredRailHeading = Color(0xFF362610);
  static const featuredRailSubtitle = Color(0xFF6B583E);
  static const featuredRailAccent = Color(0xFFC47A12);
  static const featuredTone = Color(0xFFFFE8BD);

  static const homeCareRailBg = Color(0xFFF1F7F4);
  static const homeCareRailBorder = Color(0xFFD5E7DD);
  static const homeCareRailHeading = Color(0xFF154D38);
  static const homeCareRailSubtitle = Color(0xFF446C5B);
  static const homeCareRailAccent = Color(0xFF1A5C43);
  static const homeCareTone = Color(0xFFBFE3D1);

  static const shotsRailBg = Color(0xFFF1F8F5);
  static const shotsRailBorder = Color(0xFFDCEAE2);
  static const shotsRailHeading = Color(0xFF134B38);
  static const shotsRailSubtitle = Color(0xFF486E5D);
  static const shotsRailAccent = Color(0xFF087E58);
  static const shotsTone = Color(0xFFD8EFE3);

  static const dogRailBg = Color(0xFFFFF6E4);
  static const dogRailBorder = Color(0xFFF0D7A4);
  static const dogRailHeading = Color(0xFF7A4A10);
  static const dogRailSubtitle = Color(0xFF8D6840);
  static const dogRailAccent = Color(0xFFC47A12);
  static const dogTone = Color(0xFFFFDFA6);

  static const catRailBg = Color(0xFFF4EFFC);
  static const catRailBorder = Color(0xFFD9CEF3);
  static const catRailHeading = Color(0xFF4E3488);
  static const catRailSubtitle = Color(0xFF6B5A8C);
  static const catRailAccent = Color(0xFF6B4BB5);
  static const catTone = Color(0xFFD8CCF7);

  static const cattleRailBg = Color(0xFFFBEDE3);
  static const cattleRailBorder = Color(0xFFEFC8A8);
  static const cattleRailHeading = Color(0xFF7A3D22);
  static const cattleRailSubtitle = Color(0xFF8A5A44);
  static const cattleRailAccent = Color(0xFFC45C2A);
  static const cattleTone = Color(0xFFF2C4A2);

  static const goatRailBg = Color(0xFFF3F4E2);
  static const goatRailBorder = Color(0xFFD4D6A6);
  static const goatRailHeading = Color(0xFF4F5420);
  static const goatRailSubtitle = Color(0xFF6A6C48);
  static const goatRailAccent = Color(0xFF6B6E2E);
  static const goatTone = Color(0xFFDFE0B0);

  static const poultryRailBg = Color(0xFFFFF0ED);
  static const poultryRailBorder = Color(0xFFF5C6BE);
  static const poultryRailHeading = Color(0xFF8F2F2A);
  static const poultryRailSubtitle = Color(0xFF9A5652);
  static const poultryRailAccent = Color(0xFFC24A40);
  static const poultryTone = Color(0xFFFFC6BE);

  static const exoticRailBg = Color(0xFFE7F6EF);
  static const exoticRailBorder = Color(0xFFB4DFCB);
  static const exoticRailHeading = Color(0xFF0E5A41);
  static const exoticRailSubtitle = Color(0xFF3D6F5C);
  static const exoticRailAccent = Color(0xFF0F7A56);
  static const exoticTone = Color(0xFFB6E2CF);

  // Order status tokens
  static const orderPending = Color(0xFF92700A);
  static const orderPendingBg = Color(0xFFFEF9E7);
  static const orderConfirmed = Color(0xFF1D4ED8);
  static const orderConfirmedBg = Color(0xFFEFF6FF);
  static const orderPacked = Color(0xFF4338CA);
  static const orderPackedBg = Color(0xFFEEF2FF);
  static const orderShipped = Color(0xFF7E22CE);
  static const orderShippedBg = Color(0xFFFAF5FF);
  static const orderOutForDelivery = Color(0xFF92610A);
  static const orderOutForDeliveryBg = Color(0xFFFFFBEB);
  static const orderDelivered = Color(0xFF15803D);
  static const orderDeliveredBg = Color(0xFFF0FDF4);
  static const orderReturned = Color(0xFF9A3412);
  static const orderReturnedBg = Color(0xFFFFF7ED);
  static const orderCancelled = Color(0xFFB91C1C);
  static const orderCancelledBg = Color(0xFFFEF2F2);

  // Footer tokens
  static const footerBg = Color(0xFF1A221E);
  static const footerText = Color(0xFF99A6A0);
  static const footerMuted = Color(0xFFA5B2AC);
}
