import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/recipe.dart';
import '../../models/recipe_ingredient.dart';
import '../../models/recipe_step.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/primary_button.dart';
import 'widgets/ingredient_list_editor.dart';
import 'widgets/option_chips.dart';
import 'widgets/preference_card.dart';
import 'widgets/servings_stepper.dart';
import 'widgets/step_list_editor.dart';

/// Used both to write a brand-new recipe from scratch and to edit an
/// existing one (generated or saved). Returns the edited [Recipe] via
/// Navigator.pop, or null if the user backs out.
class RecipeEditorScreen extends StatefulWidget {
  final Recipe initial;
  final String title;
  final String saveLabel;

  const RecipeEditorScreen({
    super.key,
    required this.initial,
    required this.title,
    this.saveLabel = 'Save',
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];
  static const _cuisines = [
    'Filipino', 'Italian', 'Mexican', 'Japanese', 'Indian',
    'Mediterranean', 'American', 'Thai', 'Chinese',
  ];
  static const _dietary = [
    'Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free', 'Low-carb',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _prepCtrl;
  late final TextEditingController _cookCtrl;

  late Set<String> _mealType;
  late Set<String> _cuisine;
  late Set<String> _diet;
  late int _servings;
  late List<RecipeIngredient> _ingredients;
  late List<RecipeStep> _steps;

  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _nameCtrl = TextEditingController(text: r.name);
    _descriptionCtrl = TextEditingController(text: r.description);
    _prepCtrl = TextEditingController(text: r.prepTime == 0 ? '' : '${r.prepTime}');
    _cookCtrl = TextEditingController(text: r.cookingTime == 0 ? '' : '${r.cookingTime}');
    _mealType = r.mealType == 'Any' ? {} : {r.mealType};
    _cuisine = r.cuisine == 'Any' ? {} : {r.cuisine};
    _diet = r.dietaryRestriction == 'None'
        ? {}
        : r.dietaryRestriction.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    _servings = r.servings == 0 ? 2 : r.servings;
    _ingredients = List.of(r.ingredients);
    _steps = List.of(r.steps);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _prepCtrl.dispose();
    _cookCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredients.where((i) => i.name.trim().isNotEmpty).toList();
    final steps = _steps.where((s) => s.instruction.trim().isNotEmpty).toList();

    if (ingredients.isEmpty) {
      setState(() => _error = 'Add at least one ingredient.');
      return;
    }
    if (steps.isEmpty) {
      setState(() => _error = 'Add at least one step.');
      return;
    }

    final recipe = widget.initial.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      mealType: _mealType.isEmpty ? 'Any' : _mealType.first,
      cuisine: _cuisine.isEmpty ? 'Any' : _cuisine.first,
      servings: _servings,
      prepTime: int.tryParse(_prepCtrl.text.trim()) ?? 0,
      cookingTime: int.tryParse(_cookCtrl.text.trim()) ?? 0,
      dietaryRestriction: _diet.isEmpty ? 'None' : _diet.join(', '),
      ingredients: ingredients,
      steps: steps,
      // source is left unchanged: editing a recipe never changes whether
      // it originally came from AI generation or manual entry.
    );

    Navigator.pop(context, recipe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.title,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpacing.s16),
                ],
                AppTextField(
                  label: 'Recipe name',
                  hint: 'e.g. Garlic Tomato Rice Bowl',
                  controller: _nameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.s16),
                AppTextField(
                  label: 'Description',
                  hint: 'A short description of the dish (optional)',
                  controller: _descriptionCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.s16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Prep time (min)',
                        hint: '0',
                        controller: _prepCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s16),
                    Expanded(
                      child: AppTextField(
                        label: 'Cook time (min)',
                        hint: '0',
                        controller: _cookCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
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
                  child: OptionChips(
                    options: _dietary,
                    selected: _diet,
                    multiSelect: true,
                    otherTitle: 'Add your own dietary need',
                    onChanged: (v) => setState(() => _diet = v),
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                Text('Ingredients', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.s12),
                IngredientListEditor(
                  initial: _ingredients,
                  onChanged: (v) => _ingredients = v,
                ),
                const SizedBox(height: AppSpacing.s24),
                Text('Steps', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.s12),
                StepListEditor(
                  initial: _steps,
                  onChanged: (v) => _steps = v,
                ),
                const SizedBox(height: AppSpacing.s24),
                PrimaryButton(label: widget.saveLabel, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
