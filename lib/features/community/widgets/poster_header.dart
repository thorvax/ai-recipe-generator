import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_ago.dart';
import '../../../providers/profile_provider.dart';
import '../../../shared/widgets/user_avatar.dart';

/// A poster's / commenter's avatar (custom photo → Google photo → initial).
class PosterAvatar extends StatelessWidget {
  final String uid;
  final String name;
  final double size;

  const PosterAvatar({
    super.key,
    required this.uid,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) =>
      UserAvatar(uid: uid, name: name, size: size);
}

/// The current public name for [uid], or [fallback] (the name stored on the
/// post/comment) until the profile has loaded.
String publicNameOf(BuildContext context, String uid, String fallback) {
  final name = context.select<ProfileProvider, String?>(
    (p) => p.profileFor(uid)?.name,
  );
  return (name == null || name.trim().isEmpty) ? fallback : name;
}

/// Avatar + "Jamie Reyes" + "2h ago".
/// Set [onImage] for white text over a photo.
class PosterHeader extends StatelessWidget {
  final String uid;
  final String name;
  final DateTime? postedAt;
  final bool onImage;

  const PosterHeader({
    super.key,
    required this.uid,
    required this.name,
    required this.postedAt,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final shownName = publicNameOf(context, uid, name);
    final nameColor = onImage ? AppColors.white : AppColors.textPrimary;
    final timeColor = onImage ? AppColors.white : AppColors.textSecondary;

    return Row(
      children: [
        PosterAvatar(uid: uid, name: shownName, size: onImage ? 36 : 40),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shownName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: nameColor,
                ),
              ),
              Text(
                timeAgo(postedAt),
                style: AppTextStyles.caption.copyWith(color: timeColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
