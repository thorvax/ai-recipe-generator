import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/recipe.dart';

/// Orange tag pill (diet, cuisine, category). [compact] = smaller, for cards.
class RecipeTag extends StatelessWidget {
  final String text;
  final bool compact;

  const RecipeTag({super.key, required this.text, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.s12 : AppSpacing.s16,
        vertical: compact ? AppSpacing.s4 : AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.r24),
      ),
      child: Text(
        text,
        style: (compact ? AppTextStyles.caption : AppTextStyles.body2)
            .copyWith(color: AppColors.secondaryDark),
      ),
    );
  }
}

/// White rounded card used around ingredients, steps and list items.
class RecipeCardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const RecipeCardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class RecipeIngredientsCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeIngredientsCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return RecipeCardBox(
      child: Column(
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
    );
  }
}

class RecipeStepsCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeStepsCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return RecipeCardBox(
      child: Column(
        children: [
          for (final step in recipe.steps)
            Padding(
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
                      '${step.stepNumber}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(step.instruction, style: AppTextStyles.body1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Full recipe view: title, description, time pills, ingredients, steps, tags.
/// Used by the Generated Recipe screen.
class RecipeContent extends StatelessWidget {
  final Recipe recipe;

  const RecipeContent({super.key, required this.recipe});

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
        RecipeCardBox(
          child: Wrap(
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
        RecipeIngredientsCard(recipe: recipe),
        const SizedBox(height: AppSpacing.s24),
        Text('Steps', style: AppTextStyles.heading2),
        const SizedBox(height: AppSpacing.s12),
        RecipeStepsCard(recipe: recipe),
        if (recipe.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [for (final tag in recipe.tags) RecipeTag(text: tag)],
          ),
        ],
      ],
    );
  }
}
