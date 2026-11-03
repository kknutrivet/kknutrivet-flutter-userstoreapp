import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/address.dart';
import '../../../models/user.dart';
import '../../../providers/app_providers.dart';
import '../widgets/location_search_bottom_sheet.dart';
import 'addresses_screen.dart' show addressesProvider;

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address});
  final Address? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.address?.label ?? '');
  late final _fullName =
      TextEditingController(text: widget.address?.fullName ?? '');
  late final _phone = TextEditingController(text: widget.address?.phone ?? '');
  late final _buildingNumber =
      TextEditingController(text: widget.address?.buildingNumber ?? '');
  late final _fullAddress =
      TextEditingController(text: widget.address?.fullAddress ?? '');
  late final _city = TextEditingController(text: widget.address?.city ?? '');
  late final _state = TextEditingController(text: widget.address?.state ?? '');
  late final _zip =
      TextEditingController(text: widget.address?.zipCode ?? '');
  bool _saving = false;
  bool _detectingGps = false;
  String? _locationMessage;

  static const _labelOptions = ['Home', 'Work', 'Farm', 'Clinic', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.address == null) {
      if (_label.text.isEmpty) _label.text = 'Home';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefillUserIfNeeded();
      });
    }
  }

  void _prefillUserIfNeeded() {
    if (widget.address != null) return;
    final user = ref.read(authProvider).valueOrNull;
    if (user != null && !user.isAnonymous) {
      if (_fullName.text.isEmpty && (user.name?.isNotEmpty ?? false)) {
        setState(() => _fullName.text = user.name!);
      }
      if (_phone.text.isEmpty && (user.phone?.isNotEmpty ?? false)) {
        final digits = user.phone!.replaceAll(RegExp(r'\D'), '');
        setState(() {
          _phone.text = digits.length >= 10
              ? digits.substring(digits.length - 10)
              : digits;
        });
      }
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _fullName.dispose();
    _phone.dispose();
    _buildingNumber.dispose();
    _fullAddress.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    super.dispose();
  }

  Future<void> _detectGpsLocation() async {
    if (_detectingGps) return;
    AppHaptics.selection();
    setState(() {
      _detectingGps = true;
      _locationMessage = null;
    });

    try {
      final location = await LocationService.instance.getCurrentLocation();
      if (!mounted) return;

      setState(() {
        if (location.buildingName != null && location.buildingName!.isNotEmpty) {
          _buildingNumber.text = location.buildingName!;
        }
        if (location.fullAddress != null && location.fullAddress!.isNotEmpty) {
          _fullAddress.text = location.fullAddress!;
        }
        if (location.city != null && location.city!.isNotEmpty) {
          _city.text = location.city!;
        }
        if (location.state != null && location.state!.isNotEmpty) {
          _state.text = location.state!;
        }
        if (location.zipCode != null && location.zipCode!.isNotEmpty) {
          _zip.text = location.zipCode!;
        }
        _locationMessage =
            'Location auto-filled via GPS. Please check and complete your building/flat details.';
      });
      showToast('GPS location detected');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      showToast(msg, isError: true);
      setState(() => _locationMessage = msg);
    } finally {
      if (mounted) setState(() => _detectingGps = false);
    }
  }

  Future<void> _openLocationSearch() async {
    AppHaptics.selection();
    final result = await LocationSearchBottomSheet.show(context);
    if (result != null && mounted) {
      setState(() {
        if (result.buildingName != null && result.buildingName!.isNotEmpty) {
          _buildingNumber.text = result.buildingName!;
        }
        if (result.title != null && result.title!.isNotEmpty) {
          _fullAddress.text = result.displayName;
        } else {
          _fullAddress.text = result.displayName;
        }
        if (result.city != null && result.city!.isNotEmpty) {
          _city.text = result.city!;
        }
        if (result.state != null && result.state!.isNotEmpty) {
          _state.text = result.state!;
        }
        if (result.zipCode != null && result.zipCode!.isNotEmpty) {
          _zip.text = result.zipCode!;
        }
        _locationMessage =
            'Location selected: ${result.title ?? result.displayName}. Please verify your building/house number.';
      });
      showToast('Location selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(authProvider, (_, next) {
      if (next.valueOrNull != null) {
        _prefillUserIfNeeded();
      }
    });

    final isEdit = widget.address != null;

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Address' : 'Add Delivery Address',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Location Helper Card (GPS & Location Search)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F9F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCFE5DA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.explore_rounded,
                              size: 16, color: AppColors.primaryDeep),
                          SizedBox(width: 6),
                          Text(
                            'Quick Address Fill',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Auto-fill your street, city, state, and pincode instantly:',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _detectingGps ? null : _detectGpsLocation,
                              icon: _detectingGps
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryDeep,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded,
                                      size: 16),
                              label: Text(
                                _detectingGps ? 'Locating…' : 'Use Current GPS',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDeep,
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                    color: Color(0xFFB5D8C7)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openLocationSearch,
                              icon: const Icon(Icons.search_rounded, size: 16),
                              label: const Text(
                                'Search Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                backgroundColor: Colors.white,
                                side:
                                    const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_locationMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCCE4D8)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 15, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _locationMessage!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                AppCard(
                  variant: AppCardVariant.elevated,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Label Selector
                      const Text(
                        'Address Type',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _labelOptions.map((opt) {
                          final isSelected = _label.text.trim().toLowerCase() ==
                              opt.toLowerCase();
                          return ChoiceChip(
                            label: Text(opt),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                AppHaptics.selection();
                                setState(() => _label.text = opt);
                              }
                            },
                            selectedColor: AppColors.primaryDeep,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _fullName,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Full Name *',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number (10 digits) *',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                          prefixText: '+91 ',
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().length != 10)
                            ? 'Enter a valid 10-digit mobile number'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _buildingNumber,
                        decoration: const InputDecoration(
                          labelText: 'House / Flat / Building / Apartment No. *',
                          hintText: 'e.g. Flat 302, Sai Residency / House No. 12',
                          prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Building / House name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _fullAddress,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Street Address, Road & Area *',
                          hintText: 'Road name, colony, area, near landmark',
                          prefixIcon: Icon(Icons.home_outlined, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Street address is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _city,
                              decoration: const InputDecoration(
                                labelText: 'City / Town *',
                                prefixIcon: Icon(Icons.location_city_rounded,
                                    size: 20),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _state,
                              decoration: const InputDecoration(
                                labelText: 'State *',
                                prefixIcon:
                                    Icon(Icons.map_outlined, size: 20),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _zip,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit Pincode *',
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().length != 6)
                            ? 'Enter valid 6-digit pincode'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.borderWarmSoft,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          MediaQuery.of(context).viewInsets.bottom > 0
              ? 10
              : MediaQuery.of(context).padding.bottom + 10,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: AppButton(
              label: isEdit ? 'Update Address' : 'Save Delivery Address',
              icon: const Icon(Icons.check_rounded, size: 16),
              variant: AppButtonVariant.primary,
              size: AppButtonSize.lg,
              fullWidth: true,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final address = Address(
        id: widget.address?.id ?? '',
        label: _label.text.trim().isEmpty ? null : _label.text.trim(),
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        buildingNumber: _buildingNumber.text.trim().isEmpty
            ? null
            : _buildingNumber.text.trim(),
        fullAddress: _fullAddress.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        zipCode: _zip.text.trim(),
        isDefault: widget.address?.isDefault ?? false,
      );
      Address? savedAddress;
      if (widget.address != null) {
        savedAddress = await ref
            .read(addressServiceProvider)
            .updateAddress(widget.address!.id, address);
        showToast('Address updated successfully');
      } else {
        savedAddress =
            await ref.read(addressServiceProvider).addAddress(address);
        showToast('Address added successfully');
      }
      ref.invalidate(addressesProvider);
      if (mounted) context.pop(savedAddress);
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

