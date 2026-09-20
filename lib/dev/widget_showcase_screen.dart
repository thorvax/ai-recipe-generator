import 'package:flutter/material.dart';

import '/core/theme/app_colors.dart';
import '/core/theme/app_spacing.dart';
import '/core/theme/app_text_styles.dart';
import '/shared/widgets/app_bottom_nav.dart';
import '/shared/widgets/app_chip.dart';
import '/shared/widgets/app_text_field.dart';
import '/shared/widgets/empty_state.dart';
import '/shared/widgets/error_banner.dart';
import '/shared/widgets/loading_indicator.dart';
import '/shared/widgets/primary_button.dart';
import '/shared/widgets/secondary_button.dart';

/// TEMPORARY screen to preview all shared widgets. Delete after Step 2.
class WidgetShowcaseScreen extends StatefulWidget {
  const WidgetShowcaseScreen({super.key});

  @override
  State<WidgetShowcaseScreen> createState() => _WidgetShowcaseScreenState();
}

class _WidgetShowcaseScreenState extends State<WidgetShowcaseScreen> {
  int _navIndex = 0;
  String _selectedMeal = 'Dinner';
  final List<String> _ingredients = ['Tomato', 'Onion', 'Egg'];

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading2),
          const SizedBox(height: AppSpacing.s12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          _section(
            'Typography',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("What's in your kitchen?", style: AppTextStyles.heading1),
                Text('Your Ingredients', style: AppTextStyles.heading2),
                Text('Add the ingredients you have.', style: AppTextStyles.body1),
                Text('Tomato', style: AppTextStyles.body2),
                Text('2 servings · 30 mins', style: AppTextStyles.caption),
              ],
            ),
          ),
          _section(
            'Buttons',
            Column(
              children: [
                PrimaryButton(
                  label: 'Continue',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.s8),
                const PrimaryButton(label: 'Disabled', onPressed: null),
                const SizedBox(height: AppSpacing.s8),
                PrimaryButton(label: 'Loading', isLoading: true, onPressed: () {}),
                const SizedBox(height: AppSpacing.s8),
                SecondaryButton(label: 'Cancel', onPressed: () {}),
              ],
            ),
          ),
          _section(
            'Text fields',
            const Column(
              children: [
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: AppSpacing.s16),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                ),
              ],
            ),
          ),
          _section(
            'Chips',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final meal in ['Breakfast', 'Lunch', 'Dinner', 'Snack'])
                      AppChip(
                        label: meal,
                        selected: _selectedMeal == meal,
                        onTap: () => setState(() => _selectedMeal = meal),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final ing in _ingredients)
                      AppChip(
                        label: ing,
                        onDeleted: () => setState(() => _ingredients.remove(ing)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _section('Error banner', const ErrorBanner(message: 'Incorrect email or password.')),
          _section('Loading', const SizedBox(height: 100, child: LoadingIndicator(message: 'Cooking up your recipe...'))),
          _section(
            'Empty state',
            SizedBox(
              height: 340,
              child: EmptyState(
                icon: Icons.bookmark_border,
                title: 'No saved recipes yet',
                message: 'Generate a recipe and save it to see it here.',
                actionLabel: 'Generate a recipe',
                onAction: () {},
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
