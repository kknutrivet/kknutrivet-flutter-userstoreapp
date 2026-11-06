import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/markdown_view.dart';
import '../../../models/chat.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

/// Opens the Dr. Paw Pet Companion modal bottom sheet preloaded with [product]
/// and an optional [initialQuestion], matching the web app's `openProductCompanion`.
Future<void> showDrPawCompanionSheet(
  BuildContext context, {
  required Product product,
  String? initialQuestion,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) => DrPawCompanionSheet(
      product: product,
      initialQuestion: initialQuestion,
    ),
  );
}

class DrPawCompanionSheet extends ConsumerStatefulWidget {
  const DrPawCompanionSheet({
    super.key,
    required this.product,
    this.initialQuestion,
  });

  final Product product;
  final String? initialQuestion;

  @override
  ConsumerState<DrPawCompanionSheet> createState() => _DrPawCompanionSheetState();
}

class _DrPawCompanionSheetState extends ConsumerState<DrPawCompanionSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String _language = 'English';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logDrPawChatStarted();

    if (widget.initialQuestion != null && widget.initialQuestion!.trim().isNotEmpty) {
      final question = widget.initialQuestion!.trim();
      _messages.add(ChatMessage(role: 'user', content: question));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(question, isInitial: true);
      });
    } else {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content:
              'Hello! I am **Dr. Paw**, your AI pet companion. 🐾\n\nI can help you with dosage, administration, animal safety, active ingredients, or alternatives for **${widget.product.name}**.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send(String text, {bool isInitial = false}) async {
    final question = text.trim();
    if (question.isEmpty || (_sending && !isInitial)) return;

    AppHaptics.light();
    _controller.clear();

    if (!isInitial) {
      setState(() {
        _messages.add(ChatMessage(role: 'user', content: question));
        _sending = true;
      });
    } else {
      setState(() {
        _sending = true;
      });
    }

    AnalyticsService.instance.logDrPawMessageSent(
      messageCount: _messages.where((m) => m.role == 'user').length,
    );
    _scrollToBottom();

    try {
      final animal = widget.product.animalTypes.isNotEmpty
          ? widget.product.animalTypes.first
          : 'Dog';

      final history = _messages
          .where((m) => m.content.isNotEmpty)
          .map((m) => {'role': m.role, 'text': m.content})
          .toList();

      final reply = await ref.read(aiServiceProvider).ask(
            question: question,
            animalType: animal,
            language: _language,
            currentProduct: widget.product,
            history: history,
          );

      if (!mounted) return;
      setState(() {
        _messages.add(reply);
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content:
                'I am having trouble answering right now. Please try again or tap **Reset**.',
          ),
        );
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _resetChat() {
    AppHaptics.light();
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content:
              'Hello! I am **Dr. Paw**, your AI pet companion. 🐾\n\nAsk me anything about **${widget.product.name}**.',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.product.animalTypes.isNotEmpty
        ? widget.product.animalTypes.first
        : 'my pet';
    final p = widget.product;

    final defaultPrompts = [
      'How to use ${p.name}?',
      'Is this safe for $animal?',
      'Active ingredients & clinical benefits',
      'Are there equivalent alternatives?',
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.homeCanvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.borderWarmSoft),
              ),
            ),
            child: Row(
              children: [
                // Avatar with online status dot
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCCEF5)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/dr-paw-genz-avatar.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.homeLavender,
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.accentViolet,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Title + Product Context
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Flexible(
                            child: Text(
                              'Dr. Paw',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF137333),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text(
                            '🛒 ',
                            style: TextStyle(fontSize: 10.5),
                          ),
                          Expanded(
                            child: Text(
                              widget.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Language dropdown
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _language,
                      isDense: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'English', child: Text('Eng')),
                        DropdownMenuItem(value: 'हिन्दी', child: Text('हिन्दी')),
                        DropdownMenuItem(value: 'বাংলা', child: Text('বাংলা')),
                        DropdownMenuItem(value: 'తెలుగు', child: Text('తెలుగు')),
                        DropdownMenuItem(value: 'தமிழ்', child: Text('தமிழ்')),
                        DropdownMenuItem(value: 'ଓଡ଼ିଆ', child: Text('ଓଡ଼ିଆ')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _language = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Reset chat
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Reset chat',
                  color: AppColors.textSecondary,
                  onPressed: _resetChat,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'Close Dr. Paw',
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final message = _messages[i];
                final isUser = message.role == 'user';
                final isLast = i == _messages.length - 1;

                return Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.84,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primaryDeep : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                          border: isUser
                              ? null
                              : Border.all(color: AppColors.borderWarm),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isUser)
                              Text(
                                message.content,
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1.35,
                                  fontSize: 13.5,
                                ),
                              )
                            else ...[
                              MarkdownView(message.content),
                              if (message.suggestedQuestions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Suggested follow-ups:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final q in message.suggestedQuestions)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: InkWell(
                                      onTap: () => _send(q),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryWash,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 13,
                                              color: AppColors.primaryDeep,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                q,
                                                style: const TextStyle(
                                                  color: AppColors.primaryDeep,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Initial quick prompt chips if only welcome message is shown
                    if (_messages.length == 1 && !isUser && isLast) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final prompt in defaultPrompts)
                              InkWell(
                                onTap: () => _send(prompt),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.primaryWashDeep),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.cardShadow,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '💬 $prompt',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          // Sending typing indicator
          if (_sending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderWarm),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dr. Paw is analyzing ${widget.product.name}...',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar with keyboard insets
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              8 +
                  MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.borderWarmSoft),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.homeCanvas,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderWarm),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about ${widget.product.name}...',
                        hintStyle: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) => _send(v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  onPressed: _sending ? null : () => _send(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
