import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Read-only stars, rounded to the nearest half (e.g. 4.3 -> 4.5).
class StarRatingDisplay extends StatelessWidget {
  final double value;
  final double size;

  const StarRatingDisplay({super.key, required this.value, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final v = (value * 2).round() / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            v >= i
                ? Icons.star_rounded
                : (v >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: AppColors.secondary,
          ),
      ],
    );
  }
}

/// Tappable stars for choosing a rating from 1 to 5.
class StarRatingInput extends StatelessWidget {
  final int value; // 0 = nothing chosen yet
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: AppColors.secondary,
              ),
            ),
          ),
      ],
    );
  }
}
