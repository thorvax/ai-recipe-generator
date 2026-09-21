import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Round + and − buttons with the current number (as in the design).
class ServingsStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const ServingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        
        const SizedBox(width: AppSpacing.s8),
        Text('$value', style: AppTextStyles.body1),
        const SizedBox(width: AppSpacing.s8),

        IconButton(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
