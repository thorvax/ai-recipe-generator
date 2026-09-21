import 'package:cloud_firestore/cloud_firestore.dart';

/// GENERATION_REQUEST + REQUEST_INGREDIENT entities combined:
/// what the user chose on the Ingredient Input screen.
class GenerationRequest {
  final List<String> ingredients;
  final String? mealType; // null = no preference
  final String? cuisine; // null = no preference
  final int servings;
  final List<String> dietaryNeeds; // can pick several
  final String? notes; // "Additional notes" box

  const GenerationRequest({
    required this.ingredients,
    this.mealType,
    this.cuisine,
    this.servings = 2,
    this.dietaryNeeds = const [],
    this.notes,
  });

  Map<String, dynamic> toMap(String userId) => {
        'user_id': userId,
        'ingredients': ingredients,
        'meal_type': mealType,
        'cuisine': cuisine,
        'servings': servings,
        'dietary_restriction': dietaryNeeds.join(', '),
        'notes': notes,
        'created_at': FieldValue.serverTimestamp(),
      };
}
