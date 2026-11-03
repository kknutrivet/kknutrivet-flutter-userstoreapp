import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/consultation.dart';

class ConsultationDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ConsultationDetailAppBar({
    super.key,
    required this.booking,
    required this.busyAction,
    required this.onJoinVideoCall,
    this.videoAvailable = false,
    this.videoEligible = false,
    this.videoAmount,
    this.careChatAssignedAt,
    this.onPayVideoCall,
  });

  final ConsultationBooking? booking;
  final bool busyAction;
  final bool videoAvailable;
  final bool videoEligible;
  final double? videoAmount;
  final DateTime? careChatAssignedAt;
  final ValueChanged<ConsultationBooking> onJoinVideoCall;
  final VoidCallback? onPayVideoCall;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final currentBooking = booking;
    final isDoctorAssigned = currentBooking != null &&
        (careChatAssignedAt != null || currentBooking.isDoctorAssigned);

    final doctorSubtitle = currentBooking == null
        ? 'KK Nutrivet Care Team'
        : (isDoctorAssigned &&
                currentBooking.vet != null &&
                currentBooking.vet!.name.trim().isNotEmpty
            ? (currentBooking.vet!.name.trim().toLowerCase().startsWith('dr')
                ? currentBooking.vet!.name.trim()
                : 'Dr. ${currentBooking.vet!.name.trim()}')
            : 'KK Nutrivet Care Team');

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: currentBooking == null
          ? const Text('Care Chat')
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryWash,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    size: 18,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${capitalize(currentBooking.animalType.isEmpty ? 'Animal' : currentBooking.animalType)} · #${currentBooking.bookingRef}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConsultationHeaderStatusBadge(
                            status: currentBooking.status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctorSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      actions: [
        if (currentBooking != null)
          IconButton(
            onPressed: busyAction
                ? null
                : () {
                    if (videoAvailable ||
                        (currentBooking.meetingUrl != null &&
                            currentBooking.meetingUrl!.isNotEmpty)) {
                      onJoinVideoCall(currentBooking);
                    } else if (videoEligible && onPayVideoCall != null) {
                      onPayVideoCall!();
                    } else if (!isDoctorAssigned) {
                      AppHaptics.light();
                      showToast(
                        'Video call is not active yet. Our care team will assign a veterinarian shortly.',
                      );
                    } else {
                      AppHaptics.light();
                      showToast(
                        'Video call is not active yet. Your doctor will initiate or schedule the video session if needed.',
                      );
                    }
                  },
            tooltip: videoAvailable
                ? 'Join video consultation'
                : (videoEligible
                    ? 'Video consultation available · Tap to unlock'
                    : 'Video consultation status'),
            icon: busyAction
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryDeep,
                    ),
                  )
                : Icon(
                    videoAvailable
                        ? Icons.videocam_rounded
                        : Icons.videocam_outlined,
                    color: videoAvailable ||
                            (currentBooking.meetingUrl != null &&
                                currentBooking.meetingUrl!.isNotEmpty)
                        ? AppColors.primaryDeep
                        : (videoEligible
                            ? AppColors.warning
                            : AppColors.textSecondary),
                  ),
          ),
        IconButton(
          onPressed: () {
            AppHaptics.light();
            context.go('/consultations');
          },
          tooltip: 'Past History',
          icon: const Icon(
            Icons.history_rounded,
            color: AppColors.primaryDeep,
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.borderWarm),
      ),
    );
  }
}

class ConsultationHeaderStatusBadge extends StatelessWidget {
  const ConsultationHeaderStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, String text) = switch (status.toUpperCase()) {
      'IN_PROGRESS' || 'CONFIRMED' => (
        AppColors.success,
        AppColors.successBg,
        'In progress',
      ),
      'COMPLETED' => (
        AppColors.textSecondary,
        AppColors.primaryWashFaint,
        'Completed',
      ),
      _ => (AppColors.warning, AppColors.warningBg, 'Waiting'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class CareIntroCard extends StatelessWidget {
  const CareIntroCard({super.key, required this.booking});
  final ConsultationBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: AppColors.primaryDeep,
              ),
              const SizedBox(width: 6),
              Text(
                '${capitalize(booking.animalType.isEmpty ? 'Animal' : booking.animalType)} Care Chat · ${booking.language ?? 'English'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
          if (booking.concern != null &&
              booking.concern!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              booking.concern!.trim(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Our care team will review your case with a certified veterinarian and reply right here.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class ConsultationPrescriptionCard extends StatelessWidget {
  const ConsultationPrescriptionCard({
    super.key,
    required this.prescription,
    required this.locked,
    this.unlockAmount,
    this.onDownloadPdf,
    required this.onOrderMedicines,
    required this.onUnlock,
    this.busyAction = false,
  });

  final ConsultationPrescription prescription;
  final bool locked;
  final double? unlockAmount;
  final VoidCallback? onDownloadPdf;
  final VoidCallback onOrderMedicines;
  final VoidCallback onUnlock;
  final bool busyAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.rxBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rxBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: AppColors.rxText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digital Prescription (Rx)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Issued by certified veterinarian',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDownloadPdf != null && !locked)
                IconButton(
                  onPressed: onDownloadPdf,
                  tooltip: 'Download PDF',
                  icon: const Icon(
                    Icons.download_rounded,
                    color: AppColors.primaryDeep,
                  ),
                ),
            ],
          ),
          if (locked) ...[
            const SizedBox(height: 12),
            const Text(
              'Your veterinarian has prepared a digital prescription for this consultation.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: busyAction ? null : onUnlock,
              icon: busyAction
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_open_rounded,
                      size: 17, color: Colors.white),
              label: Text(
                busyAction
                    ? 'Opening payment gateway…'
                    : unlockAmount != null
                        ? 'Unlock Prescription for ${formatPrice(unlockAmount!)}'
                        : 'Unlock Prescription',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                disabledBackgroundColor:
                    AppColors.primaryDeep.withValues(alpha: 0.65),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
                iconColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ] else ...[
            if (prescription.diagnosis != null &&
                prescription.diagnosis!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Diagnosis: ${prescription.diagnosis}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            if (prescription.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              ...prescription.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.primaryDeep,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.medicineName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              [
                                if (item.dosage.isNotEmpty) item.dosage,
                                if (item.frequency.isNotEmpty) item.frequency,
                                if (item.duration.isNotEmpty) item.duration,
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (prescription.instructions != null &&
                prescription.instructions!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Instructions: ${prescription.instructions}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (onDownloadPdf != null) ...[
                  OutlinedButton.icon(
                    onPressed: onDownloadPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 44),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onOrderMedicines,
                    icon: const Icon(Icons.shopping_bag_outlined,
                        size: 17, color: Colors.white),
                    label: const Text('Order Prescribed Medicines'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      foregroundColor: Colors.white,
                      iconColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class RateConsultationCard extends StatelessWidget {
  const RateConsultationCard({
    super.key,
    this.existingRating,
    this.existingComment,
    required this.submitted,
    required this.selectedRating,
    required this.commentController,
    required this.submitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int? existingRating;
  final String? existingComment;
  final bool submitted;
  final int selectedRating;
  final TextEditingController commentController;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final alreadyRated = existingRating != null || submitted;
    final displayRating = existingRating ?? selectedRating;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alreadyRated
                ? 'Thank you for rating this consultation'
                : 'Rate this consultation',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: alreadyRated ? null : () => onRatingChanged(star),
                icon: Icon(
                  star <= displayRating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: AppColors.starGold,
                  size: 30,
                ),
              );
            }),
          ),
          if (!alreadyRated) ...[
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 2,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Share your feedback (optional)…',
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(submitting ? 'Submitting…' : 'Submit Review'),
            ),
          ] else if (existingComment != null &&
              existingComment!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              existingComment!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
