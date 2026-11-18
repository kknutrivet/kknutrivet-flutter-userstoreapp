import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Emits `true` when the device has no active network interface (`ConnectivityResult.none`).
/// Falls back to `false` (online) when platform channels are unavailable (e.g. widget tests).
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  try {
    final initial = await connectivity.checkConnectivity();
    yield _isDisconnected(initial);
    await for (final results in connectivity.onConnectivityChanged) {
      yield _isDisconnected(results);
    }
  } on MissingPluginException {
    yield false;
  } catch (_) {
    yield false;
  }
});

bool _isDisconnected(List<ConnectivityResult> results) {
  if (results.isEmpty) return true;
  return results.every((r) => r == ConnectivityResult.none);
}

/// Wraps the root navigator child and shows a subtle floating offline pill
/// whenever [isOfflineProvider] emits `true`.
class OfflineBannerWrapper extends ConsumerWidget {
  const OfflineBannerWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider).valueOrNull ?? false;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 16,
          right: 16,
          child: IgnorePointer(
            ignoring: !isOffline,
            child: SafeArea(
              bottom: false,
              child: AnimatedSlide(
                offset: isOffline ? Offset.zero : const Offset(0, -1.4),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: isOffline ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Center(child: _OfflineStatusPill()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineStatusPill extends StatelessWidget {
  const _OfflineStatusPill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.45),
          ),
          boxShadow: AppShadows.lifted,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 15,
              color: Color(0xFFFBBF24),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'No internet — showing cached data',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Branded fallback card used by [ErrorWidget.builder] when a widget throws
/// during build in release mode.
class AppErrorFallbackCard extends StatelessWidget {
  const AppErrorFallbackCard({super.key, this.details});

  final FlutterErrorDetails? details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.homeCanvas,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderWarm),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Something went wrong',
                  textAlign: TextAlign.center,
                  style: AppTheme.serif(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kDebugMode && details != null
                      ? details!.exceptionAsString()
                      : 'We hit an unexpected display issue. Please pull to refresh or try again.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
