import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/consultation.dart';
import '../../../models/pet.dart';
import '../../../providers/app_providers.dart';

final myPetsProvider = FutureProvider.autoDispose<List<PetProfile>>((ref) {
  return ref.read(petServiceProvider).fetchPets();
});

final slotsProvider =
    FutureProvider.autoDispose.family<List<VetSlot>, String>((
  ref,
  date,
) async {
  final data =
      await ref.read(consultationServiceProvider).fetchSlots(date: date);
  return _parseSlots(data);
});

List<VetSlot> _parseSlots(Map<String, dynamic> data) {
  final slots = <VetSlot>[];
  final rawSlots = data['slots'];
  if (rawSlots is List) {
    for (final e in rawSlots) {
      if (e is Map<String, dynamic>) {
        try {
          slots.add(VetSlot.fromJson(e));
        } catch (_) {}
      }
    }
  }
  final rawVets = data['vets'];
  if (rawVets is List) {
    for (final v in rawVets) {
      if (v is Map<String, dynamic>) {
        final nested = v['slots'];
        if (nested is List) {
          for (final s in nested) {
            if (s is Map<String, dynamic>) {
              try {
                slots.add(VetSlot.fromJson(s));
              } catch (_) {}
            }
          }
        }
      }
    }
  }
  return slots;
}

class BookConsultationScreen extends ConsumerStatefulWidget {
  const BookConsultationScreen({
    super.key,
    this.followUpOfId,
    this.initialPetProfileId,
    this.initialAnimalType,
  });

  final String? followUpOfId;
  final String? initialPetProfileId;
  final String? initialAnimalType;

  @override
  ConsumerState<BookConsultationScreen> createState() =>
      _BookConsultationScreenState();
}

class _BookConsultationScreenState
    extends ConsumerState<BookConsultationScreen> {
  static const _languages = [
    'English',
    'हिन्दी',
    'বাংলা',
    'తెలుగు',
    'தமிழ்',
    'ଓଡ଼ିଆ',
  ];

  PetProfile? _pet;
  String? _manualAnimalType;
  String _language = 'English';
  String _date = 'today';
  String? _dateLabel;
  VetSlot? _selectedSlot;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logConsultationBookingStarted(
      animalType: widget.initialAnimalType,
    );
    _manualAnimalType = widget.initialAnimalType;
    final now = DateTime.now();
    _dateLabel = 'Today, ${formatDate(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(myPetsProvider);
    final slotsAsync = ref.watch(slotsProvider(_date));
    final animalType = _pet?.animalType ?? _manualAnimalType;

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Book a vet',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (widget.followUpOfId != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Doctor-authorized free follow-up: choose a slot within the 7-day window at ₹0 fee.',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _StepCard(
            stepNumber: 1,
            title: 'Who needs veterinary care?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                petsAsync.when(
                  data: (pets) {
                    if (pets.isNotEmpty) {
                      return Column(
                        children: [
                          for (final pet in pets)
                            InkWell(
                              onTap: () {
                                AppHaptics.selection();
                                setState(() => _pet = pet);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _pet == pet
                                              ? AppColors.primaryDeep
                                              : AppColors.border,
                                          width: _pet == pet ? 6 : 2,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryWash,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.pets,
                                          color: AppColors.primaryDeep,
                                          size: 18),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pet.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            capitalize(pet.animalType),
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                _pet = null;
                                _manualAnimalType = null;
                              }),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Other animal'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const Text(
                      'No saved pet profiles. Select an animal type below:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                if (_pet == null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Dog',
                      'Cat',
                      'Cattle',
                      'Poultry',
                      'Goat/Sheep'
                    ].map((a) {
                      final selected = _manualAnimalType == a;
                      return ChoiceChip(
                        label: Text(a),
                        selected: selected,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryDeep
                              : AppColors.textPrimary,
                        ),
                        backgroundColor: AppColors.primaryWashFaint,
                        selectedColor: AppColors.primaryWash,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.borderWarm,
                          ),
                        ),
                        onSelected: (_) {
                          AppHaptics.selection();
                          setState(() => _manualAnimalType = a);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StepCard(
            stepNumber: 2,
            title: 'Preferred consultation language',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((l) {
                final selected = _language == l;
                return ChoiceChip(
                  label: Text(l),
                  selected: selected,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primaryDeep
                        : AppColors.textPrimary,
                  ),
                  backgroundColor: AppColors.primaryWashFaint,
                  selectedColor: AppColors.primaryWash,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          selected ? AppColors.primary : AppColors.borderWarm,
                    ),
                  ),
                  onSelected: (_) {
                    AppHaptics.selection();
                    setState(() => _language = l);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _StepCard(
            stepNumber: 3,
            title: 'Select appointment slot',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(
                    _dateLabel ?? _date,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDeep,
                    side: const BorderSide(color: AppColors.borderWarm),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                slotsAsync.when(
                  data: (slots) {
                    if (slots.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: EmptyView(
                          message:
                              'No slots available for this date.\nPlease choose another day.',
                          icon: Icons.event_busy_outlined,
                        ),
                      );
                    }
                    final grouped = <String, List<VetSlot>>{};
                    for (final s in slots) {
                      grouped.putIfAbsent(s.vet.name, () => []).add(s);
                    }
                    return Column(
                      children: grouped.entries.map((e) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${e.key}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: e.value.map((slot) {
                                final selected =
                                    _selectedSlot?.id == slot.id;
                                final isPast = slot.startAt
                                    .isBefore(DateTime.now());
                                return ChoiceChip(
                                  label: Text(formatTime(slot.startAt)),
                                  selected: selected,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.primaryDeep
                                        : (isPast
                                            ? AppColors.textTertiary
                                            : AppColors.textPrimary),
                                  ),
                                  backgroundColor: Colors.white,
                                  selectedColor: AppColors.primaryWash,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: selected
                                          ? AppColors.primaryDeep
                                          : AppColors.borderWarm,
                                    ),
                                  ),
                                  onSelected: isPast
                                      ? null
                                      : (_) {
                                          AppHaptics.selection();
                                          setState(() =>
                                              _selectedSlot = slot);
                                        },
                                  avatar: isPast
                                      ? null
                                      : (selected
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              size: 15,
                                              color: AppColors.primaryDeep)
                                          : const Icon(
                                              Icons.access_time_rounded,
                                              size: 14,
                                              color:
                                                  AppColors.textSecondary)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: LoadingView(),
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(slotsProvider(_date)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderWarm)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_selectedSlot != null)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consultation Fee',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.followUpOfId != null
                          ? 'FREE FOLLOW-UP'
                          : formatPrice(_selectedSlot!.vet.fee),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeepest,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ElevatedButton(
                onPressed:
                    (animalType == null || _selectedSlot == null || _booking)
                        ? null
                        : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _booking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm & Book'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    AppHaptics.light();
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 14)),
    );
    if (picked == null) return;
    final isToday = picked.year == today.year &&
        picked.month == today.month &&
        picked.day == today.day;
    setState(() {
      _date = isToday
          ? 'today'
          : '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _dateLabel =
          isToday ? 'Today, ${formatDate(picked)}' : formatDate(picked);
      _selectedSlot = null;
    });
    ref.invalidate(slotsProvider(_date));
  }

  Future<void> _confirm() async {
    AppHaptics.light();
    final animalType = _pet?.animalType ?? _manualAnimalType!;
    setState(() => _booking = true);
    try {
      final booking = await ref.read(consultationServiceProvider).holdSlot(
            slotId: _selectedSlot!.id,
            petProfileId: _pet?.id ?? widget.initialPetProfileId,
            animalType: animalType,
            language: _language,
            followUpOfId: widget.followUpOfId,
          );
      if (!mounted) return;
      final proceed = await _showConfirmDialog(booking);
      if (proceed == true) {
        if (!mounted) return;
        AnalyticsService.instance.logConsultationBooked(
          consultationId: booking.id,
          amount: booking.amount,
        );
        showToast(
          booking.isFreeFollowUp
              ? 'Free follow-up slot held. Please confirm it.'
              : 'Slot held. Please complete payment.',
        );
        context.pushReplacement('/consultations/${booking.id}');
      }
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  Future<bool?> _showConfirmDialog(ConsultationBooking booking) {
    final vetName = booking.vet?.name ?? _selectedSlot?.vet.name ?? 'Vet';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirm Consultation',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor: Dr. $vetName',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Time: ${_selectedSlot != null ? formatDateTime(_selectedSlot!.startAt) : ''}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Language: $_language',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Animal: ${booking.animalType}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryWashFaint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Payable:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    booking.isFreeFollowUp
                        ? '₹0 (Free Follow-up)'
                        : (booking.amount != null
                            ? formatPrice(booking.amount!)
                            : 'Standard Fee'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primaryDeepest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => ctx.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.child,
  });

  final int stepNumber;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderWarm),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.primaryDeep,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
