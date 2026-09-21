import 'package:flutter/foundation.dart';

import '../models/generation_request.dart';
import '../models/recipe.dart';
import '../services/gemini_service.dart';
import '../services/recipe_service.dart';

/// State for recipe generation: loading, error, and the current recipe.
class RecipeProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final RecipeService _recipes = RecipeService();

  bool _isGenerating = false;
  String? _errorMessage;
  Recipe? _currentRecipe;

  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  Recipe? get currentRecipe => _currentRecipe;

  /// Generates a recipe, saves the request + recipe to Firestore,
  /// and returns true on success.
  Future<bool> generate({
    required GenerationRequest request,
    required String userId,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    _currentRecipe = null;
    notifyListeners();

    try {
      var recipe =
          await _gemini.generateRecipe(request: request, userId: userId);

      // Saving is best-effort: the recipe is shown even if Firestore fails.
      await _recipes.saveRequest(request, userId);
      final id = await _recipes.saveRecipe(recipe);
      recipe = recipe.copyWith(id: id);

      _currentRecipe = recipe;
      return true;
    } on GeminiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('generate failed: $e');
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}
