import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_text_field.dart';

/// "Add an ingredient..." field + removable chips + "3 ingredients added".
/// The parent screen owns the list; this widget only draws it.
class IngredientChipInput extends StatelessWidget {
  final List<String> ingredients;
  final TextEditingController controller;
  final VoidCallback onSubmit; // Enter button or keyboard Done
  final ValueChanged<String> onRemove;

  const IngredientChipInput({
    super.key,
    required this.ingredients,
    required this.controller,
    required this.onSubmit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final count = ingredients.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IntrinsicHeight makes the button exactly as tall as the field.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppTextField(
                  hint: 'Add an ingredient...',
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                ),
                child: Text(
                  'Enter',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (count > 0) ...[
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final ingredient in ingredients)
                AppChip(
                  label: ingredient,
                  onDeleted: () => onRemove(ingredient),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        Text(
          count == 0
              ? 'Type an ingredient and tap Enter. Add several at once by '
                  'separating them with commas, e.g. chicken, garlic, rice.'
              : '$count ingredient${count == 1 ? '' : 's'} added',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
