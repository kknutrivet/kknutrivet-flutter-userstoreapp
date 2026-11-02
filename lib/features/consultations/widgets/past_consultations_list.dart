import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../models/consultation.dart';

class PastConsultationsListView extends StatelessWidget {
  const PastConsultationsListView({
    super.key,
    required this.consultationsAsync,
    required this.onRefresh,
    required this.onRetry,
    required this.onOpenChat,
  });

  final AsyncValue<List<ConsultationBooking>> consultationsAsync;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<ConsultationBooking> onOpenChat;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: consultationsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderWarm),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryWash,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 26,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No previous chats',
                        style: AppTheme.serif(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your veterinary Care Chat conversations and digital prescriptions will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return PastConsultationCard(
                booking: booking,
                onOpenChat: () => onOpenChat(booking),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class PastConsultationCard extends StatelessWidget {
  const PastConsultationCard({
    super.key,
    required this.booking,
    required this.onOpenChat,
  });

  final ConsultationBooking booking;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final animalTitle = booking.petName != null && booking.petName!.isNotEmpty
        ? '${booking.petName} · ${capitalize(booking.animalType)}'
        : capitalize(
            booking.animalType.isEmpty ? 'Animal' : booking.animalType,
          );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenChat,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryWash,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets_rounded,
                          size: 13,
                          color: AppColors.primaryDeep,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          animalTitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${booking.bookingRef}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  CareStatusChip(booking: booking),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                (booking.concern != null && booking.concern!.trim().isNotEmpty)
                    ? booking.concern!.trim()
                    : 'Veterinary Care Chat consultation',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDateTime(booking.createdAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: AppColors.primaryWashFaint,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onOpenChat,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Open chat →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CareStatusChip extends StatelessWidget {
  const CareStatusChip({super.key, required this.booking});
  final ConsultationBooking booking;

  @override
  Widget build(BuildContext context) {
    final upper = booking.status.toUpperCase();
    final hasRx = booking.prescription != null;

    final (Color fg, Color bg, String label) = switch (upper) {
      _ when hasRx && upper != 'COMPLETED' => (
        AppColors.rxText,
        AppColors.rxBg,
        'Prescription ready',
      ),
      'COMPLETED' => (
        AppColors.textSecondary,
        AppColors.primaryWashFaint,
        'Completed',
      ),
      'IN_PROGRESS' || 'CONFIRMED' => (
        AppColors.success,
        AppColors.successBg,
        'In progress',
      ),
      'WAITING_FOR_VET' || 'HOLD' || 'PENDING_PAYMENT' => (
        AppColors.warning,
        AppColors.warningBg,
        'Waiting for reply',
      ),
      _ => (AppColors.primaryDeep, AppColors.primaryWash, 'Waiting for reply'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PastConsultationsStickyNewBar extends StatelessWidget {
  const PastConsultationsStickyNewBar({
    super.key,
    required this.onStartNewChat,
  });

  final VoidCallback onStartNewChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderWarm)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ElevatedButton.icon(
            onPressed: onStartNewChat,
            icon: const Icon(Icons.add_circle_outline_rounded,
                size: 18, color: Colors.white),
            label: const Text('+ Start a new consultation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: Colors.white,
              iconColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
