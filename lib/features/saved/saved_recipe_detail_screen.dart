import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/saved_provider.dart';
import '../../shared/widgets/recipe_content.dart';
import '../../shared/widgets/secondary_button.dart';
import '../community/widgets/post_recipe_sheet.dart';
import 'widgets/category_sheet.dart';

/// Full view of a saved recipe, with Remove from Collection.
class SavedRecipeDetailScreen extends StatelessWidget {
  final String savedId;

  const SavedRecipeDetailScreen({super.key, required this.savedId});

  Future<void> _changeCategory(BuildContext context) async {
    final provider = context.read<SavedProvider>();
    final saved = provider.findById(savedId);
    if (saved == null) return;

    final name = await showCategorySheet(
      context,
      initial: saved.categoryName,
      confirmLabel: 'Update Category',
    );
    if (name == null || !context.mounted) return;

    final error = await provider.changeCategory(saved, name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Moved to $name')),
    );
  }

  Future<void> _post(BuildContext context) async {
    final saved = context.read<SavedProvider>().findById(savedId);
    if (saved == null) return;

    final caption = await showPostRecipeSheet(
      context,
      recipeName: saved.recipe.name,
    );
    if (caption == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final error = await context.read<CommunityProvider>().post(
          userId: auth.currentUser?.uid ?? saved.userId,
          posterName: auth.displayName,
          recipeId: saved.recipeId,
          recipe: saved.recipe,
          caption: caption,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Posted to the community')),
    );
  }

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove recipe?', style: AppTextStyles.heading2),
        content: Text(
          'It will be removed from your saved recipes.',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<SavedProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // back to the list first
    final error = await provider.remove(savedId);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Removed from your collection')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedProvider>().findById(savedId);

    // Happens for a moment after removing: the recipe is already gone.
    if (saved == null) {
      return Scaffold(appBar: AppBar());
    }

    final recipe = saved.recipe;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          recipe.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == 'category') {
                _changeCategory(context);
              } else {
                _post(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'category', child: Text('Change category')),
              PopupMenuItem(value: 'post', child: Text('Post to community')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24, AppSpacing.s8, AppSpacing.s24, AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecipeTag(text: saved.categoryName),
              const SizedBox(height: AppSpacing.s16),
              Text('Ingredients', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.s12),
              RecipeIngredientsCard(recipe: recipe),
              const SizedBox(height: AppSpacing.s24),
              Text('Steps', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.s12),
              RecipeStepsCard(recipe: recipe),
              const SizedBox(height: AppSpacing.s24),
              SecondaryButton(
                label: 'Remove from Collection',
                onPressed: () => _remove(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
