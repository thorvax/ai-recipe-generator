import 'package:cloud_firestore/cloud_firestore.dart';

import 'recipe.dart';

/// SAVED_RECIPE entity. Stored in Firestore at saved_recipes/{userId}_{recipeId}.
///
/// Firestore has no joins, so the document also keeps a snapshot of the
/// recipe and the category name. The saved list and detail screens can then
/// load with a single query instead of one extra read per recipe.
class SavedRecipe {
  final String id;
  final String userId;
  final String recipeId;
  final String categoryId;
  final String categoryName;
  final Recipe recipe;
  final DateTime? savedAt;

  const SavedRecipe({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.categoryId,
    required this.categoryName,
    required this.recipe,
    this.savedAt,
  });

  Map<String, dynamic> toMap() => {
        'saved_recipe_id': id,
        'user_id': userId,
        'recipe_id': recipeId,
        'category_id': categoryId,
        'category_name': categoryName,
        'recipe': recipe.toMap(),
        'saved_at': FieldValue.serverTimestamp(),
      };

  factory SavedRecipe.fromMap(Map<String, dynamic> map, {required String id}) {
    final ts = map['saved_at'];
    final recipeId = map['recipe_id']?.toString() ?? '';
    return SavedRecipe(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      recipeId: recipeId,
      categoryId: map['category_id']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? 'Uncategorized',
      recipe: Recipe.fromMap(
        Map<String, dynamic>.from(map['recipe'] as Map),
        id: recipeId,
      ),
      savedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
