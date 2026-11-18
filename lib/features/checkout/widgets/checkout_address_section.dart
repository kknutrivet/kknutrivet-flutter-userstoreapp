import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/address.dart';
import '../../../models/delivery.dart';
import '../../../providers/app_providers.dart';

export '../../../providers/app_providers.dart' show addressesProvider;

/// Modal bottom sheet showing saved delivery addresses with tap-to-select and "Add new".
void showCheckoutAddressPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<Address> addresses,
  required String? selectedAddressId,
  required ValueChanged<Address> onSelectAddress,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.78;
      return Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryWash,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select delivery address',
                            style: AppTheme.serif(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose a saved address (${addresses.length} saved)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close address picker',
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    for (final a in addresses) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CheckoutAddressCard(
                          address: a,
                          isSelected: a.id == selectedAddressId,
                          onTap: () {
                            AppHaptics.selection();
                            onSelectAddress(a);
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDeep,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      AppHaptics.light();
                      final newAddr =
                          await context.push<Address?>('/addresses/new');
                      ref.invalidate(addressesProvider);
                      if (newAddr != null) {
                        onSelectAddress(newAddr);
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Add new address',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

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
        final activePincode =
            ref.watch(deliveryPincodeProvider).valueOrNull?.trim();
        final matchingPinAddr =
            (activePincode != null && activePincode.isNotEmpty)
                ? (addresses
                        .where(
                          (a) =>
                              a.isDefault && a.zipCode.trim() == activePincode,
                        )
                        .firstOrNull ??
                    addresses
                        .where((a) => a.zipCode.trim() == activePincode)
                        .firstOrNull)
                : null;
        if (selectedAddressId == null) {
          final defaultAddr = matchingPinAddr ??
              addresses.where((a) => a.isDefault).firstOrNull ??
              addresses.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onDefaultAddressResolved(defaultAddr);
          });
        }
        final selected = addresses
                .where((a) => a.id == selectedAddressId)
                .firstOrNull ??
            matchingPinAddr ??
            addresses.where((a) => a.isDefault).firstOrNull ??
            addresses.first;

        return Column(
          children: [
            CheckoutAddressCard(
              address: selected,
              isSelected: true,
              onTap: () {
                if (addresses.length > 1) {
                  AppHaptics.tap();
                  showCheckoutAddressPickerSheet(
                    context: context,
                    ref: ref,
                    addresses: addresses,
                    selectedAddressId: selected.id,
                    onSelectAddress: onSelectAddress,
                  );
                } else {
                  onSelectAddress(selected);
                }
              },
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
              child: Wrap(
                spacing: 8,
                children: [
                  if (addresses.length > 1)
                    TextButton.icon(
                      onPressed: () {
                        AppHaptics.tap();
                        onToggleExpanded();
                        showCheckoutAddressPickerSheet(
                          context: context,
                          ref: ref,
                          addresses: addresses,
                          selectedAddressId: selected.id,
                          onSelectAddress: onSelectAddress,
                        );
                      },
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                      label: Text(
                        'Change (${addresses.length - 1} more)',
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
        message: 'Could not load your addresses. Check your connection and retry.',
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
            'Delivery to ${info.pincode} · ${info.etaLabel}',
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
