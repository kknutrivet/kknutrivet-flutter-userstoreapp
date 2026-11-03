import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/markdown_view.dart';

class _Insight {
  const _Insight(this.title, this.category, this.body, this.tone);
  final String title;
  final String category;
  final String body;
  final AppBadgeTone tone;
}

const _insights = [
  _Insight(
    'My dog is not eating - what should I do?',
    'Dogs',
    'A dog skipping one meal often isn\'t a worry, but watch closely. Start by offering a smaller, more tempting meal. Check for other signs: dullness, vomiting, loose stools, or pain. If your dog refuses food for more than 24 hours, or shows any of these signs, see a vet. In puppies and senior dogs, act faster - dehydration sets in quickly.',
    AppBadgeTone.amber,
  ),
  _Insight(
    'Recognising early signs of vitamin & mineral deficiency in cattle',
    'Cattle',
    'Low intake of minerals shows up first as dull coat, reduced feed intake and poor growth. Watch for pica (licking walls, eating soil), stiff gait, and reduced milk yield in milking animals. A balanced mineral mixture and regular deworming prevent most of these problems. Confirm with your vet before adding supplements.',
    AppBadgeTone.emerald,
  ),
  _Insight(
    'Why is my cat losing weight?',
    'Cats',
    'Gradual weight loss is easy to miss behind long fur. Weigh your cat monthly on a kitchen scale. Common causes: poor-quality food, dental pain, worms, or underlying disease. If weight loss continues for more than two weeks, book a vet consultation rather than waiting.',
    AppBadgeTone.peach,
  ),
  _Insight(
    'Bloat in dogs - a true emergency',
    'Large Breeds',
    'Bloat (gastric dilation-volvulus) is life-threatening and progresses fast. Signs: a swollen, hard belly, unproductive retching, restlessness, drooling. Do NOT wait and do not try to treat it at home - get to a vet immediately. Preventing it means avoiding vigorous exercise right after meals and not feeding one huge meal a day.',
    AppBadgeTone.coral,
  ),
  _Insight(
    'Foul-smelling ears or head shaking in dogs',
    'Ears & Skin',
    'Repeated head shaking and itchy ears usually mean an ear infection. Dog ears are warm and moist, which suits yeast and bacteria. Avoid poking anything into the ear canal. Wipe the visible part with a vet-recommended cleaner and have a vet check the cause - underlying allergies are common.',
    AppBadgeTone.violet,
  ),
  _Insight(
    'Feeding young calves - colostrum matters',
    'Livestock',
    'Colostrum in the first few hours of life provides the calf\'s only immunity. Give good-quality colostrum within 2-4 hours of birth. Thereafter, keep feeding times regular and milk temperature consistent. Sudden feed changes are the most common cause of calf scours.',
    AppBadgeTone.emerald,
  ),
];

class VetInsightsScreen extends ConsumerWidget {
  const VetInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Vet Clinical Insights',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          AppCard(
            variant: AppCardVariant.tinted,
            backgroundColor: AppColors.primaryWash,
            borderColor: AppColors.primaryWashDeep,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primaryDeep,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Practical clinical guidance curated by licensed veterinarians. Always confirm ongoing treatment with your local vet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final insight in _insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                variant: AppCardVariant.elevated,
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: AppBadge(
                    label: insight.category,
                    tone: insight.tone,
                  ),
                  title: Text(
                    insight.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownView(insight.body),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AppButton(
                          label: 'Explore Health Library',
                          icon: const Icon(Icons.menu_book_rounded, size: 14),
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.sm,
                          onPressed: () {
                            AppHaptics.light();
                            context.push('/diseases');
                          },
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Dr. Paw (AI)',
                          icon: const Icon(Icons.auto_awesome, size: 14),
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.sm,
                          onPressed: () {
                            AppHaptics.light();
                            context.push('/vet');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
  }
}
