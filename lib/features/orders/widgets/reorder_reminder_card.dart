import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

/// 30-day Reorder Reminder opt-in card mirroring `ReorderReminderCard.tsx`
/// (5% off non-feed via REFILL5, or +25 KK Coins for feed orders).
class ReorderReminderCard extends ConsumerStatefulWidget {
  const ReorderReminderCard({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ReorderReminderCard> createState() =>
      _ReorderReminderCardState();
}

class _ReorderReminderCardState extends ConsumerState<ReorderReminderCard> {
  bool _loading = true;
  bool _saving = false;
  bool _optedIn = false;
  String _rewardType = 'percent_5';
  int _bonusCoins = 25;
  String? _couponCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await ref
          .read(orderServiceProvider)
          .fetchReorderReminder(widget.orderId);
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      if (!mounted) return;
      setState(() {
        _optedIn = data['optedIn'] == true;
        _rewardType = data['rewardType']?.toString() ?? 'percent_5';
        _bonusCoins = (data['bonusCoins'] as num?)?.toInt() ?? 25;
        _couponCode = data['couponCode']?.toString();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    if (_saving) return;
    final next = !_optedIn;
    setState(() => _saving = true);
    try {
      await ref
          .read(orderServiceProvider)
          .setReorderReminder(widget.orderId, enabled: next);
      Haptics.selection();
      if (!mounted) return;
      setState(() => _optedIn = next);
      showToast(
        next
            ? '30-day refill reminder enabled!'
            : 'Refill reminder turned off.',
      );
    } catch (_) {
      showToast('Could not update reminder right now.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final perkText = _rewardType == 'bonus_coins'
        ? 'Get +$_bonusCoins KK Coins when you refill in 30 days'
        : 'Get 5% OFF (${_couponCode ?? 'REFILL5'}) on your 30-day refill';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _optedIn ? AppColors.primaryWashFaint : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _optedIn ? AppColors.primaryDeep : AppColors.primaryWashDeep,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryWash,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _optedIn
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.primaryDeep,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '30-Day Refill Reminder',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perkText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _saving ? null : _toggle,
            style: FilledButton.styleFrom(
              backgroundColor: _optedIn
                  ? AppColors.primaryDeep
                  : const Color(0xFF07583F),
              minimumSize: const Size(74, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _optedIn ? 'Active ✓' : 'Remind me',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
