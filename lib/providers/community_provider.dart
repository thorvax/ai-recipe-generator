import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/community_filters.dart';
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

  // ---------- feed search + dietary filters (this session only) ----------

  String _searchQuery = '';
  // Lower-cased dietary filters that are switched on.
  final Set<String> _activeDiet = {};
  // The saved dietary preferences last applied as defaults (lower-cased).
  Set<String> _appliedDefaults = {};

  String get searchQuery => _searchQuery;
  Set<String> get activeDiet => Set.unmodifiable(_activeDiet);
  bool get hasActiveFilters =>
      _activeDiet.isNotEmpty || _searchQuery.trim().isNotEmpty;

  /// True while the active chips are exactly the user's saved preferences
  /// (shows "Showing recipes that match your dietary preferences").
  bool get filtersAreDefaults =>
      _activeDiet.isNotEmpty && setEquals(_activeDiet, _appliedDefaults);

  bool isDietActive(String option) =>
      _activeDiet.contains(option.trim().toLowerCase());

  /// The feed after search and dietary filters.
  List<PostedRecipe> get visiblePosts =>
      filterPosts(_posts, query: _searchQuery, diet: _activeDiet);

  void setSearch(String query) {
    if (query == _searchQuery) return;
    _searchQuery = query;
    notifyListeners();
  }

  void toggleDiet(String option) {
    final key = option.trim().toLowerCase();
    if (!_activeDiet.remove(key)) _activeDiet.add(key);
    notifyListeners();
  }

  /// Turns off all dietary chips (and the search too when [search] is set).
  void clearFilters({bool search = false}) {
    _activeDiet.clear();
    if (search) _searchQuery = '';
    notifyListeners();
  }

  /// True when [saved] was already applied (no sync needed).
  bool defaultsApplied(List<String> saved) =>
      setEquals(_lower(saved), _appliedDefaults);

  /// Applies the saved dietary preferences as default filters. Like the
  /// Home screen, only the difference is applied, so chips the user
  /// toggled by hand are not wiped when the preferences change.
  void syncDietaryDefaults(List<String> saved) {
    final defaults = _lower(saved);
    if (setEquals(defaults, _appliedDefaults)) return;
    final added = defaults.difference(_appliedDefaults);
    final removed = _appliedDefaults.difference(defaults);
    _appliedDefaults = defaults;
    _activeDiet
      ..addAll(added)
      ..removeAll(removed);
    notifyListeners();
  }

  static Set<String> _lower(Iterable<String> values) => values
      .map((v) => v.trim().toLowerCase())
      .where((v) => v.isNotEmpty)
      .toSet();

  void _resetFilters() {
    _searchQuery = '';
    _activeDiet.clear();
    _appliedDefaults = {};
  }

  void listen(String userId) {
    if (_userId == userId && _sub != null) return;
    _sub?.cancel();
    _userId = userId;
    _posts = [];
    _isLoading = true;
    _errorMessage = null;
    _stats.clear();
    _resetFilters();
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
    _resetFilters();
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
    String? photoBase64,
  }) async {
    try {
      final created = await _service.createPost(
        userId: userId,
        posterName: posterName,
        recipeId: recipeId,
        recipe: recipe,
        caption: caption,
        photoBase64: photoBase64,
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

  /// Adds a comment, or a reply when [parentId] is set.
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
    String? parentId,
    String? replyToUserName,
    String? photoBase64,
  }) {
    return _run(() => _service.addComment(
          postId: postId,
          userId: userId,
          userName: userName,
          text: text,
          parentId: parentId,
          replyToUserName: replyToUserName,
          photoBase64: photoBase64,
        ));
  }

  /// A top-level comment that still has replies becomes a "deleted"
  /// placeholder so the replies stay readable. Anything else is removed.
  Future<String?> deleteComment(
    String postId,
    Comment comment, {
    required bool hasReplies,
  }) {
    if (!comment.isReply && hasReplies) {
      return _run(() => _service.softDeleteComment(
            postId: postId,
            commentId: comment.id,
          ));
    }
    return _run(
      () => _service.deleteComment(postId: postId, commentId: comment.id),
    );
  }

  /// Hearts or un-hearts a comment for [userId].
  Future<String?> toggleCommentLike(
    String postId,
    Comment comment,
    String userId,
  ) {
    return _run(() => _service.setCommentLike(
          postId: postId,
          commentId: comment.id,
          userId: userId,
          liked: !comment.isLikedBy(userId),
        ));
  }

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
