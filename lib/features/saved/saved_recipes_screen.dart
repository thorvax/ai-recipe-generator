import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/saved_provider.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'saved_recipe_detail_screen.dart';
import 'widgets/saved_recipe_card.dart';

/// Saved tab: search + category filter + list (or the empty state).
class SavedRecipesScreen extends StatefulWidget {
  /// Called by the empty state button (switches to the Home tab).
  final VoidCallback onGenerate;

  const SavedRecipesScreen({super.key, required this.onGenerate});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  String _search = '';
  String _category = 'All';

  Widget _body(SavedProvider saved) {
    if (saved.isLoading) {
      return const LoadingIndicator();
    }

    if (saved.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: saved.errorMessage!,
      );
    }

    if (saved.saved.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_add_outlined,
        title: 'No saved recipes yet',
        message: 'Recipes you save will show up here.',
        actionLabel: 'Generate your first recipe',
        onAction: widget.onGenerate,
      );
    }

    // If the selected category no longer has recipes, fall back to "All".
    final categories = ['All', ...saved.usedCategories];
    final selected = categories.contains(_category) ? _category : 'All';
    final items = saved.filtered(search: _search, category: selected);

    return Column(
      children: [
        AppTextField(
          hint: 'Search recipes',
          prefixIcon: Icons.search,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: AppSpacing.s16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in categories) ...[
                AppChip(
                  label: c,
                  selected: c == selected,
                  onTap: () => setState(() => _category = c),
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No recipes match your search.',
                    style: AppTextStyles.body2
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.s12),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return SavedRecipeCard(
                      saved: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SavedRecipeDetailScreen(savedId: item.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24, AppSpacing.s24, AppSpacing.s24, 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Recipes', style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.s16),
            Expanded(child: _body(saved)),
          ],
        ),
      ),
    );
  }
}
