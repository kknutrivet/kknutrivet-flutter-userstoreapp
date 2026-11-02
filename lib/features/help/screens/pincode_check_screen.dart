import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/delivery.dart';
import '../../../providers/app_providers.dart';

class PincodeCheckScreen extends ConsumerStatefulWidget {
  const PincodeCheckScreen({super.key});

  @override
  ConsumerState<PincodeCheckScreen> createState() =>
      _PincodeCheckScreenState();
}

class _PincodeCheckScreenState extends ConsumerState<PincodeCheckScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  DeliveryInfo? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final code = _controller.text.trim();
    if (code.length != 6) {
      showToast('Please enter a 6-digit pincode', isError: true);
      return;
    }
    AppHaptics.light();
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final info =
          await ref.read(deliveryServiceProvider).checkPincode(code);
      if (!mounted) return;
      setState(() => _result = info);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Check Delivery Speed',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          AppCard(
            variant: AppCardVariant.tinted,
            backgroundColor: AppColors.primaryWash,
            borderColor: AppColors.primaryWashDeep,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primaryDeep,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Enter your 6-digit pincode to check estimated dispatch time, Cash on Delivery availability, and courier serviceability.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            variant: AppCardVariant.elevated,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '6-digit Pincode',
                    hintText: 'e.g. 760001, 751024',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _check(),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Check Pincode',
                  icon: const Icon(Icons.search_rounded, size: 16),
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.md,
                  fullWidth: true,
                  isLoading: _loading,
                  onPressed: _loading ? null : _check,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            AppCard(
              variant: AppCardVariant.tinted,
              backgroundColor: AppColors.errorBg,
              borderColor: AppColors.error.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          if (_result != null) _resultCard(_result!),
          const SizedBox(height: 36),
        ],
      ),
    ),
  );
  }

  Widget _resultCard(DeliveryInfo info) {
    final ok = info.serviceable;
    final tone = ok ? AppBadgeTone.emerald : AppBadgeTone.coral;

    return AppCard(
      variant: AppCardVariant.elevated,
      borderColor: ok ? AppColors.primaryDeep : AppColors.error,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge(
                label: ok ? 'SERVICEABLE' : 'UNAVAILABLE',
                tone: tone,
              ),
              const Spacer(),
              Text(
                'Pincode: ${info.pincode}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ok
                ? 'Delivery available to ${info.city ?? 'your area'}'
                : 'Delivery currently unavailable to ${info.pincode}',
            style: AppTheme.serif(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ok ? AppColors.primaryDeep : AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          if (ok) ...[
            _infoRow(Icons.schedule_rounded, 'Estimated dispatch: ${info.etaLabel}'),
            const SizedBox(height: 6),
            _infoRow(
              info.cod ? Icons.payments_outlined : Icons.credit_card_outlined,
              info.cod
                  ? 'Cash on Delivery (COD) available'
                  : 'Prepaid / Online payment only',
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primaryDeep),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
