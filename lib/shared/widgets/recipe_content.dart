import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/recipe.dart';

/// Title, description, time pills, ingredients, steps and tags.
/// Reused by the Generated Recipe screen and the Saved Recipe detail screen.
class RecipeContent extends StatelessWidget {
  final Recipe recipe;

  const RecipeContent({super.key, required this.recipe});

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Text(
        text,
        style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Text(
        text,
        style: AppTextStyles.body2.copyWith(color: AppColors.secondaryDark),
      ),
    );
  }

  Widget _stepRow(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Text(
              '$number',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: Text(text, style: AppTextStyles.body1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(recipe.name, style: AppTextStyles.heading1),
        if (recipe.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            recipe.description,
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        _card(
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              _pill('Prep ${recipe.prepTime} min'),
              _pill('Cook ${recipe.cookingTime} min'),
              _pill('${recipe.servings} servings'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text('Ingredients', style: AppTextStyles.heading2),
        const SizedBox(height: AppSpacing.s12),
        _card(
          Column(
            children: [
              for (final ingredient in recipe.ingredients)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(ingredient.name, style: AppTextStyles.body1),
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Text(
                        ingredient.amountLabel,
                        style: AppTextStyles.body2
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text('Steps', style: AppTextStyles.heading2),
        const SizedBox(height: AppSpacing.s12),
        _card(
          Column(
            children: [
              for (final step in recipe.steps)
                _stepRow(step.stepNumber, step.instruction),
            ],
          ),
        ),
        if (recipe.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [for (final tag in recipe.tags) _tag(tag)],
          ),
        ],
      ],
    );
  }
}
