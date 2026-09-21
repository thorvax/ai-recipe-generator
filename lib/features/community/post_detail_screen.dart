import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/comment.dart';
import '../../models/posted_recipe.dart';
import '../../models/rating.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_content.dart';
import 'widgets/comment_tile.dart';
import 'widgets/poster_header.dart';
import 'widgets/star_rating.dart';

/// A posted recipe: full recipe, caption, ratings and comments.
class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final Stream<List<Rating>> _ratingsStream;
  late final Stream<List<Comment>> _commentsStream;
  final _commentCtrl = TextEditingController();

  int _pendingRating = 0;
  bool _rating = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final community = context.read<CommunityProvider>();
    _ratingsStream = community.ratingsStream(widget.postId);
    _commentsStream = community.commentsStream(widget.postId);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _submitRating(String uid) async {
    setState(() => _rating = true);
    final error = await context.read<CommunityProvider>().rate(
          postId: widget.postId,
          userId: uid,
          value: _pendingRating,
        );
    if (!mounted) return;
    setState(() => _rating = false);
    _snack(error ?? 'Thanks for rating!');
  }

  Future<void> _sendComment(String uid) async {
    var text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    if (text.length > 500) text = text.substring(0, 500);

    final auth = context.read<AuthProvider>();
    setState(() => _sending = true);
    final error = await context.read<CommunityProvider>().addComment(
          postId: widget.postId,
          userId: uid,
          userName: auth.displayName,
          text: text,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _commentCtrl.clear();
    } else {
      _snack(error);
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final error = await context
        .read<CommunityProvider>()
        .deleteComment(widget.postId, comment.id);
    if (error != null && mounted) _snack(error);
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete post?', style: AppTextStyles.heading2),
        content: Text(
          'Your recipe will no longer be visible to other users.',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final community = context.read<CommunityProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    final error = await community.deletePost(widget.postId);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Post deleted')),
    );
  }

  Widget _ratingsCard(PostedRecipe post, String uid, bool isOwner) {
    return StreamBuilder<List<Rating>>(
      stream: _ratingsStream,
      builder: (context, snapshot) {
        final ratings = snapshot.data ?? const <Rating>[];
        final stats = RatingStats.fromRatings(ratings);

        Rating? mine;
        for (final r in ratings) {
          if (r.userId == uid) mine = r;
        }

        return RecipeCardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    stats.count == 0 ? '–' : stats.average.toStringAsFixed(1),
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StarRatingDisplay(value: stats.average, size: 22),
                      Text(
                        stats.count == 1 ? '1 rating' : '${stats.count} ratings',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              if (isOwner)
                Text(
                  'This is your recipe. Other cooks can rate it.',
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textSecondary),
                )
              else if (mine != null)
                Text(
                  'You rated this recipe ${mine.value} out of 5.',
                  style: AppTextStyles.body2
                      .copyWith(color: AppColors.textSecondary),
                )
              else ...[
                Text('Rate this recipe', style: AppTextStyles.body2),
                const SizedBox(height: AppSpacing.s8),
                StarRatingInput(
                  value: _pendingRating,
                  onChanged: (v) => setState(() => _pendingRating = v),
                ),
                const SizedBox(height: AppSpacing.s16),
                PrimaryButton(
                  label: 'Submit Rating',
                  isLoading: _rating,
                  onPressed:
                      _pendingRating == 0 ? null : () => _submitRating(uid),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _commentsList(String uid) {
    return StreamBuilder<List<Comment>>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Could not load comments.', style: AppTextStyles.body2);
        }
        final comments = snapshot.data ?? const <Comment>[];
        if (comments.isEmpty) {
          return Text(
            'No comments yet. Be the first!',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          );
        }
        return Column(
          children: [
            for (final c in comments)
              CommentTile(
                comment: c,
                isMine: c.userId == uid,
                onDelete: () => _deleteComment(c),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = context.watch<CommunityProvider>().findPost(widget.postId);
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.restaurant_menu_outlined,
          title: 'Post not available',
          message: 'This recipe was removed or could not be loaded.',
        ),
      );
    }

    final isOwner = post.userId == uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Recipe', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (_) => _deletePost(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete post')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24, AppSpacing.s8, AppSpacing.s24, AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterHeader(name: post.posterName, postedAt: post.postedAt),
              if (post.caption.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Text(post.caption, style: AppTextStyles.body1),
              ],
              const SizedBox(height: AppSpacing.s24),
              RecipeContent(recipe: post.recipe),
              const SizedBox(height: AppSpacing.s24),
              Text('Ratings', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.s12),
              _ratingsCard(post, uid, isOwner),
              const SizedBox(height: AppSpacing.s24),
              Text('Comments', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.s12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AppTextField(
                      hint: 'Add a comment...',
                      controller: _commentCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(uid),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: _sending ? null : () => _sendComment(uid),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              _commentsList(uid),
            ],
          ),
        ),
      ),
    );
  }
}
