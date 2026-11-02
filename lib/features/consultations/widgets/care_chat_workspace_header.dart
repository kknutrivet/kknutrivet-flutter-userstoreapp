import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

class CareChatWorkspaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CareChatWorkspaceAppBar({
    super.key,
    required this.showPastConsultations,
    required this.pastCount,
    required this.onStartNewChat,
    required this.onSelectCurrent,
    required this.onSelectPast,
  });

  final bool showPastConsultations;
  final int pastCount;
  final VoidCallback onStartNewChat;
  final VoidCallback onSelectCurrent;
  final VoidCallback onSelectPast;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 54);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vet Care Chat',
            style: AppTheme.serif(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Certified veterinarians · Digital prescriptions',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: onStartNewChat,
            icon: const Icon(Icons.add_comment_outlined, size: 16),
            label: const Text('+ New Chat'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDeep,
              backgroundColor: AppColors.primaryWash,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.borderWarm)),
          ),
          child: CareChatWorkspaceModeToggle(
            showPast: showPastConsultations,
            pastCount: pastCount,
            onSelectCurrent: onSelectCurrent,
            onSelectPast: onSelectPast,
          ),
        ),
      ),
    );
  }
}

class CareChatWorkspaceModeToggle extends StatelessWidget {
  const CareChatWorkspaceModeToggle({
    super.key,
    required this.showPast,
    required this.pastCount,
    required this.onSelectCurrent,
    required this.onSelectPast,
  });

  final bool showPast;
  final int pastCount;
  final VoidCallback onSelectCurrent;
  final VoidCallback onSelectPast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryWashFaint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              selected: !showPast,
              icon: Icons.chat_bubble_outline_rounded,
              label: 'New / Current Care Chat',
              onTap: onSelectCurrent,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ToggleSegment(
              selected: showPast,
              icon: Icons.history_rounded,
              label: 'Past Consultations ($pastCount)',
              onTap: onSelectPast,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryDeep : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CareChatSummaryChipsBar extends StatelessWidget {
  const CareChatSummaryChipsBar({
    super.key,
    required this.step,
    required this.selectedLanguage,
    required this.contactName,
    required this.contactPhone,
    required this.selectedAnimal,
    required this.otherAnimalName,
    required this.onStepTap,
  });

  final int step;
  final String selectedLanguage;
  final String contactName;
  final String contactPhone;
  final String selectedAnimal;
  final String otherAnimalName;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    if (step == 0) return const SizedBox.shrink();

    final chips = <Widget>[];
    if (step >= 1) {
      chips.add(
        CareChatSummaryStepChip(
          icon: Icons.translate_rounded,
          label: selectedLanguage,
          onTap: () {
            AppHaptics.selection();
            onStepTap(0);
          },
        ),
      );
    }
    if (step >= 2 && contactName.trim().isNotEmpty) {
      chips.add(
        CareChatSummaryStepChip(
          icon: Icons.person_outline_rounded,
          label: '${contactName.trim()} · ${contactPhone.trim()}',
          onTap: () {
            AppHaptics.selection();
            onStepTap(1);
          },
        ),
      );
    }
    if (step >= 3 && selectedAnimal.isNotEmpty) {
      final displayAnimal =
          selectedAnimal == 'Other' && otherAnimalName.trim().isNotEmpty
          ? otherAnimalName.trim()
          : selectedAnimal;
      chips.add(
        CareChatSummaryStepChip(
          icon: Icons.pets_rounded,
          label: displayAnimal,
          onTap: () {
            AppHaptics.selection();
            onStepTap(2);
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

class CareChatSummaryStepChip extends StatelessWidget {
  const CareChatSummaryStepChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryWashDeep),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primaryDeep),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit_outlined,
                size: 13,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CareChatIntakeCardHeader extends StatelessWidget {
  const CareChatIntakeCardHeader({
    super.key,
    required this.step,
  });

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryWash,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'KK Nutrivet care team',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Step ${step + 1} of 4',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Let’s help your animal',
          style: AppTheme.serif(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Share a few details to start a free chat with our care team. Replies appear right here in this chat.',
          style: TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(4, (index) {
            final active = index <= step;
            return Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
