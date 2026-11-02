import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/address.dart';
import '../../../providers/app_providers.dart';

final addressesProvider = FutureProvider.autoDispose<List<Address>>((ref) {
  return ref.read(addressServiceProvider).fetchAddresses();
});

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Saved Addresses',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDeep,
        foregroundColor: Colors.white,
        onPressed: () async {
          AppHaptics.light();
          await context.push('/addresses/new');
          ref.invalidate(addressesProvider);
        },
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text(
          'Add Address',
          style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
        ),
      ),
      body: SafeArea(
        top: false,
        child: addressesAsync.when(
          data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.location_off_outlined,
                  title: 'No saved addresses yet',
                  description:
                      'Add your delivery address for faster veterinary ordering, medicine dispatch, and doorstep tracking.',
                  actionLabel: 'Add Delivery Address',
                  onAction: () async {
                    AppHaptics.light();
                    await context.push('/addresses/new');
                    ref.invalidate(addressesProvider);
                  },
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(addressesProvider);
              await ref.read(addressesProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final address = addresses[i];
                return _AddressTile(
                  address: address,
                  onEdit: () async {
                    AppHaptics.light();
                    await context.push('/addresses/${address.id}/edit',
                        extra: address);
                    ref.invalidate(addressesProvider);
                  },
                  onDelete: () => _deleteAddress(context, ref, address.id),
                  onSetDefault: () => _setDefault(context, ref, address),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: AppLoader.large()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load addresses',
              description: e.toString(),
              actionLabel: 'Try Again',
              onAction: () => ref.invalidate(addressesProvider),
            ),
          ),
        ),
      ),
    ),
  );
}

  Future<void> _deleteAddress(
      BuildContext context, WidgetRef ref, String id) async {
    AppHaptics.light();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete address?',
            style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text(
            'This address will be removed from your saved delivery locations.'),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(addressServiceProvider).deleteAddress(id);
        showToast('Address deleted');
        ref.invalidate(addressesProvider);
      } catch (e) {
        showToast(e.toString(), isError: true);
      }
    }
  }

  Future<void> _setDefault(
      BuildContext context, WidgetRef ref, Address address) async {
    AppHaptics.selection();
    try {
      final updated = Address(
        id: address.id,
        label: address.label,
        fullName: address.fullName,
        phone: address.phone,
        buildingNumber: address.buildingNumber,
        fullAddress: address.fullAddress,
        city: address.city,
        state: address.state,
        zipCode: address.zipCode,
        isDefault: true,
      );
      await ref.read(addressServiceProvider).updateAddress(address.id, updated);
      showToast('Default address updated');
      ref.invalidate(addressesProvider);
    } catch (e) {
      showToast(e.toString(), isError: true);
    }
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      borderColor: address.isDefault ? AppColors.primaryDeep : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (address.label != null && address.label!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppBadge(
                    label: address.label!.toUpperCase(),
                    tone: AppBadgeTone.emerald,
                  ),
                ),
              Expanded(
                child: Text(
                  address.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (address.isDefault)
                const AppBadge(
                  label: 'DEFAULT',
                  tone: AppBadgeTone.emerald,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.formattedAddress,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.city}, ${address.state} — ${address.zipCode}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                address.phone,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderWarmSoft),
          Row(
            children: [
              if (!address.isDefault)
                TextButton(
                  onPressed: onSetDefault,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Set as default',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primaryDeep)),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 14, color: AppColors.error),
                label: const Text('Delete',
                    style: TextStyle(fontSize: 12, color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
