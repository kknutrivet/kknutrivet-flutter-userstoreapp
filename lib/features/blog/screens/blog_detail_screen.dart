import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/customer_error.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/markdown_view.dart';
import '../../../models/content.dart';
import '../../../providers/app_providers.dart';

final blogDetailProvider = FutureProvider.autoDispose.family<BlogPost, String>((
  ref,
  slug,
) {
  return ref.read(contentServiceProvider).fetchBlogPost(slug);
});

class BlogDetailScreen extends ConsumerWidget {
  const BlogDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(blogDetailProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      body: SafeArea(
        top: false,
        child: postAsync.when(
          data: (post) => CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 260,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background:
                      post.coverImage != null && post.coverImage!.isNotEmpty
                      ? AppNetworkImage(
                          imageUrl: post.coverImage!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primaryWashFaint,
                          child: const Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppCard(
                    variant: AppCardVariant.elevated,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.category != null &&
                            post.category!.isNotEmpty) ...[
                          AppBadge(
                            label: post.category!.toUpperCase(),
                            tone: AppBadgeTone.emerald,
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          post.title,
                          style: AppTheme.serif(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (post.authorName != null &&
                                post.authorName!.isNotEmpty) ...[
                              const Icon(
                                Icons.person_outline,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.authorName!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '·',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (post.publishedAt != null) ...[
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(post.publishedAt!),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Divider(
                          height: 28,
                          color: AppColors.borderWarmSoft,
                        ),
                        if (post.content != null && post.content!.isNotEmpty)
                          MarkdownView(
                            articleBodyWithoutDuplicateTitle(
                              post.content!,
                              post.title,
                            ),
                          )
                        else
                          const Text(
                            'No article content available.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: AppLoader.large()),
          error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to load article',
                  description: customerError(e, action: 'load this article'),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(blogDetailProvider(slug)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String articleBodyWithoutDuplicateTitle(String content, String title) {
  final lines = content.trimLeft().split('\n');
  if (lines.isEmpty) return content;
  final heading = RegExp(r'^#{1,6}\s+(.+?)\s*#*\s*$').firstMatch(lines.first);
  if (heading != null &&
      heading.group(1)!.trim().toLowerCase() == title.trim().toLowerCase()) {
    return lines.skip(1).join('\n').trimLeft();
  }
  return content;
}
