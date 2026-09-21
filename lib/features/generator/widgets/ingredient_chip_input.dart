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
  final VoidCallback onSubmit; // called when the user presses Enter/Done
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
        AppTextField(
          hint: 'Add an ingredient...',
          controller: controller,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
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
              ? 'Type an ingredient and press Done to add it.'
              : '$count ingredient${count == 1 ? '' : 's'} added',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
