import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../models/consultation.dart';

class CareChatWaitingRuleBanner extends StatelessWidget {
  const CareChatWaitingRuleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E8),
        border: Border(bottom: BorderSide(color: Color(0xFFF1D39A))),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFF71551D),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can send up to 5 text messages while waiting for our care team to reply.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF71551D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CareChatPaymentBanner extends StatelessWidget {
  const CareChatPaymentBanner({
    super.key,
    required this.booking,
    required this.busyAction,
    required this.onPayOrUnlock,
  });

  final ConsultationBooking booking;
  final bool busyAction;
  final VoidCallback onPayOrUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      color: AppColors.warningBg,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Complete payment to confirm your slot.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: busyAction ? null : onPayOrUnlock,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              booking.isFreeFollowUp
                  ? 'Confirm Free'
                  : (booking.amount != null
                        ? 'Pay ${formatPrice(booking.amount!)}'
                        : 'Pay Now'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class CareChatBubble extends StatelessWidget {
  const CareChatBubble({
    super.key,
    required this.message,
    required this.booking,
    required this.onUnlockPrescription,
    required this.onOpenMedia,
  });

  final CareChatMessage message;
  final ConsultationBooking booking;
  final ValueChanged<CareChatMessage> onUnlockPrescription;
  final ValueChanged<String> onOpenMedia;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.body.isEmpty ? 'System update' : message.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final isCustomer = message.isCustomer;
    final bubbleColor = isCustomer ? const Color(0xFFD9FDD3) : Colors.white;
    final alignment = isCustomer ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isCustomer ? 16 : 4),
              topRight: Radius.circular(isCustomer ? 4 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            border: isCustomer ? null : Border.all(color: AppColors.borderWarm),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D173C32),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCustomer) ...[
                Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (message.messageType == 'PRESCRIPTION')
                InlinePrescriptionBubble(
                  message: message,
                  booking: booking,
                  onUnlock: () => onUnlockPrescription(message),
                  onOpenUrl: onOpenMedia,
                )
              else if (message.messageType == 'IMAGE' &&
                  message.mediaUrl != null &&
                  message.mediaUrl!.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => onOpenMedia(message.mediaUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: message.mediaUrl!,
                      height: 170,
                      width: 240,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        height: 170,
                        width: 240,
                        color: AppColors.shimmerBase,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, _, _) => Container(
                        height: 100,
                        width: 200,
                        color: AppColors.surfaceAlt,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                if (message.body.isNotEmpty &&
                    message.body != 'Shared a photo') ...[
                  const SizedBox(height: 6),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isCustomer ? Colors.white : AppColors.textPrimary,
                      height: 1.38,
                    ),
                  ),
                ],
              ] else if (message.messageType == 'VIDEO' &&
                  message.mediaUrl != null &&
                  message.mediaUrl!.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => onOpenMedia(message.mediaUrl!),
                  child: Container(
                    height: 140,
                    width: 240,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Watch video clip',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (message.body.isNotEmpty &&
                    message.body != 'Shared a video' &&
                    message.body != 'Shared a photo') ...[
                  const SizedBox(height: 6),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isCustomer ? Colors.white : AppColors.textPrimary,
                      height: 1.38,
                    ),
                  ),
                ],
              ] else
                Text(
                  message.body,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                    height: 1.38,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatTime(message.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (isCustomer) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: AppColors.primaryDeep,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InlinePrescriptionBubble extends StatelessWidget {
  const InlinePrescriptionBubble({
    super.key,
    required this.message,
    required this.booking,
    required this.onUnlock,
    required this.onOpenUrl,
  });

  final CareChatMessage message;
  final ConsultationBooking booking;
  final VoidCallback onUnlock;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final hasUrl = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryWash,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: AppColors.primaryDeep,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Digital Prescription Shared',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ],
          ),
          if (message.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message.body,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (hasUrl && (message.prescriptionUnlocked ?? !booking.prescriptionLocked))
            ElevatedButton.icon(
              onPressed: () => onOpenUrl(message.mediaUrl!),
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  size: 16, color: Colors.white),
              label: const Text('View / Download Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
                minimumSize: const Size.fromHeight(38),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (!(message.prescriptionUnlocked ?? !booking.prescriptionLocked))
            ElevatedButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.lock_open_rounded,
                  size: 16, color: Colors.white),
              label: Text(
                (message.unlockAmount ?? booking.unlockAmount) != null
                    ? 'Unlock Prescription (${formatPrice((message.unlockAmount ?? booking.unlockAmount)!)})'
                    : 'Unlock Prescription',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
                minimumSize: const Size.fromHeight(38),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum CareChatMediaChoice {
  cameraPhoto,
  cameraVideo,
  galleryPhoto,
  galleryVideo,
}

Future<CareChatMediaChoice?> showCareChatMediaPickerSheet(BuildContext context) {
  return showModalBottomSheet<CareChatMediaChoice>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderWarm,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Attach Photo or Video',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Capture live with camera or select from gallery',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MediaOptionTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Take Photo',
                    subtitle: 'Live capture',
                    color: AppColors.primaryDeep,
                    bg: AppColors.primaryWash,
                    onTap: () => Navigator.pop(ctx, CareChatMediaChoice.cameraPhoto),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MediaOptionTile(
                    icon: Icons.videocam_rounded,
                    label: 'Record Video',
                    subtitle: 'Live record',
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFEF3C7),
                    onTap: () => Navigator.pop(ctx, CareChatMediaChoice.cameraVideo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MediaOptionTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Photo Gallery',
                    subtitle: 'Pick image',
                    color: const Color(0xFF2563EB),
                    bg: const Color(0xFFEFF6FF),
                    onTap: () => Navigator.pop(ctx, CareChatMediaChoice.galleryPhoto),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MediaOptionTile(
                    icon: Icons.video_library_rounded,
                    label: 'Video Gallery',
                    subtitle: 'Pick video (≤25MB)',
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFF5F3FF),
                    onTap: () => Navigator.pop(ctx, CareChatMediaChoice.galleryVideo),
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

class _MediaOptionTile extends StatelessWidget {
  const _MediaOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
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
    );
  }
}

class CareChatComposer extends StatelessWidget {
  const CareChatComposer({
    super.key,
    required this.messageController,
    required this.sending,
    required this.uploadingMedia,
    required this.onPickAndSendPhoto,
    required this.onSendTextMessage,
  });

  final TextEditingController messageController;
  final bool sending;
  final bool uploadingMedia;
  final VoidCallback onPickAndSendPhoto;
  final VoidCallback onSendTextMessage;

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
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    onPressed: uploadingMedia || sending
                        ? null
                        : onPickAndSendPhoto,
                    tooltip: 'Attach photo or video',
                    icon: uploadingMedia
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.primaryDeep,
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSendTextMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type your message…',
                      filled: true,
                      fillColor: AppColors.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.borderWarm,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.borderWarm,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: AppColors.primaryDeep,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: sending ? null : onSendTextMessage,
                      child: Center(
                        child: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'For emergencies, contact the nearest veterinary hospital immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class CareChatMessagesSection extends StatelessWidget {
  const CareChatMessagesSection({
    super.key,
    required this.isLoading,
    required this.messages,
    required this.booking,
    required this.onUnlockPrescription,
    required this.onOpenMedia,
  });

  final bool isLoading;
  final List<CareChatMessage> messages;
  final ConsultationBooking booking;
  final ValueChanged<CareChatMessage> onUnlockPrescription;
  final ValueChanged<String> onOpenMedia;

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: LoadingView(),
      );
    }
    if (messages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Your conversation with the care team starts here.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: messages
          .map(
            (msg) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CareChatBubble(
                message: msg,
                booking: booking,
                onUnlockPrescription: onUnlockPrescription,
                onOpenMedia: onOpenMedia,
              ),
            ),
          )
          .toList(),
    );
  }
}
