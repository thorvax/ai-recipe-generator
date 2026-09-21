import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/saved_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_content.dart';
import '../../shared/widgets/secondary_button.dart';
import '../saved/widgets/category_sheet.dart';

/// Shows the generated recipe with Save / Start a New Recipe buttons.
class RecipeResultScreen extends StatefulWidget {
  const RecipeResultScreen({super.key});

  @override
  State<RecipeResultScreen> createState() => _RecipeResultScreenState();
}

class _RecipeResultScreenState extends State<RecipeResultScreen> {
  bool _saving = false;

  Future<void> _save(Recipe recipe) async {
    final category = await showCategorySheet(context);
    if (category == null || !mounted) return;

    setState(() => _saving = true);
    final error = await context
        .read<SavedProvider>()
        .save(recipe: recipe, categoryName: category);
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Saved to $category')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = context.watch<RecipeProvider>().currentRecipe;
    final isSaved = context.watch<SavedProvider>().isSaved(recipe?.id);

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.restaurant_menu_outlined,
          title: 'No recipe yet',
          message: 'Go back and generate a recipe first.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24, 0, AppSpacing.s24, AppSpacing.s24,
          ),
          child: Column(
            children: [
              RecipeContent(recipe: recipe),
              const SizedBox(height: AppSpacing.s24),
              PrimaryButton(
                label: isSaved ? 'Saved to Collection' : 'Save to Collection',
                trailingIcon: isSaved ? Icons.check : null,
                isLoading: _saving,
                onPressed: isSaved ? null : () => _save(recipe),
              ),
              const SizedBox(height: AppSpacing.s12),
              SecondaryButton(
                label: 'Start a New Recipe',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
