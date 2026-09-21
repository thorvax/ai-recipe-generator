import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Pill chip used for meal type, cuisine, dietary options, categories,
/// and removable ingredient tags (pass [onDeleted] to show the "×").
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? AppColors.primary : AppColors.surface;
    final Color fg = selected ? AppColors.white : AppColors.textPrimary;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.r24),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.body2.copyWith(color: fg)),
              if (onDeleted != null) ...[
                const SizedBox(width: AppSpacing.s8),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(Icons.close, size: 16, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
