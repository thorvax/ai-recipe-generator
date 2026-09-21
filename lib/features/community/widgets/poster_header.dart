import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/time_ago.dart';

/// Circle with the first letter of a name.
class PosterAvatar extends StatelessWidget {
  final String name;
  final double size;

  const PosterAvatar({super.key, required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTextStyles.body1.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

/// Avatar + "Jamie Reyes" + "2h ago".
class PosterHeader extends StatelessWidget {
  final String name;
  final DateTime? postedAt;

  const PosterHeader({super.key, required this.name, required this.postedAt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PosterAvatar(name: name),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(timeAgo(postedAt), style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}
