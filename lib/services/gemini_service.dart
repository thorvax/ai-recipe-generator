import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/env.dart';
import '../models/generation_request.dart';
import '../models/recipe.dart';

/// A friendly error the UI can show directly.
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);

  @override
  String toString() => message;
}

/// Calls the Gemini REST API directly with the http package.
/// No UI code in here.
class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  Future<Recipe> generateRecipe({
    required GenerationRequest request,
    required String userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/${Env.geminiModel}:generateContent');

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _buildPrompt(request)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.8,
        // Ask Gemini to answer in JSON that follows our schema:
        'responseMimeType': 'application/json',
        'responseSchema': _recipeSchema,
      },
    };

    // 1) Send the request
    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': Env.geminiApiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw GeminiException('The request took too long. Please try again.');
    } catch (_) {
      throw GeminiException(
          'Could not reach the AI service. Check your internet connection.');
    }

    // 2) Check the HTTP status
    if (response.statusCode != 200) {
      debugPrint('Gemini error ${response.statusCode}: ${response.body}');
      throw GeminiException(_messageForStatus(response.statusCode));
    }

    // 3) Read the JSON text out of the response
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException(
            'The AI could not create a recipe for this request. '
            'Try different ingredients.');
      }

      final parts = candidates[0]['content']['parts'] as List;
      final text = parts
          .where((p) => p['text'] != null && p['thought'] != true)
          .map((p) => p['text'])
          .join();

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
    } catch (e) {
      debugPrint('Gemini parse error: $e\n${response.body}');
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

  /// The JSON shape we want back from Gemini.
  static const Map<String, dynamic> _recipeSchema = {
    'type': 'OBJECT',
    'properties': {
      'recipe_name': {'type': 'STRING'},
      'description': {'type': 'STRING'},
      'prep_time': {'type': 'INTEGER'},
      'cooking_time': {'type': 'INTEGER'},
      'ingredients': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'ingredient_name': {'type': 'STRING'},
            'quantity': {'type': 'STRING'},
            'unit': {'type': 'STRING'},
          },
          'required': ['ingredient_name', 'quantity', 'unit'],
        },
      },
      'steps': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
    },
    'required': [
      'recipe_name',
      'description',
      'prep_time',
      'cooking_time',
      'ingredients',
      'steps',
    ],
  };

  String _messageForStatus(int code) {
    switch (code) {
      case 400:
        return 'The AI request was not accepted. Check your API key and model name.';
      case 401:
      case 403:
        return 'The API key was rejected. Check the key in env.dart.';
      case 404:
        return 'AI model not found. Check the model name in env.dart.';
      case 429:
        return 'Free daily/minute limit reached. Wait a bit and try again.';
      case 500:
      case 503:
        return 'The AI service is busy right now. Please try again.';
      default:
        return 'Something went wrong (error $code). Please try again.';
    }
  }
}
