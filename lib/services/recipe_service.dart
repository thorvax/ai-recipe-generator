import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/generation_request.dart';
import '../models/recipe.dart';

/// Reads/writes recipes and generation requests in Firestore.
class RecipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore write futures can wait forever when the device is offline,
  // so we never wait longer than this.
  static const Duration _writeTimeout = Duration(seconds: 6);

  /// Keep a record of what the user asked for (GENERATION_REQUEST).
  Future<void> saveRequest(GenerationRequest request, String userId) async {
    try {
      await _db
          .collection('generation_requests')
          .add(request.toMap(userId))
          .timeout(_writeTimeout);
    } catch (e) {
      debugPrint('saveRequest failed: $e');
    }
  }

  /// Store the generated recipe (RECIPE) and return its document id.
  Future<String> saveRecipe(Recipe recipe) async {
    final ref = _db.collection('recipes').doc();
    try {
      await ref.set(recipe.toMap()).timeout(_writeTimeout);
    } catch (e) {
      debugPrint('saveRecipe failed: $e');
    }
    return ref.id;
  }
}
