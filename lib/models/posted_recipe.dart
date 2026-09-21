import 'package:cloud_firestore/cloud_firestore.dart';

import 'recipe.dart';

/// POSTED_RECIPE entity. Stored at posted_recipes/{userId}_{recipeId}.
/// Ratings and comments live in sub-collections of the post:
///   posted_recipes/{id}/ratings/{userId}
///   posted_recipes/{id}/comments/{commentId}
/// The post keeps a snapshot of the recipe so other users can read it
/// without needing access to the poster's private recipes collection.
class PostedRecipe {
  final String id;
  final String userId; // the poster
  final String posterName;
  final String recipeId;
  final String caption; // may be empty
  final Recipe recipe;
  final DateTime? postedAt;

  const PostedRecipe({
    required this.id,
    required this.userId,
    required this.posterName,
    required this.recipeId,
    required this.caption,
    required this.recipe,
    this.postedAt,
  });

  Map<String, dynamic> toMap() => {
        'post_id': id,
        'user_id': userId,
        'poster_name': posterName,
        'recipe_id': recipeId,
        'caption': caption,
        'recipe': recipe.toMap(),
        'posted_at': FieldValue.serverTimestamp(),
      };

  factory PostedRecipe.fromMap(Map<String, dynamic> map, {required String id}) {
    final ts = map['posted_at'];
    final recipeId = map['recipe_id']?.toString() ?? '';
    return PostedRecipe(
      id: id,
      userId: map['user_id']?.toString() ?? '',
      posterName: map['poster_name']?.toString() ?? 'Cook',
      recipeId: recipeId,
      caption: map['caption']?.toString() ?? '',
      recipe: Recipe.fromMap(
        Map<String, dynamic>.from(map['recipe'] as Map),
        id: recipeId,
      ),
      postedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
