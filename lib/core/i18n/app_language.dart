import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_strings.dart';

const String kLocaleStorageKey = 'kknutrivet_locale';

/// Supported storefront languages — exact parity with `SUPPORTED_LOCALES` in
/// `kknutrivet-webapp/src/lib/i18n.ts`.
enum AppLocale {
  en(code: 'en', label: 'English', nativeLabel: 'English', shortLabel: 'EN'),
  hi(code: 'hi', label: 'Hindi', nativeLabel: 'हिंदी', shortLabel: 'हिंदी'),
  or_(code: 'or', label: 'Odia', nativeLabel: 'ଓଡ଼ିଆ', shortLabel: 'ଓଡ଼ିଆ'),
  te(code: 'te', label: 'Telugu', nativeLabel: 'తెలుగు', shortLabel: 'తెలుగు'),
  ta(code: 'ta', label: 'Tamil', nativeLabel: 'தமிழ்', shortLabel: 'தமிழ்');

  const AppLocale({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.shortLabel,
  });

  final String code;
  final String label;
  final String nativeLabel;
  final String shortLabel;

  static AppLocale fromCode(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final locale in AppLocale.values) {
      if (locale.code == normalized) return locale;
    }
    return AppLocale.en;
  }
}

class LanguageNotifier extends Notifier<AppLocale> {
  bool _hydrated = false;

  @override
  AppLocale build() {
    if (!_hydrated) {
      _hydrated = true;
      _loadSavedLocale();
    }
    return AppLocale.en;
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(kLocaleStorageKey);
      if (saved != null && saved.isNotEmpty) {
        final parsed = AppLocale.fromCode(saved);
        if (parsed != state) {
          state = parsed;
        }
      }
    } catch (_) {
      // Non-blocking fallback to English in tests or restricted environments.
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    if (state == locale) return;
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kLocaleStorageKey, locale.code);
    } catch (_) {}
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLocale>(
  LanguageNotifier.new,
);

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(languageProvider);
  return AppStrings.of(locale);
});
