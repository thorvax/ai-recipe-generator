import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Orange outlined "+ Other" / "+ Custom category" chip.
class AddChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const AddChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r24),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.s4),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
