import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import '../models/saved_recipe.dart';
import '../services/saved_recipe_service.dart';

/// State for the Saved Recipes tab: live list + save / remove / re-categorize.
class SavedProvider extends ChangeNotifier {
  final SavedRecipeService _service = SavedRecipeService();

  StreamSubscription<List<SavedRecipe>>? _sub;
  String? _userId;
  List<SavedRecipe> _saved = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<SavedRecipe> get saved => _saved;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Start listening to this user's saved recipes (call after login).
  void listen(String userId) {
    if (_userId == userId && _sub != null) return;
    _sub?.cancel();
    _userId = userId;
    _saved = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _sub = _service.watchSavedRecipes(userId).listen(
      (list) {
        _saved = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('saved recipes stream error: $e');
        _isLoading = false;
        _errorMessage = 'Could not load your saved recipes.';
        notifyListeners();
      },
    );
  }

  /// Stop listening (call on logout).
  void stop() {
    _sub?.cancel();
    _sub = null;
    _userId = null;
    _saved = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool isSaved(String? recipeId) =>
      recipeId != null && _saved.any((s) => s.recipeId == recipeId);

  SavedRecipe? findById(String id) {
    for (final s in _saved) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Category names that at least one saved recipe uses (for the filter bar).
  List<String> get usedCategories {
    final names = <String>{for (final s in _saved) s.categoryName}.toList();
    names.sort();
    return names;
  }

  /// Applies the search text and category filter ("All" = no filter).
  List<SavedRecipe> filtered({String search = '', String category = 'All'}) {
    final q = search.trim().toLowerCase();
    return _saved.where((s) {
      if (category != 'All' && s.categoryName != category) return false;
      if (q.isEmpty) return true;
      final r = s.recipe;
      return r.name.toLowerCase().contains(q) ||
          r.ingredients.any((i) => i.name.toLowerCase().contains(q));
    }).toList();
  }

  /// The user's own category names (used to extend the preset chips).
  Future<List<String>> categoryNames() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final cats = await _service.getCategories(uid);
      return cats.map((c) => c.name).toList();
    } catch (_) {
      return [];
    }
  }

  /// Each of these returns an error message, or null when it worked.
  Future<String?> save({
    required Recipe recipe,
    required String categoryName,
  }) {
    return _run(() => _service.saveRecipe(
          userId: recipe.userId,
          recipe: recipe,
          categoryName: categoryName,
        ));
  }

  Future<String?> changeCategory(SavedRecipe saved, String categoryName) {
    return _run(() => _service.changeCategory(
          userId: saved.userId,
          savedId: saved.id,
          categoryName: categoryName,
        ));
  }

  Future<String?> remove(String savedId) =>
      _run(() => _service.removeSaved(savedId));

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on TimeoutException {
      return 'Could not reach the server. Check your connection and try again.';
    } catch (e) {
      debugPrint('saved action failed: $e');
      return 'Something went wrong. Please try again.';
    }
  }
}
