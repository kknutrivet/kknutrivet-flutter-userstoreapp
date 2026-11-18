import 'package:material_ui/material_ui.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../theme/app_theme.dart';
import '../utils/haptics.dart';

/// Global scaffold messenger key wired into [KkNutrivetApp] so [showToast]
/// can display styled floating in-app toasts from anywhere without needing a
/// [BuildContext].
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Visual severity for [AppToast] / [showToast].
enum AppToastType { success, error, warning, info }

/// Displays a sleek floating toast with semantic icon, color, and haptics.
///
/// Keeps the signature `showToast(message, {isError = false})` backwards-compatible
/// with all existing call sites while supporting richer [type], [title], and
/// [context] options.
void showToast(
  String message, {
  bool isError = false,
  AppToastType? type,
  String? title,
  String? actionLabel,
  VoidCallback? onAction,
  BuildContext? context,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  final resolvedType =
      type ?? (isError ? AppToastType.error : AppToastType.success);

  switch (resolvedType) {
    case AppToastType.success:
      AppHaptics.success();
    case AppToastType.error:
      AppHaptics.error();
    case AppToastType.warning:
      AppHaptics.light();
    case AppToastType.info:
      AppHaptics.tap();
  }

  final messenger = context != null
      ? ScaffoldMessenger.maybeOf(context)
      : appScaffoldMessengerKey.currentState;

  if (messenger != null && messenger.mounted) {
    messenger
      ..removeCurrentSnackBar()
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          content: AppToastCard(
            message: message,
            title: title,
            type: resolvedType,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
            onDismiss: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );
    return;
  }

  // Fallback for isolated calls without a mounted ScaffoldMessenger.
  try {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: resolvedType == AppToastType.error
          ? AppColors.error
          : AppColors.primaryDark,
      textColor: Colors.white,
    );
  } catch (_) {
    // Ignore platform-channel absence in pure unit tests.
  }
}

/// Styled floating toast surface with icon badge, message, and dismiss action.
class AppToastCard extends StatelessWidget {
  const AppToastCard({
    super.key,
    required this.message,
    required this.type,
    this.title,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String message;
  final AppToastType type;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final (
      Color bg,
      Color border,
      Color iconBg,
      IconData icon,
    ) = switch (type) {
      AppToastType.success => (
        AppColors.primaryDeepest,
        AppColors.primary,
        AppColors.primary,
        Icons.check_circle_rounded,
      ),
      AppToastType.error => (
        const Color(0xFF7F1D1D),
        AppColors.error,
        AppColors.error,
        Icons.error_rounded,
      ),
      AppToastType.warning => (
        const Color(0xFF78350F),
        AppColors.warning,
        AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      AppToastType.info => (
        const Color(0xFF0C4A6E),
        AppColors.info,
        AppColors.info,
        Icons.info_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border.withValues(alpha: 0.45), width: 1),
        boxShadow: AppShadows.lifted,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.trim().isNotEmpty) ...[
                  Text(
                    title!,
                    style: AppTheme.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.sans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.96),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
