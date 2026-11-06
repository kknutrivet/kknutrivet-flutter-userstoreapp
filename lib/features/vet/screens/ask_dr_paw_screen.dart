import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/markdown_view.dart';
import '../../../models/product.dart';
import '../../../providers/app_providers.dart';

class AskDrPawScreen extends ConsumerStatefulWidget {
  const AskDrPawScreen({
    super.key,
    this.currentProduct,
    this.initialQuestion,
    this.animalType,
  });

  final Product? currentProduct;
  final String? initialQuestion;
  final String? animalType;

  @override
  ConsumerState<AskDrPawScreen> createState() => _AskDrPawScreenState();
}

class _AskDrPawScreenState extends ConsumerState<AskDrPawScreen> {
  static const _animals = ['Dog', 'Cat', 'Cattle', 'Poultry', 'Goat/Sheep'];
  static const _languages = [
    'English',
    'हिन्दी',
    'বাংলা',
    'తెలుగు',
    'தமிழ்',
    'ଓଡ଼ିଆ'
  ];

  static const _starterPrompts = [
    'My dog is vomiting and not eating, what should I do?',
    'Where is my latest order and tracking details?',
    'Do you have alternatives for Bravecto or Liv-52?',
    'What is the best weight gain feed for dairy cattle?',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  String? _animal = 'Dog';
  String _language = 'English';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logDrPawChatStarted();

    if (widget.animalType != null && widget.animalType!.isNotEmpty) {
      _animal = widget.animalType;
    } else if (widget.currentProduct != null &&
        widget.currentProduct!.animalTypes.isNotEmpty) {
      _animal = widget.currentProduct!.animalTypes.first;
    }

    if (widget.initialQuestion != null && widget.initialQuestion!.trim().isNotEmpty) {
      final question = widget.initialQuestion!.trim();
      _messages.add(_ChatMessage(role: 'user', content: question));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(question, isInitial: true);
      });
    } else if (widget.currentProduct != null) {
      _messages.add(_ChatMessage(
        role: 'assistant',
        content:
            'Hello! I am **Dr. Paw**, your AI pet companion. 🐾\n\nI can help you with dosage, administration, animal safety, active ingredients, or alternatives for **${widget.currentProduct!.name}**.',
      ));
    } else {
      _messages.add(const _ChatMessage(
        role: 'assistant',
        content:
            'Hello! I am **Dr. Paw**, your AI veterinary assistant. Choose your animal above, describe what symptoms or questions you have, and I will share immediate veterinary insights.\n\n*⚠️ Note: Urgent, worsening, or critical symptoms always require a qualified veterinary doctor.*',
      ));
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
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
        _messages.add(_ChatMessage(role: 'user', content: question));
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
      final history = _messages
          .where((m) => m.content.isNotEmpty)
          .map((m) => {'role': m.role, 'text': m.content})
          .toList();

      final reply = await ref.read(aiServiceProvider).ask(
            question: question,
            animalType: _animal,
            language: _language,
            currentProduct: widget.currentProduct,
            history: history,
          );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: reply.content,
          productIds: reply.productIds,
          suggestedQuestions: reply.suggestedQuestions,
        ));
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: e.toString()));
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _resetChat() {
    AppHaptics.light();
    setState(() {
      _messages.clear();
      _messages.add(const _ChatMessage(
        role: 'assistant',
        content:
            'Hello! I am **Dr. Paw**, your AI veterinary assistant. Choose your animal above, describe what symptoms or questions you have, and I will share immediate veterinary insights.\n\n*⚠️ Note: Urgent, worsening, or critical symptoms always require a qualified veterinary doctor.*',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Dr. Paw',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
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
                  if (widget.currentProduct != null)
                    Text(
                      '🛒 ${widget.currentProduct!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    const Text(
                      'Animal-care guidance',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF52645C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(17),
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
                  DropdownMenuItem(value: 'English', child: Text('English')),
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
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: _resetChat,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 13,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_messages.length > 1) ...[
            _selectorBar(),
            const Divider(height: 1, color: AppColors.borderWarmSoft),
          ],
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length <= 1 ? 1 : _messages.length,
              itemBuilder: (context, i) {
                if (_messages.length <= 1) {
                  return _starterPromptCards();
                }
                final message = _messages[i];
                return _MessageBubble(
                  message: message,
                  onQuestionTap: _send,
                  onProductTap: (id) => context.push('/product/$id'),
                );
              },
            ),
          ),
          if (_sending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Dr. Paw is typing...',
                          style: TextStyle(
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
          _inputBar(),
        ],
      ),
    );
  }

  Widget _starterPromptCards() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE5EDE8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/dr-paw-genz-avatar.webp'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F5ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'WELCOME TO DR. PAW! 🐾',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFF0A6847),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Your 24/7 Veterinary Pet Companion',
                  style: AppTheme.serif(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'I’m trained on animal clinical care, KK Nutrivet products, live order tracking, and live veterinary triage. Ask me anything!',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                // 2x2 capabilities grid
                Row(
                  children: [
                    Expanded(
                      child: _capabilityCard(
                        Icons.healing_outlined,
                        const Color(0xFF0A6847),
                        'Symptom Checker',
                        'Vomiting, itching, fever, dosage guidance',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _capabilityCard(
                        Icons.local_shipping_outlined,
                        const Color(0xFF2563EB),
                        'Order Tracking',
                        'Live package status & 1-tap re-ordering',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _capabilityCard(
                        Icons.sync_alt_rounded,
                        const Color(0xFFD97706),
                        'Brand Equivalents',
                        'Active formulas for Bravecto, Liv-52',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _capabilityCard(
                        Icons.video_call_outlined,
                        const Color(0xFF7C3AED),
                        'Doctor Consultation',
                        'Free initial chat · paid services quoted separately',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'SELECT YOUR PET TO GET TAILORED ADVICE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _animalSelectCard('Dog', 'assets/images/animal-categories/dog.webp'),
              const SizedBox(width: 8),
              _animalSelectCard('Cat', 'assets/images/animal-categories/cat.webp'),
              const SizedBox(width: 8),
              _animalSelectCard('Cattle', 'assets/images/animal-categories/cattle.webp'),
              const SizedBox(width: 8),
              _animalSelectCard('Poultry', 'assets/images/animal-categories/poultry.webp'),
              const SizedBox(width: 8),
              _animalSelectCard('Goat/Sheep', 'assets/images/animal-categories/goat.webp'),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'POPULAR FIRST QUESTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ..._starterPrompts.map((q) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _send(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5EDE8)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              q,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: AppColors.primaryDeep),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _capabilityCard(
      IconData icon, Color color, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAF1EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              height: 1.3,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animalSelectCard(String animalName, String asset) {
    final selected = _animal == animalName;
    return Expanded(
      child: Material(
        color: selected ? const Color(0xFFE9F5EF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            AppHaptics.selection();
            setState(() => _animal = animalName);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.primaryDeep
                    : const Color(0xFFE5EDE8),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Image.asset(
                  asset,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets_rounded,
                    size: 24,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  animalName,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? AppColors.primaryDeep
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _animals.map((a) {
                final selected = _animal == a;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(a),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                    ),
                    selected: selected,
                    backgroundColor: AppColors.primaryWashFaint,
                    selectedColor: AppColors.primaryWash,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primaryDeep
                            : AppColors.borderWarm,
                      ),
                    ),
                    onSelected: (_) {
                      AppHaptics.selection();
                      setState(() => _animal = a);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _languages.map((l) {
                final selected = _language == l;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(l),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.catRailHeading
                          : AppColors.textSecondary,
                    ),
                    selected: selected,
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.homeLavender,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? AppColors.accentViolet
                            : AppColors.borderWarmSoft,
                      ),
                    ),
                    onSelected: (_) {
                      AppHaptics.selection();
                      setState(() => _language = l);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECE9))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE3E0)),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF5A615F),
                size: 20,
              ),
              onPressed: () {
                AppHaptics.light();
                context.push('/scan');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAF7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDCEEE3)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about pet care, orders, doctor consult...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryDeep,
                      padding: const EdgeInsets.all(8),
                    ),
                    onPressed: () => _send(_controller.text),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.content,
    this.productIds = const [],
    this.suggestedQuestions = const [],
  });
  final String role;
  final String content;
  final List<String> productIds;
  final List<String> suggestedQuestions;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onQuestionTap,
    required this.onProductTap,
  });

  final _ChatMessage message;
  final void Function(String) onQuestionTap;
  final void Function(String) onProductTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryDeep : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.borderWarm),
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
                ...message.suggestedQuestions.map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: InkWell(
                      onTap: () => onQuestionTap(q),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryWash,
                          borderRadius: BorderRadius.circular(10),
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
                ),
              ],
              if (message.productIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Recommended products:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                ...message.productIds.map(
                  (id) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => onProductTap(id),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryWashFaint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderWarm),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 15,
                              color: AppColors.primaryDeep,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'View recommended product',
                                style: TextStyle(
                                  color: AppColors.primaryDeep,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: AppColors.primaryDeep,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
