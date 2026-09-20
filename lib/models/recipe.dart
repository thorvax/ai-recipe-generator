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
  final String mealType;
  final String cuisine;
  final int servings;
  final int cookingTime; // minutes
  final String dietaryRestriction;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final DateTime? createdAt;

  const Recipe({
    this.id,
    required this.userId,
    required this.name,
    required this.mealType,
    required this.cuisine,
    required this.servings,
    required this.cookingTime,
    required this.dietaryRestriction,
    required this.ingredients,
    required this.steps,
    this.createdAt,
  });

  /// Build a Recipe from the JSON that Gemini returns.
  /// The meal type / cuisine / servings / diet come from the user's request.
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
      mealType: request.mealType ?? 'Any',
      cuisine: request.cuisine ?? 'Any',
      servings: request.servings,
      cookingTime: (json['cooking_time'] as num?)?.toInt() ?? 0,
      dietaryRestriction: request.dietaryRestriction ?? 'None',
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
        'meal_type': mealType,
        'cuisine': cuisine,
        'servings': servings,
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
      mealType: map['meal_type']?.toString() ?? 'Any',
      cuisine: map['cuisine']?.toString() ?? 'Any',
      servings: (map['servings'] as num?)?.toInt() ?? 1,
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
        mealType: mealType,
        cuisine: cuisine,
        servings: servings,
        cookingTime: cookingTime,
        dietaryRestriction: dietaryRestriction,
        ingredients: ingredients,
        steps: steps,
        createdAt: createdAt,
      );

  /// "2 servings · 30 mins" (matches the Caption style in the design)
  String get summaryLabel => '$servings servings · $cookingTime mins';
}
