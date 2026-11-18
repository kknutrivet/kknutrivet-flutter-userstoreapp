import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../models/consultation.dart';
import '../../../providers/app_providers.dart';
import '../../checkout/screens/cashfree_checkout_screen.dart';
import '../widgets/care_chat_thread_widgets.dart';
import '../widgets/consultation_prescription_and_review.dart';

final consultationDetailProvider = FutureProvider.autoDispose
    .family<ConsultationBooking, String>((ref, id) async {
      final all = await ref
          .read(consultationServiceProvider)
          .fetchMyConsultations();
      return all.firstWhere(
        (b) => b.id == id,
        orElse: () => throw ApiException('Consultation not found.'),
      );
    });

final careChatMessagesProvider = FutureProvider.autoDispose
    .family<CareChatPage, String>((ref, id) {
      return ref.read(consultationServiceProvider).fetchChatPage(id);
    });

class ConsultationDetailScreen extends ConsumerStatefulWidget {
  const ConsultationDetailScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState
    extends ConsumerState<ConsultationDetailScreen> with WidgetsBindingObserver {
  final Map<String, CareChatMessage> _history = {};
  bool _loadingEarlier = false;
  bool? _olderHasMore;
  bool _refreshing = false;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reviewCommentController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer;
  bool _sending = false;
  bool _uploadingMedia = false;
  bool _busyAction = false;
  String? _busyPaymentMessageId;
  bool _submittingReview = false;
  bool _reviewSubmitted = false;
  int _selectedRating = 5;

  CareChatCoinStatus? _coinStatusOverride;
  bool _coinPacksExpanded = false;
  bool _confirmingCoinRecharge = false;
  int? _rechargingPackAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) return;
      _poll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _messageController.dispose();
    _reviewCommentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _poll();
  }

  Future<void> _poll() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try { await _refreshAll(); } catch (_) { /* Retry on next poll; UI exposes error. */ }
    finally { _refreshing = false; }
  }

  Future<void> _loadEarlier(List<CareChatMessage> messages) async {
    if (_loadingEarlier || messages.isEmpty) return;
    setState(() => _loadingEarlier = true);
    try {
      final page = await ref.read(consultationServiceProvider).fetchChatPage(widget.id, before: messages.first.createdAt.toUtc().toIso8601String());
      if (!mounted) return;
      setState(() {
        for (final message in [...messages, ...page.messages]) { _history[message.id] = message; }
        _olderHasMore = page.hasMore;
      });
    } catch (error) { if (mounted) showToast(error.toString(), isError: true); }
    finally { if (mounted) setState(() => _loadingEarlier = false); }
  }

  Future<void> _requestFollowUp() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Ask about this consultation'),
      content: TextField(controller: controller, maxLength: 2000, maxLines: 4, decoration: const InputDecoration(labelText: 'Your follow-up question')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Send request'))]));
    controller.dispose();
    if (!mounted || reason == null || reason.isEmpty) return;
    try { await ref.read(consultationServiceProvider).requestFollowUp(widget.id, reason); if (mounted) await _refreshAll(); }
    catch (error) { if (mounted) showToast(error.toString(), isError: true); }
  }

  Future<void> _refreshAll() async {
    ref.invalidate(consultationDetailProvider(widget.id));
    ref.invalidate(careChatMessagesProvider(widget.id));
    await Future.wait([
      ref.read(consultationDetailProvider(widget.id).future),
      ref.read(careChatMessagesProvider(widget.id).future),
    ]);
  }

  Future<void> _handleReaction(CareChatMessage message, String emoji) async {
    if (message.isSystem) return;
    final hasReacted =
        message.reactions.any((r) => r.emoji == emoji && r.mine);
    try {
      final updatedReactions = await ref
          .read(consultationServiceProvider)
          .toggleReaction(
            widget.id,
            message.id,
            emoji,
            remove: hasReacted,
          );
      if (!mounted) return;
      setState(() {
        _history[message.id] = message.copyWith(reactions: updatedReactions);
      });
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    }
  }

  CareChatCoinStatus? _currentCoinStatus([CareChatPage? page]) =>
      _coinStatusOverride ??
      page?.coinStatus ??
      ref.read(careChatMessagesProvider(widget.id)).valueOrNull?.coinStatus;

  void _applyCoinStatusMap(dynamic raw) {
    if (raw is! Map || !mounted) return;
    final parsed = CareChatCoinStatus.fromJson(
      Map<String, dynamic>.from(raw),
    );
    setState(() => _coinStatusOverride = parsed);
  }

  bool _preflightCoinsBlocked() {
    final coinStatus = _currentCoinStatus();
    if (coinStatus == null || !coinStatus.isActiveForCustomer) return false;
    if (coinStatus.waitingLockActive) {
      showToast(
        'Waiting for a doctor to accept your consultation before sending more messages.',
        isError: true,
      );
      return true;
    }
    if (coinStatus.outOfCoins) {
      setState(() => _coinPacksExpanded = true);
      showToast(
        'Out of KK Coins — choose a recharge pack above to send your message.',
        isError: true,
      );
      return true;
    }
    return false;
  }

  void _handleChatSendError(Object error) {
    if (error is ApiException) {
      final rawCoin = error.meta?['coinStatus'];
      if (rawCoin is Map) {
        final parsed = CareChatCoinStatus.fromJson(
          Map<String, dynamic>.from(rawCoin),
        );
        setState(() {
          _coinStatusOverride = parsed;
          if (error.code == 'INSUFFICIENT_KK_COINS') {
            _coinPacksExpanded = true;
          }
        });
      } else if (error.code == 'INSUFFICIENT_KK_COINS') {
        setState(() => _coinPacksExpanded = true);
      }
    }
    showToast(error.toString(), isError: true);
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty ||
        _sending ||
        ref.read(careChatMessagesProvider(widget.id)).valueOrNull?.canMessage !=
            true) {
      return;
    }
    if (_preflightCoinsBlocked()) return;
    AppHaptics.light();
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(consultationServiceProvider)
          .sendChatMessageResult(widget.id, body: text, messageType: 'TEXT');
      if (!mounted) return;
      if (_messageController.text.trim() == text) _messageController.clear();
      if (result.coinStatus != null) {
        setState(() => _coinStatusOverride = result.coinStatus);
      }
      ref.invalidate(careChatMessagesProvider(widget.id));
    } catch (e) {
      if (!mounted) return;
      _handleChatSendError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendMedia() async {
    if (_uploadingMedia || _sending) return;
    if (_preflightCoinsBlocked()) return;
    AppHaptics.selection();

    final choice = await showCareChatMediaPickerSheet(context);
    if (choice == null || !mounted) return;

    final picker = ImagePicker();
    XFile? picked;
    String messageType = 'IMAGE';
    String defaultBody = 'Shared a photo';

    switch (choice) {
      case CareChatMediaChoice.cameraPhoto:
        picked = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 82,
          maxWidth: 1600,
        );
        messageType = 'IMAGE';
        defaultBody = 'Shared a photo';
        break;
      case CareChatMediaChoice.cameraVideo:
        picked = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 2),
        );
        messageType = 'VIDEO';
        defaultBody = 'Shared a video';
        break;
      case CareChatMediaChoice.galleryPhoto:
        picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 82,
          maxWidth: 1600,
        );
        messageType = 'IMAGE';
        defaultBody = 'Shared a photo';
        break;
      case CareChatMediaChoice.galleryVideo:
        picked = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
        messageType = 'VIDEO';
        defaultBody = 'Shared a video';
        break;
    }

    if (picked == null) return;

    if (messageType == 'VIDEO') {
      final fileLength = await picked.length();
      if (fileLength > 25 * 1024 * 1024) {
        showToast('Please choose a video under 25 MB', isError: true);
        return;
      }
    }

    setState(() => _uploadingMedia = true);
    try {
      final mediaUrl = await ref
          .read(uploadServiceProvider)
          .uploadFile(picked.path, purpose: 'care-chat');
      final result = await ref
          .read(consultationServiceProvider)
          .sendChatMessageResult(
            widget.id,
            body: defaultBody,
            messageType: messageType,
            mediaUrl: mediaUrl,
          );
      if (!mounted) return;
      if (result.coinStatus != null) {
        setState(() => _coinStatusOverride = result.coinStatus);
      }
      ref.invalidate(careChatMessagesProvider(widget.id));
      showToast(messageType == 'VIDEO' ? 'Video sent' : 'Photo sent');
    } catch (e) {
      if (!mounted) return;
      _handleChatSendError(e);
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  Future<void> _joinVideoCall(ConsultationBooking booking) async {
    if (_busyAction) return;
    AppHaptics.light();
    setState(() => _busyAction = true);
    try {
      String? url = booking.meetingUrl;
      if (url == null || url.isEmpty) {
        final data = await ref
            .read(consultationServiceProvider)
            .joinCall(booking.id);
        url = (data['roomUrl'] ?? data['url'] ?? data['meetingUrl'])
            ?.toString();
      }
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      showToast('Video room will open once assigned by the veterinarian.');
    } catch (e) {
      if (!mounted) return;
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      showToast('Invalid link', isError: true);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<String?> _promptPhoneNumberForPayment() async {
    final initialPhone = ref.read(authProvider).valueOrNull?.phone ?? '';
    final controller = TextEditingController(text: initialPhone);
    String? errorText;
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enter mobile number for payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cashfree requires a valid 10-digit Indian mobile number to open the payment gateway.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 15,
                decoration: InputDecoration(
                  labelText: 'Mobile number',
                  hintText: '10-digit mobile number',
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final digits = controller.text.replaceAll(RegExp(r'\D'), '');
                final normalized = digits.length > 10
                    ? digits.substring(digits.length - 10)
                    : digits;
                if (normalized.length != 10) {
                  setDialogState(
                    () => errorText = 'Enter a valid 10-digit mobile number',
                  );
                  return;
                }
                Navigator.pop(ctx, normalized);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return phone;
  }

  Future<Map<String, dynamic>?> _createPaymentWithPhoneFallback(
    String bookingId, {
    String? prescriptionMessageId,
    bool video = false,
    String? purpose,
    int? coinPackAmount,
  }) async {
    final service = ref.read(consultationServiceProvider);
    try {
      return await service.createPayment(
        bookingId,
        prescriptionMessageId: prescriptionMessageId,
        video: video,
        purpose: purpose,
        coinPackAmount: coinPackAmount,
      );
    } on ApiException catch (e) {
      if (e.code != 'MISSING_CUSTOMER_PHONE' || !mounted) rethrow;
      final phone = await _promptPhoneNumberForPayment();
      if (!mounted || phone == null) return null;
      return service.createPayment(
        bookingId,
        prescriptionMessageId: prescriptionMessageId,
        video: video,
        purpose: purpose,
        coinPackAmount: coinPackAmount,
        customerPhone: phone,
        skipPhoneVerification: true,
      );
    }
  }

  Future<void> _startCoinRecharge(
    ConsultationBooking booking,
    CareCoinRechargePack pack,
  ) async {
    if (_busyAction || _rechargingPackAmount != null) return;
    AppHaptics.selection();
    setState(() => _rechargingPackAmount = pack.amount);
    try {
      final session = await _createPaymentWithPhoneFallback(
        booking.id,
        purpose: 'COIN_RECHARGE',
        coinPackAmount: pack.amount,
      );
      if (!mounted || session == null) return;
      final paymentSessionId = session['paymentSessionId']?.toString();
      if (paymentSessionId == null || paymentSessionId.isEmpty) {
        throw ApiException('Could not open the payment gateway.');
      }
      final orderId = session['orderId']?.toString() ?? booking.id;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CashfreeCheckoutScreen(
            paymentSessionId: paymentSessionId,
            orderId: orderId,
            mode: session['mode']?.toString() ?? 'production',
            returnUrlContains: '/care-chat',
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _rechargingPackAmount = null;
        _confirmingCoinRecharge = true;
      });
      final service = ref.read(consultationServiceProvider);
      Map<String, dynamic>? result;
      for (int attempt = 0; attempt < 4; attempt++) {
        if (!mounted) return;
        result = await service.verifyBooking(
          booking.id,
          orderId: orderId,
          coinRecharge: true,
        );
        if (result['paid'] == true) break;
        final status = result['status']?.toString().toUpperCase();
        if (status == 'FAILED' ||
            status == 'USER_DROPPED' ||
            status == 'CANCELLED' ||
            status == 'VOID') {
          break;
        }
        if (attempt < 3) {
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }
      }
      if (!mounted) return;
      if (result?['paid'] == true) {
        _applyCoinStatusMap(result?['coinStatus']);
        setState(() => _coinPacksExpanded = false);
        final credited = result?['coinsCredited'];
        final newBalance = result?['newBalance'];
        showToast(
          credited != null
              ? 'Added $credited KK Coins! Balance: ${newBalance ?? ''}'
              : 'KK Coins recharged!',
        );
        await _refreshAll();
      } else {
        showToast(
          'Your KK Coins recharge was not completed. No coins were deducted.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _rechargingPackAmount = null;
          _confirmingCoinRecharge = false;
        });
      }
    }
  }

  Future<void> _payOrUnlock(ConsultationBooking booking, {String? prescriptionMessageId, bool video = false}) async {
    if (_busyAction) return;
    AppHaptics.selection();
    setState(() {
      _busyAction = true;
      _busyPaymentMessageId = prescriptionMessageId ?? (video ? 'video' : 'booking');
    });
    try {
      final service = ref.read(consultationServiceProvider);
      if (booking.isFreeFollowUp) {
        await service.activateFreeFollowUp(booking.id);
        showToast('Free follow-up confirmed');
        ref.invalidate(consultationDetailProvider(widget.id));
        return;
      }

      final session = await _createPaymentWithPhoneFallback(
        booking.id,
        prescriptionMessageId: prescriptionMessageId,
        video: video,
      );
      if (!mounted || session == null) return;
      final paymentSessionId = session['paymentSessionId']?.toString();
      if (paymentSessionId == null || paymentSessionId.isEmpty) {
        throw ApiException('Could not open the payment gateway.');
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CashfreeCheckoutScreen(
            paymentSessionId: paymentSessionId,
            orderId: session['orderId']?.toString() ?? booking.id,
            mode: session['mode']?.toString() ?? 'production',
            returnUrlContains:
                prescriptionMessageId != null || video ? '/care-chat' : '/consultations/payment-return?booking_id=${booking.id}',
          ),
        ),
      );
      if (!mounted) return;
      final result = await service.verifyBooking(booking.id, orderId: session['orderId']?.toString(), prescriptionMessageId: prescriptionMessageId, video: video);
      if (result['paid'] != true) {
        showToast(
          'Payment is not confirmed yet. Your access updates after verification; refresh before paying again.',
          isError: true,
        );
        return;
      }
      showToast('Payment verified');
      await _refreshAll();
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busyAction = false;
          _busyPaymentMessageId = null;
        });
      }
    }
  }

  Future<void> _submitInlineReview(ConsultationBooking booking) async {
    if (_submittingReview) return;
    AppHaptics.light();
    setState(() => _submittingReview = true);
    try {
      await ref
          .read(consultationServiceProvider)
          .submitReview(
            booking.id,
            rating: _selectedRating,
            comment: _reviewCommentController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _reviewSubmitted = true);
      ref.invalidate(consultationDetailProvider(widget.id));
      showToast('Thank you for rating your consultation!');
    } catch (e) {
      if (!mounted) return;
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CareChatPage>>(careChatMessagesProvider(widget.id), (
      _,
      next,
    ) {
      next.whenData((p) {
        if (!mounted) return;
        setState(() => _coinStatusOverride = p.coinStatus);
      });
    });

    final bookingAsync = ref.watch(consultationDetailProvider(widget.id));
    final messagesAsync = ref.watch(careChatMessagesProvider(widget.id));
    final booking = bookingAsync.valueOrNull;
    final page = messagesAsync.valueOrNull;
    final effectiveCoinStatus = _coinStatusOverride ?? page?.coinStatus;
    final coinsEnabled =
        (page?.careChatCoinsEnabled == true) ||
        (effectiveCoinStatus?.enabled ?? false);
    final coinsActive = effectiveCoinStatus?.isActiveForCustomer ?? false;
    final waitingLockActive =
        coinsActive && (effectiveCoinStatus?.waitingLockActive ?? false);
    final freeRxUnlocked = coinsEnabled || (page?.prescriptionUnlocked == true);

    final merged = <String, CareChatMessage>{};
    for (final message in page?.messages ?? <CareChatMessage>[]) {
      merged[message.id] = message;
    }
    merged.addAll(_history);

    // Ensure system messages for doctor assignment and video consultation recommendation
    // are visible even if omitted by older message pagination or backend sync.
    if (booking != null && booking.isDoctorAssigned) {
      final hasDoctorAssignedMessage = merged.values.any(
        (m) => m.body.contains('has been assigned to your care chat'),
      );
      if (!hasDoctorAssignedMessage) {
        final assignedAt = booking.careChatAssignedAt ?? booking.createdAt;
        final synthetic = CareChatMessage(
          id: 'sys_doctor_assigned_${booking.id}',
          senderId: 'system',
          senderRole: 'SYSTEM',
          senderName: 'System',
          messageType: 'TEXT',
          body: '${booking.doctorDisplayName} has been assigned to your care chat.',
          createdAt: assignedAt,
        );
        merged[synthetic.id] = synthetic;
      }
    }

    if (booking != null && page?.videoEligible == true) {
      final hasVideoReqMessage = merged.values.any(
        (m) =>
            m.messageType == 'VIDEO_REQUEST' ||
            m.body.contains('recommends a video consultation'),
      );
      if (!hasVideoReqMessage) {
        final syntheticVideo = CareChatMessage(
          id: 'sys_video_req_${booking.id}',
          senderId: 'system',
          senderRole: 'SYSTEM',
          senderName: 'System',
          messageType: 'VIDEO_REQUEST',
          body: coinsEnabled
              ? 'Your doctor recommends a 1-on-1 video consultation. Review the video fee and pay to join.'
              : 'Your doctor recommends a video consultation. Review the video fee and pay to continue. The prescription is included with paid video.',
          createdAt: (booking.careChatAssignedAt ?? booking.createdAt).add(
            const Duration(seconds: 1),
          ),
        );
        merged[syntheticVideo.id] = syntheticVideo;
      }
    }

    final messages = merged.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final canMessage = page?.canMessage == true;

    final hasVetReplied = messages.any(
      (m) =>
          m.senderRole.toUpperCase() == 'VET' ||
          m.senderRole.toUpperCase() == 'ADMIN',
    );
    final isWaitingForReply =
        !hasVetReplied && (booking?.status.toUpperCase() != 'COMPLETED');

    return Scaffold(
      backgroundColor: AppColors.primaryWashFaint,
      appBar: ConsultationDetailAppBar(
        booking: booking,
        busyAction: _busyAction,
        videoAvailable: page?.videoAvailable == true,
        videoEligible: page?.videoEligible == true,
        videoAmount: page?.videoAmount,
        careChatAssignedAt:
            page?.careChatAssignedAt ?? booking?.careChatAssignedAt,
        onJoinVideoCall: _joinVideoCall,
        onPayVideoCall:
            booking != null ? () => _payOrUnlock(booking, video: true) : null,
      ),
      body: bookingAsync.when(
        data: (bookingData) {
          final isCompleted = bookingData.status.toUpperCase() == 'COMPLETED';
          final followUpUntil = page?.followUpUntil;
          final lockedPrescription =
              bookingData.prescriptionLocked && !freeRxUnlocked;
          return Column(
            children: [
              if (_busyAction || _uploadingMedia || _sending)
                const LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              if (isWaitingForReply && canMessage && !coinsActive)
                const CareChatWaitingRuleBanner(),
              if (page?.videoEligible == true && page?.videoAvailable != true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FAF6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF2E7D59),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.videocam_rounded,
                          size: 20,
                          color: Color(0xFF1E5B40),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Video requested · awaiting payment',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E5B40),
                                ),
                              ),
                              Text(
                                page?.videoAmount == null
                                    ? 'Review video consultation fee to continue'
                                    : coinsEnabled
                                    ? 'Pay ${formatPrice(page!.videoAmount!)} to unlock 1-on-1 video call'
                                    : 'Pay ₹${page!.videoAmount} to unlock video call & prescription',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E5B40),
                            disabledBackgroundColor:
                                const Color(0xFF1E5B40).withValues(alpha: 0.65),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _busyAction
                              ? null
                              : () => _payOrUnlock(bookingData, video: true),
                          child: _busyAction && _busyPaymentMessageId == 'video'
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 13,
                                      height: 13,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Opening…',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  page?.videoAmount == null
                                      ? 'Review'
                                      : 'Pay ₹${page!.videoAmount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (bookingData.status == 'HOLD' ||
                  bookingData.status == 'PENDING_PAYMENT')
                CareChatPaymentBanner(
                  booking: bookingData,
                  busyAction: _busyAction,
                  onPayOrUnlock: () => _payOrUnlock(bookingData),
                ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshAll,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                    children: [
                      if (messagesAsync.hasError)
                        TextButton(
                          onPressed: _refreshAll,
                          child: const Text(
                            'Could not refresh messages · Retry',
                          ),
                        ),
                      if ((_olderHasMore ?? page?.hasMore) == true)
                        TextButton(
                          onPressed: _loadingEarlier
                              ? null
                              : () => _loadEarlier(messages),
                          child: Text(
                            _loadingEarlier
                                ? 'Loading…'
                                : 'Load earlier messages',
                          ),
                        ),
                      CareIntroCard(booking: bookingData),
                      const SizedBox(height: 12),
                      CareChatMessagesSection(
                        isLoading: messagesAsync.isLoading,
                        messages: messages,
                        booking: bookingData,
                        canReact: canMessage,
                        onReact: _handleReaction,
                        busyAction: _busyAction,
                        busyMessageId: _busyPaymentMessageId,
                        freeRxUnlocked: freeRxUnlocked,
                        onUnlockPrescription: (message) => _payOrUnlock(
                          bookingData,
                          prescriptionMessageId: message.id,
                        ),
                        onOpenMedia: _openExternalUrl,
                      ),
                      if (bookingData.prescription != null &&
                          !messages.any(
                            (m) => m.messageType == 'PRESCRIPTION',
                          )) ...[
                        const SizedBox(height: 8),
                        ConsultationPrescriptionCard(
                          prescription: bookingData.prescription!,
                          locked: lockedPrescription,
                          unlockAmount: bookingData.unlockAmount,
                          busyAction:
                              _busyAction &&
                              (_busyPaymentMessageId == null ||
                                  _busyPaymentMessageId == 'booking'),
                          onDownloadPdf: bookingData.prescription!.pdfUrl != null
                              ? () => _openExternalUrl(
                                  bookingData.prescription!.pdfUrl!,
                                )
                              : null,
                          onOrderMedicines: () {
                            AppHaptics.light();
                            final slug = bookingData
                                .prescription!
                                .items
                                .firstOrNull
                                ?.productSlug;
                            context.push(
                              slug != null ? '/products/$slug' : '/products',
                            );
                          },
                          onUnlock: () => _payOrUnlock(bookingData),
                        ),
                      ],
                      if (isCompleted) ...[
                        const SizedBox(height: 14),
                        RateConsultationCard(
                          existingRating: bookingData.reviewRating,
                          existingComment: bookingData.reviewComment,
                          submitted: _reviewSubmitted,
                          selectedRating: _selectedRating,
                          commentController: _reviewCommentController,
                          submitting: _submittingReview,
                          onRatingChanged: (star) =>
                              setState(() => _selectedRating = star),
                          onSubmit: () => _submitInlineReview(bookingData),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_uploadingMedia)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: const Color(0xFFE8F5E9),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryDeep,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Uploading photo/video… please wait',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isCompleted && canMessage && followUpUntil != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  color: AppColors.primaryWash,
                  child: Text(
                    'Consultation completed. Follow-up questions about this concern are welcome until '
                    '${formatDateTime(followUpUntil.toUtc().add(const Duration(hours: 5, minutes: 30)))} IST'
                    '${coinsActive && effectiveCoinStatus!.freeMessagesTotal > 0 ? " · First ${effectiveCoinStatus.freeMessagesTotal} follow-up message${effectiveCoinStatus.freeMessagesTotal == 1 ? '' : 's'} free" : ""}.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDeep,
                      height: 1.35,
                    ),
                  ),
                ),
              if (canMessage)
                CareChatComposer(
                  messageController: _messageController,
                  sending: _sending,
                  uploadingMedia: _uploadingMedia,
                  onPickAndSendPhoto: _pickAndSendMedia,
                  onSendTextMessage: _sendTextMessage,
                  locked: waitingLockActive,
                  hintText: waitingLockActive
                      ? 'Waiting for a doctor to accept…'
                      : isCompleted
                      ? 'Ask a follow-up about this concern'
                      : 'Type your message…',
                  topBanner: coinsActive
                      ? CareChatCoinsBar(
                          coinStatus: effectiveCoinStatus!,
                          packsExpanded: _coinPacksExpanded,
                          confirmingRecharge: _confirmingCoinRecharge,
                          rechargingPackAmount: _rechargingPackAmount,
                          onTogglePacks: () => setState(
                            () => _coinPacksExpanded = !_coinPacksExpanded,
                          ),
                          onSelectPack: (pack) =>
                              _startCoinRecharge(bookingData, pack),
                        )
                      : null,
                )
              else
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          page == null
                              ? 'Checking conversation access…'
                              : page.followUpRequested
                              ? 'Follow-up awaiting care-team approval'
                              : 'This conversation is read-only. Your history is saved.',
                        ),
                        if (page?.bookingStatus == 'COMPLETED' &&
                            page?.followUpRequested == false)
                          TextButton(
                            onPressed: _requestFollowUp,
                            child: const Text('Request a follow-up'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(consultationDetailProvider(widget.id)),
        ),
      ),
    );
  }
}
