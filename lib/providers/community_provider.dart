import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/comment.dart';
import '../models/posted_recipe.dart';
import '../models/rating.dart';
import '../models/recipe.dart';
import '../services/community_service.dart';

/// State for the Community tab: the feed of posts, plus post / rate /
/// comment actions. Actions return an error message, or null on success.
class CommunityProvider extends ChangeNotifier {
  final CommunityService _service = CommunityService();

  StreamSubscription<List<PostedRecipe>>? _sub;
  String? _userId;
  List<PostedRecipe> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Average rating per post, for the feed cards (loaded lazily, cached).
  final Map<String, RatingStats> _stats = {};
  final Set<String> _loadingStats = {};

  List<PostedRecipe> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listen(String userId) {
    if (_userId == userId && _sub != null) return;
    _sub?.cancel();
    _userId = userId;
    _posts = [];
    _isLoading = true;
    _errorMessage = null;
    _stats.clear();
    notifyListeners();

    _sub = _service.watchPosts().listen(
      (list) {
        _posts = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('posts stream error: $e');
        _isLoading = false;
        _errorMessage = 'Could not load community recipes.';
        notifyListeners();
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _userId = null;
    _posts = [];
    _isLoading = true;
    _errorMessage = null;
    _stats.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  PostedRecipe? findPost(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---------- rating stats for feed cards ----------

  RatingStats? statsFor(String postId) => _stats[postId];

  Future<void> loadStats(String postId, {bool force = false}) async {
    if (!force && (_stats.containsKey(postId) || _loadingStats.contains(postId))) {
      return;
    }
    _loadingStats.add(postId);
    try {
      final ratings = await _service.getRatings(postId);
      _stats[postId] = RatingStats.fromRatings(ratings);
    } catch (e) {
      debugPrint('loadStats failed: $e');
    } finally {
      _loadingStats.remove(postId);
      notifyListeners();
    }
  }

  // ---------- streams for the detail screen ----------

  Stream<List<Rating>> ratingsStream(String postId) =>
      _service.watchRatings(postId);

  Stream<List<Comment>> commentsStream(String postId) =>
      _service.watchComments(postId);

  // ---------- actions ----------

  Future<String?> post({
    required String userId,
    required String posterName,
    required String recipeId,
    required Recipe recipe,
    required String caption,
  }) async {
    try {
      final created = await _service.createPost(
        userId: userId,
        posterName: posterName,
        recipeId: recipeId,
        recipe: recipe,
        caption: caption,
      );
      return created ? null : 'You already posted this recipe.';
    } catch (e) {
      return _errorFor(e);
    }
  }

  Future<String?> deletePost(String postId) =>
      _run(() => _service.deletePost(postId));

  Future<String?> rate({
    required String postId,
    required String userId,
    required int value,
  }) async {
    final error = await _run(
      () => _service.addRating(postId: postId, userId: userId, value: value),
    );
    if (error == null) await loadStats(postId, force: true);
    return error;
  }

  Future<String?> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
  }) {
    return _run(() => _service.addComment(
          postId: postId,
          userId: userId,
          userName: userName,
          text: text,
        ));
  }

  Future<String?> deleteComment(String postId, String commentId) => _run(
        () => _service.deleteComment(postId: postId, commentId: commentId),
      );

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (e) {
      return _errorFor(e);
    }
  }

  String _errorFor(Object e) {
    debugPrint('community action failed: $e');
    if (e is TimeoutException) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
