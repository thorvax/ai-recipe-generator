import 'package:cloud_firestore/cloud_firestore.dart';

import 'generation_request.dart';
import 'recipe_ingredient.dart';
import 'recipe_step.dart';

/// RECIPE entity. In Firestore, the ingredients and steps are stored INSIDE
/// the recipe document as arrays (simpler and cheaper than 3 collections).
class Recipe {
  final String? id; // null until it is saved to Firestore
  final String userId;
  final String name;
  final String description; // one or two friendly sentences
  final String mealType;
  final String cuisine;
  final int servings;
  final int prepTime; // minutes
  final int cookingTime; // minutes (cook time only)
  final String dietaryRestriction; // e.g. "Vegetarian, Gluten-free" or "None"
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final DateTime? createdAt;

  const Recipe({
    this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.mealType,
    required this.cuisine,
    required this.servings,
    required this.prepTime,
    required this.cookingTime,
    required this.dietaryRestriction,
    required this.ingredients,
    required this.steps,
    this.createdAt,
  });

  /// Build a Recipe from the JSON that Gemini returns.
  /// Meal type / cuisine / servings / diet come from the user's request.
  factory Recipe.fromGemini({
    required Map<String, dynamic> json,
    required GenerationRequest request,
    required String userId,
  }) {
    final rawIngredients = (json['ingredients'] as List?) ?? [];
    final rawSteps = (json['steps'] as List?) ?? [];

    return Recipe(
      userId: userId,
      name: json['recipe_name']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
      mealType: request.mealType ?? 'Any',
      cuisine: request.cuisine ?? 'Any',
      servings: request.servings,
      prepTime: (json['prep_time'] as num?)?.toInt() ?? 0,
      cookingTime: (json['cooking_time'] as num?)?.toInt() ?? 0,
      dietaryRestriction: request.dietaryNeeds.isEmpty
          ? 'None'
          : request.dietaryNeeds.join(', '),
      ingredients: rawIngredients
          .map((e) => RecipeIngredient.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      steps: [
        for (var i = 0; i < rawSteps.length; i++)
          RecipeStep(stepNumber: i + 1, instruction: rawSteps[i].toString()),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'recipe_name': name,
        'description': description,
        'meal_type': mealType,
        'cuisine': cuisine,
        'servings': servings,
        'prep_time': prepTime,
        'cooking_time': cookingTime,
        'dietary_restriction': dietaryRestriction,
        'ingredients': ingredients.map((i) => i.toMap()).toList(),
        'steps': steps.map((s) => s.toMap()).toList(),
        'created_at': FieldValue.serverTimestamp(),
      };

  factory Recipe.fromMap(Map<String, dynamic> map, {String? id}) {
    final ts = map['created_at'];
    return Recipe(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      name: map['recipe_name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      mealType: map['meal_type']?.toString() ?? 'Any',
      cuisine: map['cuisine']?.toString() ?? 'Any',
      servings: (map['servings'] as num?)?.toInt() ?? 1,
      prepTime: (map['prep_time'] as num?)?.toInt() ?? 0,
      cookingTime: (map['cooking_time'] as num?)?.toInt() ?? 0,
      dietaryRestriction: map['dietary_restriction']?.toString() ?? 'None',
      ingredients: ((map['ingredients'] as List?) ?? [])
          .map((e) => RecipeIngredient.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      steps: ((map['steps'] as List?) ?? [])
          .map((e) => RecipeStep.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Recipe copyWith({String? id}) => Recipe(
        id: id ?? this.id,
        userId: userId,
        name: name,
        description: description,
        mealType: mealType,
        cuisine: cuisine,
        servings: servings,
        prepTime: prepTime,
        cookingTime: cookingTime,
        dietaryRestriction: dietaryRestriction,
        ingredients: ingredients,
        steps: steps,
        createdAt: createdAt,
      );

  /// Orange tag chips under the recipe: diet(s) + cuisine.
  List<String> get tags => [
        ...dietaryRestriction
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s != 'None'),
        if (cuisine != 'Any') cuisine,
      ];

  /// "2 servings · 30 mins" (total time), for list cards.
  String get summaryLabel => '$servings servings · ${prepTime + cookingTime} mins';
}
