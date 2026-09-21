import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/recipe_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_content.dart';
import '../../shared/widgets/secondary_button.dart';

/// Shows the generated recipe with Save / Start a New Recipe buttons.
class RecipeResultScreen extends StatelessWidget {
  const RecipeResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipe = context.watch<RecipeProvider>().currentRecipe;

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
                label: 'Save to Collection',
                onPressed: () {
                  // Built in Step 6 (category pop-up + saved recipes).
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saving is coming in the next step.'),
                    ),
                  );
                },
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
