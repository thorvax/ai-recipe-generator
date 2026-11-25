import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/comment_thread.dart';
import '../../models/comment.dart';
import '../../models/posted_recipe.dart';
import '../../models/rating.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/saved_provider.dart';
import '../../services/report_service.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_content.dart';
import '../../shared/widgets/recipe_image.dart';
import '../saved/widgets/category_sheet.dart';
import 'widgets/comment_composer.dart';
import 'widgets/comment_tile.dart';
import 'widgets/poster_header.dart';
import 'widgets/report_sheet.dart';
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
  final _composerKey = GlobalKey<CommentComposerState>();

  int _pendingRating = 0;
  bool _rating = false;

  CommentSort _sort = CommentSort.recent;

  /// Threads the user opened (threads with 2+ replies start collapsed).
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    final community = context.read<CommunityProvider>();
    _ratingsStream = community.ratingsStream(widget.postId);
    _commentsStream = community.commentsStream(widget.postId);
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

  Future<String?> _sendComment(String uid, CommentDraft draft) {
    final auth = context.read<AuthProvider>();
    return context.read<CommunityProvider>().addComment(
          postId: widget.postId,
          userId: uid,
          userName: auth.displayName,
          text: draft.text,
          parentId: draft.parentId,
          replyToUserName: draft.replyToUserName,
          photoBase64: draft.photoBase64,
        );
  }

  Future<void> _deleteComment(Comment comment, {required bool hasReplies}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete comment?', style: AppTextStyles.heading2),
        content: Text(
          hasReplies
              ? 'Your comment will be removed. Its replies will stay.'
              : 'Your comment will be removed.',
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

    final error = await context.read<CommunityProvider>().deleteComment(
          widget.postId,
          comment,
          hasReplies: hasReplies,
        );
    if (error != null && mounted) _snack(error);
  }

  /// "Their profile picture" is only offered for an uploaded picture,
  /// because admins can't remove a Google photo.
  bool _hasCustomAvatar(String userId) =>
      context.read<ProfileProvider>().profileFor(userId)?.hasCustomAvatar ??
      false;

  void _reportPost(PostedRecipe post, String uid) {
    showReportSheet(
      context,
      reporterUid: uid,
      subjects: [
        ReportSubject(
          'This post',
          ReportTarget(
            type: ReportType.post,
            postId: post.id,
            targetUserId: post.userId,
          ),
        ),
        if (_hasCustomAvatar(post.userId))
          ReportSubject(
            'Their profile picture',
            ReportTarget(
              type: ReportType.avatar,
              postId: post.id,
              targetUserId: post.userId,
            ),
          ),
      ],
    );
  }

  void _reportComment(Comment comment, String uid) {
    // read, not select: this runs on tap, outside build().
    final profileName =
        context.read<ProfileProvider>().profileFor(comment.userId)?.name;
    final name = (profileName == null || profileName.trim().isEmpty)
        ? comment.userName
        : profileName;
    showReportSheet(
      context,
      reporterUid: uid,
      subjects: [
        ReportSubject(
          'This comment',
          ReportTarget(
            type: ReportType.comment,
            postId: widget.postId,
            commentId: comment.id,
            targetUserId: comment.userId,
          ),
        ),
        if (_hasCustomAvatar(comment.userId))
          ReportSubject(
            "$name's profile picture",
            ReportTarget(
              type: ReportType.avatar,
              postId: widget.postId,
              targetUserId: comment.userId,
            ),
          ),
      ],
    );
  }

  Future<void> _toggleLike(Comment comment, String uid) async {
    final error = await context
        .read<CommunityProvider>()
        .toggleCommentLike(widget.postId, comment, uid);
    if (error != null && mounted) _snack(error);
  }

  Future<void> _saveToCollection(PostedRecipe post, String uid) async {
    final category = await showCategorySheet(context);
    if (category == null || !mounted) return;

    final error = await context.read<SavedProvider>().save(
          recipe: post.recipe,
          categoryName: category,
          userId: uid,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Saved to $category')),
    );
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

  Widget _sortToggle() {
    return Row(
      children: [
        AppChip(
          label: 'Recent',
          selected: _sort == CommentSort.recent,
          onTap: () => setState(() => _sort = CommentSort.recent),
        ),
        const SizedBox(width: AppSpacing.s8),
        AppChip(
          label: 'Most liked',
          selected: _sort == CommentSort.mostLiked,
          onTap: () => setState(() => _sort = CommentSort.mostLiked),
        ),
      ],
    );
  }

  Widget _tile(
    Comment c,
    String uid, {
    bool isReply = false,
    bool isTombstone = false,
    bool hasReplies = false,
  }) {
    return CommentTile(
      key: ValueKey(c.id),
      comment: c,
      myUid: uid,
      isReply: isReply,
      isTombstone: isTombstone,
      onReply: () => _composerKey.currentState?.startReply(c),
      onDelete: () => _deleteComment(c, hasReplies: hasReplies),
      onToggleLike: () => _toggleLike(c, uid),
      onReport: () => _reportComment(c, uid),
    );
  }

  Widget _toggleLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// One thread: the top-level comment, then its replies indented.
  /// With 2+ replies it starts collapsed, showing one preview reply.
  Widget _thread(CommentThread thread, String uid) {
    final replies = thread.replies;
    final id = thread.parent.id;
    final collapsible = replies.length > 1;
    final expanded = !collapsible || _expanded.contains(id);
    final shown = expanded ? replies : [previewReply(thread, _sort)!];
    final hidden = replies.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tile(
          thread.parent,
          uid,
          isTombstone: thread.parentGone,
          hasReplies: replies.isNotEmpty,
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in shown) _tile(r, uid, isReply: true),
                if (collapsible && !expanded)
                  _toggleLink(
                    hidden == 1
                        ? 'View 1 more reply'
                        : 'View $hidden more replies',
                    () => setState(() => _expanded.add(id)),
                  ),
                if (collapsible && expanded)
                  _toggleLink(
                    'Hide replies',
                    () => setState(() => _expanded.remove(id)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _commentsList(String uid) {
    return StreamBuilder<List<Comment>>(
      stream: _commentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Could not load comments.', style: AppTextStyles.body2);
        }
        final threads = sortThreads(
          buildThreads(snapshot.data ?? const <Comment>[]),
          _sort,
        );
        if (threads.isEmpty) {
          return Text(
            'No comments yet. Be the first!',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sortToggle(),
            const SizedBox(height: AppSpacing.s8),
            for (final t in threads) _thread(t, uid),
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
    final isSaved = context.watch<SavedProvider>().isSaved(post.recipe.id);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Recipe', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          if (!isOwner)
            IconButton(
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              tooltip: isSaved ? 'Saved to your collection' : 'Save recipe',
              onPressed: isSaved ? null : () => _saveToCollection(post, uid),
            ),
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (_) => _deletePost(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete post')),
              ],
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (_) => _reportPost(post, uid),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Report')),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: RecipeImage(
                    cacheKey: post.id,
                    base64: post.photoBase64,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              PosterHeader(
                uid: post.userId,
                name: post.posterName,
                postedAt: post.postedAt,
              ),
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
              CommentComposer(
                key: _composerKey,
                onSend: (draft) => _sendComment(uid, draft),
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
