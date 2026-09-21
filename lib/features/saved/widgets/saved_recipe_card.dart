import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/saved_recipe.dart';
import '../../../shared/widgets/recipe_content.dart';

/// One row in the Saved Recipes list: category tag, name, "20 min · 2 servings".
class SavedRecipeCard extends StatelessWidget {
  final SavedRecipe saved;
  final VoidCallback onTap;

  const SavedRecipeCard({super.key, required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = saved.recipe;
    final servings = '${r.servings} serving${r.servings == 1 ? '' : 's'}';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      onTap: onTap,
      child: RecipeCardBox(
        padding: const EdgeInsets.all(AppSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeTag(text: saved.categoryName, compact: true),
            const SizedBox(height: AppSpacing.s12),
            Text(r.name, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.s8),
            Text(
              '${r.cookingTime} min · $servings',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
