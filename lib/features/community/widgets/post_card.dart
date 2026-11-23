import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/posted_recipe.dart';
import '../../../models/rating.dart';
import '../../../providers/community_provider.dart';
import '../../../shared/widgets/recipe_content.dart';
import '../../../shared/widgets/recipe_image.dart';
import 'poster_header.dart';
import 'star_rating.dart';

/// One post in the community feed: the recipe photo (or the default image)
/// as the background, with the poster on top and the recipe info at the
/// bottom over a dark gradient.
class PostCard extends StatefulWidget {
  final PostedRecipe post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  static const double height = 220;

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
    final stats = context.select<CommunityProvider, RatingStats?>(
      (c) => c.statsFor(widget.post.id),
    );
    final onImage = AppTextStyles.caption.copyWith(color: AppColors.white);
    if (stats == null) return const SizedBox(height: 18);

    if (stats.count == 0) return Text('No ratings yet', style: onImage);
    return Row(
      children: [
        StarRatingDisplay(value: stats.average, size: 16),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '${stats.average.toStringAsFixed(1)} (${stats.count})',
          style: onImage,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final tags = post.recipe.tags.take(3).toList();

    return SizedBox(
      height: PostCard.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Stack(
          children: [
            Positioned.fill(
              child: RecipeImage(cacheKey: post.id, base64: post.photoBase64),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.scrimStart,
                      AppColors.scrimStart,
                      AppColors.scrimEnd,
                    ],
                    stops: [0, 0.3, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PosterHeader(
                    uid: post.userId,
                    name: post.posterName,
                    postedAt: post.postedAt,
                    onImage: true,
                  ),
                  const Spacer(),
                  Text(
                    post.recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  if (post.caption.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      post.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s8),
                    // One line of tags; extra width is clipped, not wrapped.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          for (final t in tags)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.s8,
                              ),
                              child: RecipeTag(text: t, compact: true),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s8),
                  _ratingRow(context),
                ],
              ),
            ),
            // Ripple on top of everything; taps open the detail screen.
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: widget.onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
