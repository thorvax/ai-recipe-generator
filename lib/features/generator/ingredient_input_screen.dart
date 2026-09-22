import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/generation_request.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'widgets/ingredient_chip_input.dart';
import 'widgets/option_chips.dart';
import 'widgets/preference_card.dart';
import 'widgets/servings_stepper.dart';

/// Home tab: "What's in your kitchen?" + preferences + Generate button.
class IngredientInputScreen extends StatefulWidget {
  const IngredientInputScreen({super.key});

  @override
  State<IngredientInputScreen> createState() => _IngredientInputScreenState();
}

class _IngredientInputScreenState extends State<IngredientInputScreen> {
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];
  static const _cuisines = [
    'Filipino', 'Italian', 'Mexican', 'Japanese', 'Indian',
    'Mediterranean', 'American', 'Thai', 'Chinese',
  ];
  static const _dietary = [
    'Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free', 'Low-carb',
  ];

  final _scrollCtrl = ScrollController();
  final _ingredientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<String> _ingredients = [];
  Set<String> _mealType = {};
  Set<String> _cuisine = {};
  Set<String> _diet = {};
  int _servings = 2;

  // Tracks the last set of default dietary needs applied from Settings, so
  // we can apply just the *change* (added/removed) instead of overwriting
  // whatever the user has currently picked for this one recipe.
  Set<String> _lastAppliedDietDefaults = {};

  /// Call every build with the latest saved defaults. Runs the diff and,
  /// if anything changed, applies it after this build finishes.
  void _syncDietaryDefaults(List<String> saved) {
    final defaults = Set<String>.from(saved);
    if (setEquals(defaults, _lastAppliedDietDefaults)) return;

    final added = defaults.difference(_lastAppliedDietDefaults);
    final removed = _lastAppliedDietDefaults.difference(defaults);
    _lastAppliedDietDefaults = defaults;
    if (added.isEmpty && removed.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _diet
          ..addAll(added)
          ..removeAll(removed);
      });
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _ingredientCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Adds what's typed in the field. Commas add several at once.
  void _addIngredient() {
    final parts = _ingredientCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    setState(() {
      for (final item in parts) {
        final exists =
            _ingredients.any((i) => i.toLowerCase() == item.toLowerCase());
        if (!exists) _ingredients.add(item);
      }
      _ingredientCtrl.clear();
    });
  }

  void _generate() {
    _addIngredient(); // include anything still typed in the field
    if (_ingredients.isEmpty) return;

    final notes = _notesCtrl.text.trim();
    final request = GenerationRequest(
      ingredients: List.of(_ingredients),
      mealType: _mealType.isEmpty ? null : _mealType.first,
      cuisine: _cuisine.isEmpty ? null : _cuisine.first,
      servings: _servings,
      dietaryNeeds: _diet.toList(),
      notes: notes.isEmpty ? null : notes,
    );

    Navigator.pushNamed(context, AppRoutes.generating, arguments: request);
  }

  void _scrollToTop() {
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _syncDietaryDefaults(auth.dietaryNeeds);

    final fullName = auth.currentUser?.displayName?.trim() ?? '';
    final firstName = fullName.isEmpty ? 'there' : fullName.split(' ').first;

    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hi, $firstName', style: AppTextStyles.body1),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.white),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            Text("What's in your kitchen?", style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Add the ingredients you have.',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s16),
            IngredientChipInput(
              ingredients: _ingredients,
              controller: _ingredientCtrl,
              onSubmit: _addIngredient,
              onRemove: (name) => setState(() => _ingredients.remove(name)),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('Your Preferences', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.s16),
            PreferenceCard(
              title: 'Meal type',
              child: OptionChips(
                options: _mealTypes,
                selected: _mealType,
                otherTitle: 'Add your own meal type',
                onChanged: (v) => setState(() => _mealType = v),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            PreferenceCard(
              title: 'Cuisine',
              child: OptionChips(
                options: _cuisines,
                selected: _cuisine,
                otherTitle: 'Add your own cuisine',
                onChanged: (v) => setState(() => _cuisine = v),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            PreferenceCard(
              title: 'Servings',
              child: ServingsStepper(
                value: _servings,
                onChanged: (v) => setState(() => _servings = v),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            PreferenceCard(
              title: 'Dietary needs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OptionChips(
                    options: _dietary,
                    selected: _diet,
                    multiSelect: true,
                    otherTitle: 'Add your own dietary need',
                    onChanged: (v) => setState(() => _diet = v),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'Anything else? e.g. no shellfish, spicy food only',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  AppTextField(
                    hint: 'Additional notes',
                    controller: _notesCtrl,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Generate Recipe',
              trailingIcon: Icons.arrow_forward,
              onPressed: _ingredients.isEmpty ? null : _generate,
            ),
            Center(
              child: TextButton(
                onPressed: _scrollToTop,
                child: Text(
                  'Back to ingredients',
                  style: AppTextStyles.body2.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
