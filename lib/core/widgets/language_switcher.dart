import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../i18n/app_language.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Compact language selector pill matching `LanguageSwitcher` on the mobile
/// website (`EN / हिंदी / ଓଡ଼ିଆ / తెలుగు / தமிழ்`).
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    return Semantics(
      button: true,
      label: 'Language: ${current.label}',
      child: Material(
        color: Colors.white.withValues(alpha: 0.95),
        shape: StadiumBorder(
          side: BorderSide(
            color: AppColors.primaryDeep.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () {
            Haptics.tap();
            showLanguagePickerSheet(context, ref);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 11,
              vertical: compact ? 6 : 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 14,
                  color: AppColors.primaryDeep,
                ),
                const SizedBox(width: 4),
                Text(
                  compact ? current.shortLabel : current.nativeLabel,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDeep,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet allowing the user to pick any of the 5 supported languages.
Future<void> showLanguagePickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return Consumer(
        builder: (context, ref, _) {
          final active = ref.watch(languageProvider);
          final strings = ref.watch(appStringsProvider);
          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 20,
                        color: AppColors.primaryDeep,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        strings.selectLanguage,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final locale in AppLocale.values) ...[
                    Material(
                      color: active == locale
                          ? AppColors.primaryWashFaint
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          Haptics.selection();
                          await ref
                              .read(languageProvider.notifier)
                              .setLocale(locale);
                          if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active == locale
                                  ? AppColors.primaryDeep
                                  : AppColors.border,
                              width: active == locale ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.nativeLabel,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: active == locale
                                            ? AppColors.primaryDeep
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      locale.label,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (active == locale)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: AppColors.primaryDeep,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
