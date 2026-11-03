import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common.dart';
import '../../../models/pet.dart';
import '../../../providers/app_providers.dart';

final petDetailProvider = FutureProvider.autoDispose.family<PetProfile, String>(
  (ref, id) {
    return ref.read(petServiceProvider).fetchPet(id);
  },
);

class PetDetailScreen extends ConsumerStatefulWidget {
  const PetDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Pet Profile',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: _busy ? null : () => _deletePet(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: petAsync.when(
          data: (pet) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(petDetailProvider(widget.id));
              await ref.read(petDetailProvider(widget.id).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(pet),
                const SizedBox(height: 14),
                _reminders(pet),
                if (pet.careGuide != null) ...[
                  const SizedBox(height: 14),
                  _careGuide(pet.careGuide!),
                ],
                if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    variant: AppCardVariant.elevated,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Care Notes & History',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pet.notes!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _actions(pet),
                const SizedBox(height: 36),
              ],
            ),
          ),
          loading: () => const Center(child: AppLoader.large()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load profile',
                description: e.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(petDetailProvider(widget.id)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(PetProfile pet) {
    return AppCard(
      variant: AppCardVariant.tinted,
      backgroundColor: AppColors.primaryDeep,
      borderColor: AppColors.primaryDeepest,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 72,
              height: 72,
              child: pet.photoUrl != null && pet.photoUrl!.isNotEmpty
                  ? AppNetworkImage(imageUrl: pet.photoUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.white24,
                      child: const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  capitalize(pet.animalType),
                  style: const TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (pet.breed != null) _pill('${pet.breed}', Icons.pets),
                    if (pet.ageInMonths != null)
                      _pill(
                        pet.ageInMonths! >= 12
                            ? '${(pet.ageInMonths! / 12).floor()}y ${pet.ageInMonths! % 12}m'
                            : '${pet.ageInMonths}m',
                        Icons.cake_outlined,
                      ),
                    if (pet.weightKg != null)
                      _pill(
                        '${pet.weightKg} kg',
                        Icons.monitor_weight_outlined,
                      ),
                    if (pet.sex != null) _pill(pet.sex!, Icons.wc_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _reminders(PetProfile pet) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Care Reminders',
                style: AppTheme.serif(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                ),
              ),
              const Spacer(),
              AppBadge(
                label: pet.reminderEnabled
                    ? 'Reminders enabled'
                    : 'Reminders off',
                tone: pet.reminderEnabled
                    ? AppBadgeTone.emerald
                    : AppBadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _reminderRow(
            'Vaccination',
            pet.lastVaccinationAt,
            pet.nextVaccinationAt,
            Icons.vaccines_outlined,
          ),
          const Divider(height: 24, color: AppColors.borderWarmSoft),
          _reminderRow(
            'Deworming',
            pet.lastDewormingAt,
            pet.nextDewormingAt,
            Icons.medication_outlined,
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Update Reminder Dates',
            icon: const Icon(Icons.edit_calendar_outlined, size: 16),
            variant: AppButtonVariant.outline,
            size: AppButtonSize.sm,
            fullWidth: true,
            onPressed: _busy ? null : () => _updateReminders(pet),
          ),
        ],
      ),
    );
  }

  Widget _reminderRow(
    String label,
    DateTime? last,
    DateTime? next,
    IconData icon,
  ) {
    final isDue = next != null && next.isBefore(DateTime.now());
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDue
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primaryWash,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDue ? AppColors.error : AppColors.primaryDeep,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                last != null ? 'Last: ${formatDate(last)}' : 'Last: —',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                next != null ? 'Next: ${formatDate(next)}' : 'Next: —',
                style: TextStyle(
                  color: isDue ? AppColors.error : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isDue ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (isDue) const AppBadge(label: 'DUE NOW', tone: AppBadgeTone.coral),
      ],
    );
  }

  Widget _careGuide(Map<String, dynamic> guide) {
    final title = guide['title']?.toString() ?? 'Personalized Care Guide';
    final content = guide['content'] ?? guide['description'] ?? guide['steps'];
    final contentText = content is List
        ? content.map((e) => '• $e').join('\n')
        : content?.toString() ?? '';
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: AppColors.primaryDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contentText.isNotEmpty
                ? contentText
                : 'Veterinary care guidance is currently being generated for this profile.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(PetProfile pet) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Care team chat',
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
            variant: AppButtonVariant.primary,
            size: AppButtonSize.md,
            onPressed: () {
              AppHaptics.light();
              context.push('/consultations');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            label: 'Dr. Paw (AI)',
            icon: const Icon(Icons.auto_awesome, size: 15),
            variant: AppButtonVariant.outline,
            size: AppButtonSize.md,
            onPressed: () {
              AppHaptics.light();
              context.push('/vet');
            },
          ),
        ),
      ],
    );
  }

  Future<void> _updateReminders(PetProfile pet) async {
    DateTime? lastVax = pet.lastVaccinationAt;
    DateTime? nextVax = pet.nextVaccinationAt;
    DateTime? lastDeworm = pet.lastDewormingAt;
    DateTime? nextDeworm = pet.nextDewormingAt;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pick(
            DateTime? current,
            void Function(DateTime?) onPicked,
          ) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: current ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) onPicked(picked);
          }

          Widget dateField(
            String label,
            DateTime? value,
            void Function(DateTime?) onPicked,
          ) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () => pick(value, onPicked),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    value != null ? formatDate(value) : 'Select date',
                    style: TextStyle(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            title: Text(
              'Update Reminders',
              style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dateField(
                    'Last vaccination',
                    lastVax,
                    (d) => setDialogState(() => lastVax = d),
                  ),
                  dateField(
                    'Next vaccination',
                    nextVax,
                    (d) => setDialogState(() => nextVax = d),
                  ),
                  const SizedBox(height: 6),
                  dateField(
                    'Last deworming',
                    lastDeworm,
                    (d) => setDialogState(() => lastDeworm = d),
                  ),
                  dateField(
                    'Next deworming',
                    nextDeworm,
                    (d) => setDialogState(() => nextDeworm = d),
                  ),
                ],
              ),
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(petServiceProvider).updateReminders(widget.id, {
        'reminderEnabled': true,
        if (lastVax != null) 'lastVaccinationAt': lastVax!.toIso8601String(),
        if (nextVax != null) 'nextVaccinationAt': nextVax!.toIso8601String(),
        if (lastDeworm != null)
          'lastDewormingAt': lastDeworm!.toIso8601String(),
        if (nextDeworm != null)
          'nextDewormingAt': nextDeworm!.toIso8601String(),
      });
      showToast('Reminders updated');
      ref.invalidate(petDetailProvider(widget.id));
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this pet?'),
        content: const Text(
          'The care profile and its history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(petServiceProvider).deletePet(widget.id);
      showToast('Pet deleted');
      if (mounted) context.go('/pets');
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
