import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_ago.dart';
import '../../../models/comment.dart';
import 'poster_header.dart';

/// One comment. Shows a delete button on your own comments.
class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isMine;
  final VoidCallback onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.isMine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PosterAvatar(name: comment.userName, size: 32),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(timeAgo(comment.createdAt), style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(comment.text, style: AppTextStyles.body2),
              ],
            ),
          ),
          if (isMine)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
