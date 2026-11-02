import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/address.dart';
import '../../../models/delivery.dart';
import '../../../providers/app_providers.dart';

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) {
  return ref.read(addressServiceProvider).fetchAddresses();
});

/// Saved addresses list with collapsed/expanded selection and "Add new" button.
class CheckoutAddressSection extends ConsumerWidget {
  const CheckoutAddressSection({
    super.key,
    required this.addressesAsync,
    required this.selectedAddressId,
    required this.addressExpanded,
    required this.onSelectAddress,
    required this.onToggleExpanded,
    required this.onDefaultAddressResolved,
  });

  final AsyncValue<List<Address>> addressesAsync;
  final String? selectedAddressId;
  final bool addressExpanded;
  final ValueChanged<Address> onSelectAddress;
  final VoidCallback onToggleExpanded;
  final ValueChanged<Address> onDefaultAddressResolved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return addressesAsync.when(
      data: (addresses) {
        if (addresses.isEmpty) {
          return SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                AppHaptics.light();
                final newAddr = await context.push<Address?>('/addresses/new');
                ref.invalidate(addressesProvider);
                if (newAddr != null) {
                  onSelectAddress(newAddr);
                }
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(
                'Add a delivery address',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        }
        if (selectedAddressId == null) {
          final defaultAddr =
              addresses.where((a) => a.isDefault).firstOrNull ??
              addresses.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onDefaultAddressResolved(defaultAddr);
          });
        }
        final selected = addresses
                .where((a) => a.id == selectedAddressId)
                .firstOrNull ??
            addresses.where((a) => a.isDefault).firstOrNull ??
            addresses.first;

        return Column(
          children: [
            CheckoutAddressCard(
              address: selected,
              isSelected: true,
              onTap: () => onSelectAddress(selected),
            ),
            if (addressExpanded) ...[
              const SizedBox(height: 8),
              for (final a in addresses.where((a) => a.id != selected.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CheckoutAddressCard(
                    address: a,
                    isSelected: false,
                    onTap: () => onSelectAddress(a),
                  ),
                ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onToggleExpanded,
                    icon: Icon(
                      addressExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                    ),
                    label: Text(
                      addressExpanded
                          ? 'Hide'
                          : 'Change (${addresses.length - 1} more)',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      AppHaptics.light();
                      final newAddr =
                          await context.push<Address?>('/addresses/new');
                      ref.invalidate(addressesProvider);
                      if (newAddr != null) {
                        onSelectAddress(newAddr);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add new'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(addressesProvider),
      ),
    );
  }
}

/// Selectable card representing a saved delivery address.
class CheckoutAddressCard extends StatelessWidget {
  const CheckoutAddressCard({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final Address address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${address.formattedAddress}, ${address.city}, ${address.state} - ${address.zipCode}\n${address.phone}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pincode serviceability banner and loading indicator.
class CheckoutDeliveryStatusRow extends StatelessWidget {
  const CheckoutDeliveryStatusRow({
    super.key,
    required this.checkingDelivery,
    required this.delivery,
    required this.onOpenWaitlist,
  });

  final bool checkingDelivery;
  final DeliveryInfo? delivery;
  final ValueChanged<String> onOpenWaitlist;

  @override
  Widget build(BuildContext context) {
    if (checkingDelivery) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Checking delivery options...',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      );
    }
    final info = delivery;
    if (info == null) return const SizedBox.shrink();
    if (!info.serviceable) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "We don't deliver to this pincode yet",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
            TextButton(
              onPressed: () => onOpenWaitlist(info.pincode),
              child: const Text('Notify me'),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        const Icon(
          Icons.local_shipping_outlined,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Delivery to ${info.pincode} · ${info.etaLabel}'
            '${info.cod ? ' · COD available' : ''}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
      ],
    );
  }
}

void showCheckoutWaitlistSheet(BuildContext context, String pincode) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CheckoutWaitlistSheet(pincode: pincode),
  );
}

/// Not-deliverable waitlist sheet (POST /delivery-interest).
class CheckoutWaitlistSheet extends ConsumerStatefulWidget {
  const CheckoutWaitlistSheet({super.key, required this.pincode});
  final String pincode;

  @override
  ConsumerState<CheckoutWaitlistSheet> createState() =>
      _CheckoutWaitlistSheetState();
}

class _CheckoutWaitlistSheetState extends ConsumerState<CheckoutWaitlistSheet> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'Enter a 10-digit mobile number');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(deliveryServiceProvider).registerInterest(
            pincode: widget.pincode,
            phone: phone,
            name: _nameController.text.trim(),
          );
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        20 +
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_done) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              const Text(
                "You're on the list!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                "We'll notify you when delivery opens for ${widget.pincode}.",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ] else ...[
              Text(
                'Delivery coming soon to ${widget.pincode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Leave your number and we\u2019ll notify you the moment we can deliver.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Name'),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  hintText: '10-digit mobile number',
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 13),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Notify me'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
