import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/image_bytes_cache.dart';
import '../../../core/utils/time_ago.dart';
import '../../../models/comment.dart';
import '../../../shared/widgets/photo_viewer_screen.dart';
import 'poster_header.dart';

/// One comment or reply: avatar, name, text, optional photo, and
/// Reply / heart / delete actions. A deleted top-level comment that still
/// has replies shows as "This comment was deleted".
class CommentTile extends StatefulWidget {
  final Comment comment;
  final String myUid;

  /// Indented, smaller avatar.
  final bool isReply;

  /// Stand-in for a deleted or missing top-level comment.
  final bool isTombstone;

  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onToggleLike;

  const CommentTile({
    super.key,
    required this.comment,
    required this.myUid,
    required this.onReply,
    required this.onDelete,
    required this.onToggleLike,
    this.isReply = false,
    this.isTombstone = false,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  static const _thumbSize = 140.0;

  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(CommentTile old) {
    super.didUpdateWidget(old);
    if (old.comment.id != widget.comment.id ||
        old.comment.photoBase64?.length != widget.comment.photoBase64?.length) {
      _decode();
    }
  }

  void _decode() {
    _photo = ImageBytesCache.decode(
      'comment:${widget.comment.id}',
      widget.comment.photoBase64,
    );
  }

  Widget _tombstone() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Text(
            'This comment was deleted',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Bolds a leading "@Name" mention.
  Widget _text(Comment c) {
    final name = c.replyToUserName;
    final mention = name == null ? null : '@$name';
    if (mention != null && c.text.startsWith(mention)) {
      return Text.rich(
        TextSpan(
          style: AppTextStyles.body2,
          children: [
            TextSpan(
              text: mention,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            TextSpan(text: c.text.substring(mention.length)),
          ],
        ),
      );
    }
    return Text(c.text, style: AppTextStyles.body2);
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.s4),
              Text(label, style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    if (widget.isTombstone) return _tombstone();

    final isMine = c.userId == widget.myUid;
    final liked = c.isLikedBy(widget.myUid);
    final name = publicNameOf(context, c.userId, c.userName);
    final photo = _photo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PosterAvatar(
            uid: c.userId,
            name: c.userName,
            size: widget.isReply ? 24 : 32,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(timeAgo(c.createdAt), style: AppTextStyles.caption),
                  ],
                ),
                if (c.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s4),
                  _text(c),
                ],
                if (photo != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  GestureDetector(
                    onTap: () => PhotoViewerScreen.open(context, photo),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      child: Image.memory(
                        photo,
                        width: _thumbSize,
                        height: _thumbSize,
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    _action(
                      icon: liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: c.likeCount > 0 ? '${c.likeCount}' : '',
                      color: liked ? AppColors.heart : AppColors.textSecondary,
                      onTap: widget.onToggleLike,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    _action(
                      icon: Icons.reply_rounded,
                      label: 'Reply',
                      onTap: widget.onReply,
                    ),
                    if (isMine) ...[
                      const SizedBox(width: AppSpacing.s12),
                      _action(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onTap: widget.onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
