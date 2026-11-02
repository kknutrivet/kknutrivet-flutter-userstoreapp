import 'package:flutter/material.dart';

import '../../models/content.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/haptics.dart';
import 'app_network_image.dart';

class BlogCard extends StatelessWidget {
  const BlogCard({super.key, required this.post, required this.onTap});
  final BlogPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderWarm),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AppNetworkImage(
                  imageUrl: post.coverImage,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.article_outlined,
                  placeholder: (_, _) => Container(color: AppColors.primaryWashFaint),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.primaryWashFaint,
                    child: const Icon(Icons.article_outlined,
                        color: AppColors.textTertiary),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.category != null && post.category!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryWash,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.category!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryDeep,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.serif(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        stripHtml(post.excerpt!),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (post.authorName != null &&
                            post.authorName!.isNotEmpty) ...[
                          const Icon(Icons.person_outline,
                              size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            post.authorName!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('·',
                              style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        if (post.publishedAt != null) ...[
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo(post.publishedAt!),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
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
