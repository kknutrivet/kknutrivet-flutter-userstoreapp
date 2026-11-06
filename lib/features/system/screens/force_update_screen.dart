import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot_world_scene.dart';
import '../../../providers/app_providers.dart';
import '../../help/screens/help_screen.dart';

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
        showToast(
          result.isMaintenance
              ? 'Maintenance is still in progress.'
              : 'Update still required',
        );
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
      'https://wa.me/${HelpScreen.helpPhone}?text=${Uri.encodeComponent('Hi KK Nutrivet support, I need help with the app.')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final updateAsync = ref.watch(appUpdateCheckProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: updateAsync.when(
          data: (result) {
            final isMaintenance = result.isMaintenance;
            final config = result.config;

            return MascotWorldScene(
              mascotHeight: 80,
              showGroundShadow: false,
              centerWidget: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 68,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  errorBuilder: (_, _, _) => const Text(
                    'KK NUTRIVET',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ),
              topBadge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMaintenance
                          ? Icons.healing_rounded
                          : Icons.system_update_rounded,
                      size: 14,
                      color: isMaintenance
                          ? const Color(0xFFFDE047)
                          : const Color(0xFF86EFAC),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isMaintenance
                          ? 'SERVICE UPGRADE IN PROGRESS'
                          : 'NEW VERSION AVAILABLE',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              bottomContent: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      isMaintenance
                          ? 'Scheduled Maintenance'
                          : config.forceUpdateTitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.serif(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description Message
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Text(
                        isMaintenance
                            ? config.maintenanceMessage
                            : config.forceUpdateMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Version Info Card (only for update)
                    if (!isMaintenance) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
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
                              height: 14,
                              color: Colors.white24,
                            ),
                            _VersionRow(
                              label: 'Minimum Required',
                              value:
                                  'v${config.minAppVersion} (Build ${config.minBuildNumber})',
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Action Buttons (High Contrast White Pill Buttons)
                    if (!isMaintenance)
                      AppBounce(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppHaptics.selection();
                              launchPlayStore(
                                overrideUrl: config.playStoreUrl,
                              );
                            },
                            icon: const Icon(
                              Icons.shop_two_rounded,
                              size: 19,
                              color: Color(0xFF075B43),
                            ),
                            label: const Text(
                              'Update from Google Play',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF075B43),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      AppBounce(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _checking ? null : _refreshStatus,
                            icon: _checking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF075B43),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh_rounded,
                                    color: Color(0xFF075B43),
                                  ),
                            label: Text(
                              _checking ? 'Checking…' : 'Retry Connection',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF075B43),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),

                    // WhatsApp Support Action
                    TextButton.icon(
                      onPressed: _openWhatsApp,
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Need urgent care? Chat on WhatsApp',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
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
                    onPressed: _checking ? null : _refreshStatus,
                    child: const Text('Try Again'),
                  ),
                ],
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
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isHighlight
                  ? const Color(0xFF86EFAC)
                  : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
