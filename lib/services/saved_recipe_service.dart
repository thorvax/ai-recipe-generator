import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/recipe.dart';
import '../models/saved_recipe.dart';

/// Firestore access for categories and saved recipes. No UI code here.
class SavedRecipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore writes can wait forever while offline, so we cap the wait.
  static const Duration timeout = Duration(seconds: 8);

  /// Live list of the user's saved recipes (newest first).
  Stream<List<SavedRecipe>> watchSavedRecipes(String userId) {
    return _db
        .collection('saved_recipes')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => SavedRecipe.fromMap(d.data(), id: d.id))
          .toList();
      // A just-saved doc has no server timestamp yet -> treat it as "now".
      final now = DateTime.now();
      list.sort((a, b) => (b.savedAt ?? now).compareTo(a.savedAt ?? now));
      return list;
    });
  }

  Future<List<Category>> getCategories(String userId) async {
    final snap = await _db
        .collection('categories')
        .where('user_id', isEqualTo: userId)
        .get()
        .timeout(timeout);
    return snap.docs.map((d) => Category.fromMap(d.data(), id: d.id)).toList();
  }

  /// Finds the user's category with this name, or creates it.
  Future<Category> _getOrCreateCategory(String userId, String name) async {
    final trimmed = name.trim();
    final existing = await getCategories(userId);
    for (final c in existing) {
      if (c.name.toLowerCase() == trimmed.toLowerCase()) return c;
    }
    final ref = _db.collection('categories').doc();
    final category = Category(id: ref.id, userId: userId, name: trimmed);
    await ref.set(category.toMap()).timeout(timeout);
    return category;
  }

  /// Saves a recipe into a category. The document id is userId_recipeId, so
  /// saving the same recipe twice just updates it (no duplicates).
  Future<void> saveRecipe({
    required String userId,
    required Recipe recipe,
    required String categoryName,
  }) async {
    final category = await _getOrCreateCategory(userId, categoryName);
    final recipeId = recipe.id ?? _db.collection('recipes').doc().id;
    final docId = '${userId}_$recipeId';

    final saved = SavedRecipe(
      id: docId,
      userId: userId,
      recipeId: recipeId,
      categoryId: category.id,
      categoryName: category.name,
      recipe: recipe,
    );
    await _db
        .collection('saved_recipes')
        .doc(docId)
        .set(saved.toMap())
        .timeout(timeout);
  }

  Future<void> changeCategory({
    required String userId,
    required String savedId,
    required String categoryName,
  }) async {
    final category = await _getOrCreateCategory(userId, categoryName);
    await _db.collection('saved_recipes').doc(savedId).update({
      'category_id': category.id,
      'category_name': category.name,
    }).timeout(timeout);
  }

  Future<void> removeSaved(String savedId) {
    return _db.collection('saved_recipes').doc(savedId).delete().timeout(timeout);
  }
}
