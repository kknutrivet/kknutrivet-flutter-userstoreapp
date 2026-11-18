import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/consultation.dart';

class CareChatWaitingRuleBanner extends StatelessWidget {
  const CareChatWaitingRuleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8E8),
        border: Border(bottom: BorderSide(color: Color(0xFFF1D39A))),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF71551D)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Our care team is reviewing your case. We will notify you as soon as a doctor joins.',
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

class CareChatCoinsBar extends StatelessWidget {
  const CareChatCoinsBar({
    super.key,
    required this.coinStatus,
    required this.packsExpanded,
    required this.confirmingRecharge,
    required this.rechargingPackAmount,
    required this.onTogglePacks,
    required this.onSelectPack,
  });

  final CareChatCoinStatus coinStatus;
  final bool packsExpanded;
  final bool confirmingRecharge;
  final int? rechargingPackAmount;
  final VoidCallback onTogglePacks;
  final ValueChanged<CareCoinRechargePack> onSelectPack;

  String _phaseDescription() {
    if (coinStatus.intakeFree) {
      return 'Initial intake free · Then ${coinStatus.freeMessagesTotal} free msgs (${coinStatus.coinsPerMessage} coins/msg)';
    }
    final rem = coinStatus.isFollowUp || !coinStatus.waitingForDoctor
        ? coinStatus.freeMessagesRemaining
        : coinStatus.waitingMessagesRemaining;
    final plural = rem == 1 ? '' : 's';
    if (coinStatus.isFollowUp) {
      if (rem > 0) {
        return 'Follow-up · $rem free msg$plural left (then ${coinStatus.coinsPerMessage} coins/msg)';
      }
      return 'Follow-up · ${coinStatus.coinsPerMessage} KK Coins / message';
    }
    if (coinStatus.waitingForDoctor) {
      return 'Waiting for doctor · $rem free msg$plural left (0 coins while waiting)';
    }
    if (rem > 0) {
      return 'Doctor joined · $rem free msg$plural left (then ${coinStatus.coinsPerMessage} coins/msg)';
    }
    return '${coinStatus.coinsPerMessage} KK Coins / message';
  }

  Widget _rechargeToggleButton() {
    return InkWell(
      onTap: onTogglePacks,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primaryDeep.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          packsExpanded ? 'Hide packs' : '+ Recharge',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDeep,
          ),
        ),
      ),
    );
  }

  Widget _buildPackGrid({
    required Color cardBorderColor,
    required Color cardBackground,
  }) {
    final packs = coinStatus.effectivePacks;
    final isBusy = rechargingPackAmount != null;
    return Row(
      children: [
        for (int i = 0; i < packs.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: isBusy ? null : () => onSelectPack(packs[i]),
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: isBusy && rechargingPackAmount != packs[i].amount
                    ? 0.55
                    : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      rechargingPackAmount == packs[i].amount
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryDeep,
                              ),
                            )
                          : Text(
                              '₹${packs[i].amount}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                      const SizedBox(height: 2),
                      Text(
                        '${packs[i].coins} Coins',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      if (packs[i].label.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          packs[i].label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.2,
                            height: 1.15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (confirmingRecharge) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF065F46),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirming your KK Coins recharge…',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (coinStatus.waitingLockActive) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 15,
                  color: Color(0xFF065F46),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Waiting for a doctor to accept your consultation',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Balance: ${coinStatus.userCoinsBalance}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                _rechargeToggleButton(),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'You have shared ${coinStatus.waitingMessagesUsed}/${coinStatus.waitingMessagesLimit} initial messages. Messaging is paused so your KK Coins are not spent while waiting — chat unlocks automatically at ${coinStatus.coinsPerMessage} KK Coins / message once a doctor accepts.',
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.35,
                color: Color(0xFF065F46),
              ),
            ),
            if (packsExpanded) ...[
              const SizedBox(height: 8),
              _buildPackGrid(
                cardBorderColor: AppColors.borderWarm,
                cardBackground: Colors.white,
              ),
            ],
          ],
        ),
      );
    }

    if (coinStatus.outOfCoins) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.monetization_on_outlined,
                  size: 15,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Out of KK Coins · Need ${coinStatus.coinsPerMessage} coins (Balance: ${coinStatus.userCoinsBalance})',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Recharge KK Coins to continue chatting with the care team. Your message draft is preserved below.',
              style: TextStyle(
                fontSize: 10.5,
                height: 1.35,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 8),
            _buildPackGrid(
              cardBorderColor: const Color(0xFFFCD34D),
              cardBackground: Colors.white,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderWarm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on_outlined,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _phaseDescription(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Balance: ${coinStatus.userCoinsBalance}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                _rechargeToggleButton(),
              ],
            ),
          ),
          if (packsExpanded) ...[
            const SizedBox(height: 8),
            _buildPackGrid(
              cardBorderColor: AppColors.borderWarm,
              cardBackground: Colors.white,
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

const kChatReactions = ["👍", "❤️", "😊", "🙏", "🎉", "😢"];

class CareChatBubble extends StatelessWidget {
  const CareChatBubble({
    super.key,
    required this.message,
    required this.booking,
    required this.onUnlockPrescription,
    required this.onOpenMedia,
    this.canReact = true,
    this.onReact,
    this.busyAction = false,
    this.freeRxUnlocked = false,
  });

  final CareChatMessage message;
  final ConsultationBooking booking;
  final ValueChanged<CareChatMessage> onUnlockPrescription;
  final ValueChanged<String> onOpenMedia;
  final bool canReact;
  final void Function(CareChatMessage message, String emoji)? onReact;
  final bool busyAction;
  final bool freeRxUnlocked;

  void _showReactionSheet(BuildContext context) {
    AppHaptics.selection();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final emoji in kChatReactions)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    AppHaptics.light();
                    Navigator.pop(ctx);
                    onReact?.call(message, emoji);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      final isNoVetWait = message.isNoVetWaitNotice;
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: isNoVetWait ? 10 : 7,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.88,
          ),
          decoration: BoxDecoration(
            color: isNoVetWait
                ? const Color(0xFFF5F9F7)
                : const Color(0xFFEEF4F1),
            borderRadius: BorderRadius.circular(isNoVetWait ? 14 : 18),
            border: Border.all(
              color: const Color(0xFFDCE8E1),
              width: isNoVetWait ? 1 : 0.8,
            ),
          ),
          child: Text(
            message.body.isEmpty ? 'System update' : message.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isNoVetWait ? 12 : 11.5,
              fontWeight: isNoVetWait ? FontWeight.w600 : FontWeight.w500,
              height: 1.38,
              color: isNoVetWait
                  ? const Color(0xFF466155)
                  : const Color(0xFF566B60),
            ),
          ),
        ),
      );
    }

    final isCustomer = message.isCustomer;
    final bubbleColor = isCustomer ? AppColors.primaryWash : Colors.white;
    final alignment = isCustomer ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: GestureDetector(
          onLongPress: canReact && onReact != null
              ? () => _showReactionSheet(context)
              : null,
          child: Column(
            crossAxisAlignment: isCustomer
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isCustomer ? 16 : 4),
                    topRight: Radius.circular(isCustomer ? 4 : 16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                  border: isCustomer
                      ? null
                      : Border.all(color: AppColors.borderWarm),
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
                        busyAction: busyAction,
                        freeRxUnlocked: freeRxUnlocked,
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
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
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
                            color: isCustomer
                                ? Colors.white
                                : AppColors.textPrimary,
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
                            color: isCustomer
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1.38,
                          ),
                        ),
                      ],
                    ] else if (message.body.startsWith('Care Chat intake'))
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Your care details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Text(
                            message.body,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ],
                      )
                    else
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
              // Reactions row & quick react button:
              if (message.reactions.isNotEmpty || (canReact && onReact != null))
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final reaction in message.reactions)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: canReact && onReact != null
                              ? () => onReact!(message, reaction.emoji)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: reaction.mine
                                  ? const Color(0xFFE2F4EB)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: reaction.mine
                                    ? AppColors.primary
                                    : const Color(0xFFD6E2DB),
                                width: reaction.mine ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  reaction.emoji,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${reaction.count}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: reaction.mine
                                        ? AppColors.primaryDeep
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (canReact && onReact != null)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showReactionSheet(context),
                          child: Container(
                            width: 24,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD6E2DB),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_reaction_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
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

class InlinePrescriptionBubble extends StatelessWidget {
  const InlinePrescriptionBubble({
    super.key,
    required this.message,
    required this.booking,
    required this.onUnlock,
    required this.onOpenUrl,
    this.busyAction = false,
    this.freeRxUnlocked = false,
  });

  final CareChatMessage message;
  final ConsultationBooking booking;
  final VoidCallback onUnlock;
  final ValueChanged<String> onOpenUrl;
  final bool busyAction;
  final bool freeRxUnlocked;

  @override
  Widget build(BuildContext context) {
    final hasUrl = message.mediaUrl != null && message.mediaUrl!.isNotEmpty;
    final unlocked =
        freeRxUnlocked ||
        (message.prescriptionUnlocked ?? !booking.prescriptionLocked);
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
          if (hasUrl && unlocked)
            ElevatedButton.icon(
              onPressed: () => onOpenUrl(message.mediaUrl!),
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                size: 16,
                color: Colors.white,
              ),
              label: const Text('View / Download Prescription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                foregroundColor: Colors.white,
                iconColor: Colors.white,
                minimumSize: const Size.fromHeight(38),
                textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontFamilyFallback: ['Roboto', 'sans-serif'],
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (!unlocked)
            ElevatedButton.icon(
              onPressed: busyAction ? null : onUnlock,
              icon: busyAction
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.lock_open_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
              label: Text(
                busyAction
                    ? 'Opening payment gateway…'
                    : (message.unlockAmount ?? booking.unlockAmount) != null
                    ? 'Unlock Prescription (${formatPrice((message.unlockAmount ?? booking.unlockAmount)!)})'
                    : 'Unlock Prescription',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDeep,
                disabledBackgroundColor: AppColors.primaryDeep.withValues(
                  alpha: 0.65,
                ),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
                iconColor: Colors.white,
                minimumSize: const Size.fromHeight(38),
                textStyle: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontFamilyFallback: ['Roboto', 'sans-serif'],
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

Future<CareChatMediaChoice?> showCareChatMediaPickerSheet(
  BuildContext context,
) {
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
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                    onTap: () =>
                        Navigator.pop(ctx, CareChatMediaChoice.cameraPhoto),
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
                    onTap: () =>
                        Navigator.pop(ctx, CareChatMediaChoice.cameraVideo),
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
                    onTap: () =>
                        Navigator.pop(ctx, CareChatMediaChoice.galleryPhoto),
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
                    onTap: () =>
                        Navigator.pop(ctx, CareChatMediaChoice.galleryVideo),
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
    this.locked = false,
    this.hintText,
    this.topBanner,
  });

  final TextEditingController messageController;
  final bool sending;
  final bool uploadingMedia;
  final VoidCallback onPickAndSendPhoto;
  final VoidCallback onSendTextMessage;
  final bool locked;
  final String? hintText;
  final Widget? topBanner;

  @override
  Widget build(BuildContext context) {
    final controlsDisabled = locked || uploadingMedia || sending;
    final resolvedHint =
        hintText ??
        (locked ? 'Waiting for a doctor to accept…' : 'Type your message…');
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
              ?topBanner,
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: controlsDisabled ? null : onPickAndSendPhoto,
                      tooltip: locked
                          ? 'Waiting for a doctor to accept'
                          : 'Attach photo or video',
                      icon: uploadingMedia
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.add_photo_alternate_outlined,
                              color: locked
                                  ? AppColors.textTertiary
                                  : AppColors.primaryDeep,
                            ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      enabled: !locked,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!locked) onSendTextMessage();
                      },
                      decoration: InputDecoration(
                        hintText: resolvedHint,
                        filled: true,
                        fillColor: locked
                            ? AppColors.surfaceAlt.withValues(alpha: 0.6)
                            : AppColors.surfaceAlt,
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
                        disabledBorder: OutlineInputBorder(
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
                      color: locked
                          ? const Color(0xFFB8C7BF)
                          : AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: (sending || locked) ? null : onSendTextMessage,
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
    this.canReact = true,
    this.onReact,
    this.busyAction = false,
    this.busyMessageId,
    this.freeRxUnlocked = false,
  });

  final bool isLoading;
  final List<CareChatMessage> messages;
  final ConsultationBooking booking;
  final ValueChanged<CareChatMessage> onUnlockPrescription;
  final ValueChanged<String> onOpenMedia;
  final bool canReact;
  final void Function(CareChatMessage message, String emoji)? onReact;
  final bool busyAction;
  final String? busyMessageId;
  final bool freeRxUnlocked;

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
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
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
                canReact: canReact,
                onReact: onReact,
                freeRxUnlocked: freeRxUnlocked,
                busyAction:
                    busyAction &&
                    (busyMessageId == null || busyMessageId == msg.id),
                onUnlockPrescription: onUnlockPrescription,
                onOpenMedia: onOpenMedia,
              ),
            ),
          )
          .toList(),
    );
  }
}
