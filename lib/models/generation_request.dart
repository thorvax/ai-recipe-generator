import 'package:cloud_firestore/cloud_firestore.dart';

/// GENERATION_REQUEST + REQUEST_INGREDIENT entities combined:
/// what the user typed on the Ingredient Input screen.
class GenerationRequest {
  final List<String> ingredients;
  final String? mealType; // null = no preference
  final String? cuisine; // null = no preference
  final int servings;
  final String? dietaryRestriction; // null = none

  const GenerationRequest({
    required this.ingredients,
    this.mealType,
    this.cuisine,
    this.servings = 2,
    this.dietaryRestriction,
  });

  /// For saving the request to Firestore (done in Step 5).
  Map<String, dynamic> toMap(String userId) => {
        'user_id': userId,
        'ingredients': ingredients,
        'meal_type': mealType,
        'cuisine': cuisine,
        'servings': servings,
        'dietary_restriction': dietaryRestriction,
        'created_at': FieldValue.serverTimestamp(),
      };
}
