import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
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
  bool _submittingReview = false;
  bool _reviewSubmitted = false;
  int _selectedRating = 5;

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

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending || ref.read(careChatMessagesProvider(widget.id)).valueOrNull?.canMessage != true) return;
    AppHaptics.light();
    setState(() => _sending = true);
    try {
      await ref
          .read(consultationServiceProvider)
          .sendChatMessage(widget.id, body: text, messageType: 'TEXT');
      if (!mounted) return;
      if (_messageController.text.trim() == text) _messageController.clear();
      ref.invalidate(careChatMessagesProvider(widget.id));
    } catch (e) {
      if (!mounted) return;
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendPhoto() async {
    if (_uploadingMedia || _sending) return;
    AppHaptics.selection();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => _uploadingMedia = true);
    try {
      final mediaUrl = await ref
          .read(uploadServiceProvider)
          .uploadImage(picked.path, purpose: 'care-chat');
      await ref
          .read(consultationServiceProvider)
          .sendChatMessage(
            widget.id,
            body: 'Shared a photo',
            messageType: 'IMAGE',
            mediaUrl: mediaUrl,
          );
      if (!mounted) return;
      ref.invalidate(careChatMessagesProvider(widget.id));
      showToast('Photo sent');
    } catch (e) {
      if (!mounted) return;
      showToast(e.toString(), isError: true);
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

  Future<void> _payOrUnlock(ConsultationBooking booking, {String? prescriptionMessageId, bool video = false}) async {
    if (_busyAction) return;
    setState(() => _busyAction = true);
    try {
      final service = ref.read(consultationServiceProvider);
      if (booking.isFreeFollowUp) {
        await service.activateFreeFollowUp(booking.id);
        showToast('Free follow-up confirmed');
        ref.invalidate(consultationDetailProvider(widget.id));
        return;
      }

      final session = await service.createPayment(booking.id, prescriptionMessageId: prescriptionMessageId, video: video);
      if (!mounted) return;
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
      if (mounted) setState(() => _busyAction = false);
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
    final bookingAsync = ref.watch(consultationDetailProvider(widget.id));
    final messagesAsync = ref.watch(careChatMessagesProvider(widget.id));
    final booking = bookingAsync.valueOrNull;
    final page = messagesAsync.valueOrNull;
    final merged = {..._history};
    for (final message in page?.messages ?? <CareChatMessage>[]) { merged[message.id] = message; }
    final messages = merged.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
        data: (bookingData) => Column(
          children: [
            if (isWaitingForReply && canMessage) const CareChatWaitingRuleBanner(),
            if (page?.videoEligible == true && page?.videoAvailable != true)
              Padding(padding: const EdgeInsets.all(12), child: FilledButton.icon(
                onPressed: _busyAction ? null : () => _payOrUnlock(bookingData, video: true), icon: const Icon(Icons.videocam_outlined),
                label: Text(page?.videoAmount == null ? 'Review video consultation payment' : 'Pay ₹${page!.videoAmount} for video consultation'))),
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
                    if (messagesAsync.hasError) TextButton(onPressed: _refreshAll, child: const Text('Could not refresh messages · Retry')),
                    if ((_olderHasMore ?? page?.hasMore) == true)
                      TextButton(onPressed: _loadingEarlier ? null : () => _loadEarlier(messages), child: Text(_loadingEarlier ? 'Loading…' : 'Load earlier messages')),
                    CareIntroCard(booking: bookingData),
                    const SizedBox(height: 12),
                    CareChatMessagesSection(
                      isLoading: messagesAsync.isLoading,
                      messages: messages,
                      booking: bookingData,
                      onUnlockPrescription: (message) => _payOrUnlock(bookingData, prescriptionMessageId: message.id),
                      onOpenMedia: _openExternalUrl,
                    ),
                    if (bookingData.prescription != null && !messages.any((m) => m.messageType == 'PRESCRIPTION')) ...[
                      const SizedBox(height: 8),
                      ConsultationPrescriptionCard(
                        prescription: bookingData.prescription!,
                        locked: bookingData.prescriptionLocked,
                        unlockAmount: bookingData.unlockAmount,
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
                    if (bookingData.status.toUpperCase() == 'COMPLETED') ...[
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
            if (canMessage) CareChatComposer(
              messageController: _messageController,
              sending: _sending,
              uploadingMedia: _uploadingMedia,
              onPickAndSendPhoto: _pickAndSendPhoto,
              onSendTextMessage: _sendTextMessage,
            ) else SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(page == null ? 'Checking conversation access…' : page.followUpRequested ? 'Follow-up awaiting care-team approval' : 'This conversation is read-only. Your history is saved.'),
              if (page?.bookingStatus == 'COMPLETED' && page?.followUpRequested == false)
                TextButton(onPressed: _requestFollowUp, child: const Text('Request a follow-up')),
            ]))),
          ],
        ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(consultationDetailProvider(widget.id)),
        ),
      ),
    );
  }
}
