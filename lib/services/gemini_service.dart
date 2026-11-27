import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/generation_request.dart';
import '../models/recipe.dart';

/// A friendly error the UI can show directly.
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);

  @override
  String toString() => message;
}

/// Calls Gemini through Firebase AI Logic (Gemini Developer API, free tier).
/// The Gemini key stays inside Firebase, so it is NOT in the app or the APK.
/// No UI code in here.
class GeminiService {
  /// Same model the website uses. Not a secret, so it lives here.
  static const String modelName = 'gemini-3.5-flash-lite';

  late final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: modelName,
    generationConfig: GenerationConfig(
      temperature: 0.8,
      // Ask Gemini to answer in JSON that follows our schema:
      responseMimeType: 'application/json',
      responseSchema: _recipeSchema,
    ),
  );

  Future<Recipe> generateRecipe({
    required GenerationRequest request,
    required String userId,
  }) async {
    // 1) Send the request
    late GenerateContentResponse response;
    try {
      response = await _model
          .generateContent([Content.text(_buildPrompt(request))])
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw GeminiException('The request took too long. Please try again.');
    } on QuotaExceeded {
      throw GeminiException(
          'Free daily/minute limit reached. Wait a bit and try again.');
    } on ServiceApiNotEnabled {
      throw GeminiException(
          'AI is not set up for this app yet (Firebase AI Logic is off).');
    } on UnsupportedUserLocation {
      throw GeminiException('The AI service is not available in your region.');
    } on ServerException catch (e) {
      debugPrint('Gemini server error: ${e.message}');
      throw GeminiException('The AI service is busy right now. Please try again.');
    } on FirebaseAIException catch (e) {
      debugPrint('Gemini error: ${e.message}');
      throw GeminiException(
          'The AI could not create a recipe for this request. '
          'Try different ingredients.');
    } catch (e) {
      debugPrint('Gemini request failed: $e');
      throw GeminiException(
          'Could not reach the AI service. Check your internet connection.');
    }

    // 2) Read the JSON text out of the response
    try {
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiException(
            'The AI could not create a recipe for this request. '
            'Try different ingredients.');
      }

      final recipeJson = jsonDecode(text) as Map<String, dynamic>;
      final recipe = Recipe.fromGemini(
        json: recipeJson,
        request: request,
        userId: userId,
      );

      if (recipe.name.isEmpty ||
          recipe.ingredients.isEmpty ||
          recipe.steps.isEmpty) {
        throw GeminiException('The recipe came back incomplete. Try again.');
      }
      return recipe;
    } on GeminiException {
      rethrow;
    } on FirebaseAIException catch (e) {
      // Thrown by response.text when the answer was blocked (safety).
      debugPrint('Gemini blocked: ${e.message}');
      throw GeminiException(
          'The AI could not create a recipe for this request. '
          'Try different ingredients.');
    } catch (e) {
      debugPrint('Gemini parse error: $e');
      throw GeminiException('Could not read the AI response. Try again.');
    }
  }

  String _buildPrompt(GenerationRequest r) {
    final ingredients = r.ingredients.join(', ');
    return '''
You are a friendly home-cooking assistant. Create ONE complete recipe.

Available ingredients: $ingredients
Meal type: ${r.mealType ?? 'no preference'}
Cuisine: ${r.cuisine ?? 'no preference'}
Servings: ${r.servings}
Dietary needs: ${r.dietaryNeeds.isEmpty ? 'none' : r.dietaryNeeds.join(', ')}
Additional notes from the user: ${r.notes ?? 'none'}

Rules:
- Build the recipe mainly from the available ingredients. You may also assume
  basic pantry items (salt, pepper, cooking oil, water) and add at most a few
  other common ingredients if really needed.
- Strictly follow the dietary needs and cuisine if given.
- Scale every quantity for exactly ${r.servings} servings.
- Give precise quantities with units (use an empty unit for countable items
  such as "2 eggs").
- Write clear, numbered-style steps that a beginner can follow. Each step is
  one short paragraph.
- prep_time is the preparation time in minutes and cooking_time is the actual
  cooking time in minutes (both whole numbers).
- description is one friendly sentence (max 25 words) describing the dish.
- Respect the additional notes (for example allergies or spice level).
''';
  }

  /// The JSON shape we want back from Gemini. All properties are required.
  static final Schema _recipeSchema = Schema.object(
    properties: {
      'recipe_name': Schema.string(),
      'description': Schema.string(),
      'prep_time': Schema.integer(),
      'cooking_time': Schema.integer(),
      'ingredients': Schema.array(
        items: Schema.object(
          properties: {
            'ingredient_name': Schema.string(),
            'quantity': Schema.string(),
            'unit': Schema.string(),
          },
        ),
      ),
      'steps': Schema.array(items: Schema.string()),
    },
  );
}
