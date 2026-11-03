import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

class ForceUpdateScreen extends ConsumerStatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  ConsumerState<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends ConsumerState<ForceUpdateScreen> {
  bool _checking = false;

  Future<void> _refreshStatus() async {
    if (_checking) return;
    setState(() => _checking = true);
    AppHaptics.light();
    try {
      ref.invalidate(storeSettingsProvider);
      ref.invalidate(appUpdateCheckProvider);
      final result = await ref.read(appUpdateCheckProvider.future);
      if (!mounted) return;
      if (!result.isBlocked) {
        showToast('App is up to date!');
      } else {
        showToast('Update still required');
      }
    } catch (_) {
      if (mounted) showToast('Could not reach servers. Check internet.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openWhatsApp() async {
    AppHaptics.light();
    final uri = Uri.parse(
      'https://wa.me/918892055655?text=${Uri.encodeComponent('Hi KK Nutrivet support, I need help with the app.')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final updateAsync = ref.watch(appUpdateCheckProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: updateAsync.when(
            data: (result) {
              final isMaintenance = result.isMaintenance;
              final config = result.config;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: AppFadeSlide(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero Icon
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: isMaintenance
                                ? const Color(0xFFFEF3C7)
                                : AppColors.primaryWash,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMaintenance
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isMaintenance
                                ? Icons.construction_rounded
                                : Icons.system_update_rounded,
                            size: 44,
                            color: isMaintenance
                                ? const Color(0xFFD97706)
                                : AppColors.primaryDeep,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          isMaintenance
                              ? 'Scheduled Maintenance'
                              : config.forceUpdateTitle,
                          textAlign: TextAlign.center,
                          style: AppTheme.serif(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description Message
                        Text(
                          isMaintenance
                              ? config.maintenanceMessage
                              : config.forceUpdateMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Version Info Card (only for update, not maintenance)
                        if (!isMaintenance) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWashFaint,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderWarm),
                            ),
                            child: Column(
                              children: [
                                _VersionRow(
                                  label: 'Installed Version',
                                  value:
                                      'v${result.currentVersion} (Build ${result.currentBuildNumber})',
                                  isHighlight: false,
                                ),
                                const Divider(
                                  height: 18,
                                  color: AppColors.borderWarm,
                                ),
                                _VersionRow(
                                  label: 'Minimum Required',
                                  value:
                                      'v${config.minAppVersion} (Build ${config.minBuildNumber})',
                                  isHighlight: true,
                                ),
                                if (config.latestVersion !=
                                    config.minAppVersion) ...[
                                  const Divider(
                                    height: 18,
                                    color: AppColors.borderWarm,
                                  ),
                                  _VersionRow(
                                    label: 'Latest Available',
                                    value: 'v${config.latestVersion}',
                                    isHighlight: false,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Primary Action Button
                        if (!isMaintenance)
                          AppBounce(
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  AppHaptics.selection();
                                  launchPlayStore(
                                    overrideUrl: config.playStoreUrl,
                                  );
                                },
                                icon: const Icon(
                                  Icons.shop_two_rounded,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Update from Google Play',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDeep,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          AppBounce(
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _refreshStatus,
                                icon: _checking
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                                label: Text(
                                  _checking ? 'Checking…' : 'Retry Connection',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDeep,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Secondary Action
                        if (!isMaintenance)
                          TextButton.icon(
                            onPressed: _checking ? null : _refreshStatus,
                            icon: _checking
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              _checking ? 'Checking…' : 'Already updated? Check again',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Support Link
                        TextButton.icon(
                          onPressed: _openWhatsApp,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text(
                            'Need help? Chat with Support',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDeep),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Connection Issue',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshStatus,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.value,
    required this.isHighlight,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isHighlight
                ? AppColors.primaryDeep
                : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isHighlight
                ? AppColors.primaryDeep
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
