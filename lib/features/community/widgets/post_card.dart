import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/posted_recipe.dart';
import '../../../providers/community_provider.dart';
import '../../../shared/widgets/recipe_content.dart';
import 'poster_header.dart';
import 'star_rating.dart';

/// One post in the community feed.
class PostCard extends StatefulWidget {
  final PostedRecipe post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  void initState() {
    super.initState();
    // Load this post's average rating (cached by the provider).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunityProvider>().loadStats(widget.post.id);
      }
    });
  }

  Widget _ratingRow(BuildContext context) {
    final stats = context.watch<CommunityProvider>().statsFor(widget.post.id);
    if (stats == null) return const SizedBox(height: 20);

    if (stats.count == 0) {
      return Text(
        'No ratings yet',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      );
    }
    return Row(
      children: [
        StarRatingDisplay(value: stats.average),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '${stats.average.toStringAsFixed(1)} (${stats.count})',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final tags = post.recipe.tags.take(3).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: widget.onTap,
      child: RecipeCardBox(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosterHeader(name: post.posterName, postedAt: post.postedAt),
            const SizedBox(height: AppSpacing.s16),
            Text(post.recipe.name, style: AppTextStyles.heading2),
            if (post.caption.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                post.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [for (final t in tags) RecipeTag(text: t, compact: true)],
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            _ratingRow(context),
          ],
        ),
      ),
    );
  }
}
