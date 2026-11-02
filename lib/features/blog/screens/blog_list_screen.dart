import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/blog_card.dart';
import '../../../core/widgets/common.dart';
import '../../../models/content.dart';
import '../../../providers/app_providers.dart';

final blogCategoryProvider = StateProvider<String?>((ref) => null);

final blogListProvider = FutureProvider.autoDispose<List<BlogPost>>((ref) {
  final category = ref.watch(blogCategoryProvider);
  return ref.read(contentServiceProvider).fetchBlogPosts(category: category);
});

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  static const _categories = [
    ('All', null),
    ('Dog Care', 'dog-care'),
    ('Cat Care', 'cat-care'),
    ('Cattle & Dairy', 'cattle'),
    ('Poultry', 'poultry'),
    ('Goat & Sheep', 'goat'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(blogListProvider);
    final category = ref.watch(blogCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Insights & Care Blog',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final c in _categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.$1),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: category == c.$2
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: category == c.$2
                              ? AppColors.primaryDeep
                              : AppColors.textPrimary,
                        ),
                        selected: category == c.$2,
                        backgroundColor: AppColors.primaryWashFaint,
                        selectedColor: AppColors.primaryWash,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: category == c.$2
                                ? AppColors.primaryDeep
                                : AppColors.borderWarm,
                          ),
                        ),
                        onSelected: (_) {
                          AppHaptics.selection();
                          ref.read(blogCategoryProvider.notifier).state =
                              c.$2;
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderWarmSoft),
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: AppEmptyState(
                        icon: Icons.article_outlined,
                        title: 'No articles in this category yet',
                        description:
                            'Our veterinary editorial team is preparing fresh clinical guides and care stories for this topic.',
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(blogListProvider);
                    await ref.read(blogListProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => BlogCard(
                      post: posts[i],
                      onTap: () {
                        AppHaptics.light();
                        context.push('/blog/${posts[i].slug}');
                      },
                    ),
                  ),
                );
              },
              loading: () => const Center(child: AppLoader.large()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load articles',
                    description: e.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(blogListProvider),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
