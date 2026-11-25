import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/community_filters.dart';
import '../models/comment.dart';
import '../models/post_stats.dart';
import '../models/posted_recipe.dart';
import '../models/rating.dart';
import '../models/recipe.dart';
import '../services/community_service.dart';

/// State for the Community tab: the feed of posts, plus post / rate /
/// comment actions. Actions return an error message, or null on success.
class CommunityProvider extends ChangeNotifier {
  final CommunityService _service = CommunityService();

  StreamSubscription<Object?>? _sub;
  String? _userId;
  List<PostedRecipe> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Counters per post (likes, comments, ratings) for the feed cards.
  // Loaded lazily, or straight from the sorted feed query.
  final Map<String, PostStats> _stats = {};

  // Posts never change after they are created, so the sorted feeds keep
  // the ones they already loaded.
  final Map<String, PostedRecipe> _postCache = {};
  // Ignores results of an older query that arrive after a newer one.
  int _queryGeneration = 0;

  FeedSort _sort = FeedSort.newest;
  FeedSort get sort => _sort;
  final Set<String> _loadingStats = {};

  // Feed paging: the live query grows by one page per "Load more".
  int _limit = CommunityService.feedPageSize;
  bool _hasMore = false;
  bool _loadingMore = false;

  List<PostedRecipe> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// True when older posts may exist beyond the loaded pages.
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

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
    _limit = CommunityService.feedPageSize;
    _hasMore = false;
    _loadingMore = false;
    _sort = FeedSort.newest;
    _postCache.clear();
    notifyListeners();
    _subscribe();
  }

  /// Changes the feed order. Starts again from the first page.
  void setSort(FeedSort sort) {
    if (sort == _sort || _userId == null) return;
    _sort = sort;
    _limit = CommunityService.feedPageSize;
    _hasMore = false;
    _loadingMore = false;
    _isLoading = true;
    _posts = [];
    notifyListeners();
    _subscribe();
  }

  /// (Re)starts the live feed query with the current [_limit]. The posts
  /// already shown stay on screen until the new snapshot arrives.
  void _subscribe() {
    _sub?.cancel();
    final limit = _limit;
    final generation = ++_queryGeneration;
    final field = _sort.statsField;
    if (field != null) {
      _sub = _service.watchTopStats(field, limit).listen(
        (rows) => _showSorted(rows, limit, generation),
        onError: _onFeedError,
      );
      return;
    }
    _sub = _service.watchPosts(limit: limit).listen(
      (list) {
        _posts = list;
        _hasMore = list.length >= limit; // a full page: maybe more exist
        _isLoading = false;
        _loadingMore = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: _onFeedError,
    );
  }

  void _onFeedError(Object e) {
    debugPrint('posts stream error: $e');
    _isLoading = false;
    _loadingMore = false;
    _errorMessage = 'Could not load community recipes.';
    notifyListeners();
  }

  /// A sorted feed: the counters arrive in order; the posts are loaded by
  /// id (only the ones not cached yet) and shown in that order.
  Future<void> _showSorted(
    List<(String, PostStats)> rows,
    int limit,
    int generation,
  ) async {
    for (final (id, stats) in rows) {
      _stats[id] = stats;
    }
    final missing = [
      for (final (id, _) in rows)
        if (!_postCache.containsKey(id)) id,
    ];
    try {
      if (missing.isNotEmpty) {
        for (final post in await _service.getPosts(missing)) {
          _postCache[post.id] = post;
        }
      }
    } catch (e) {
      if (generation == _queryGeneration) _onFeedError(e);
      return;
    }
    if (generation != _queryGeneration) return; // a newer query took over

    _posts = [
      for (final (id, _) in rows)
        if (_postCache[id] != null) _postCache[id]!,
    ];
    _hasMore = rows.length >= limit;
    _isLoading = false;
    _loadingMore = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads one more page of older posts. Search and dietary filters only
  /// look at loaded posts, so this also lets them reach older recipes.
  void loadMore() {
    if (!_hasMore || _loadingMore || _userId == null) return;
    _limit += CommunityService.feedPageSize;
    _loadingMore = true;
    notifyListeners();
    _subscribe();
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
    _limit = CommunityService.feedPageSize;
    _hasMore = false;
    _loadingMore = false;
    _sort = FeedSort.newest;
    _postCache.clear();
    _queryGeneration++;
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

  // ---------- counters for feed cards ----------

  PostStats? statsFor(String postId) => _stats[postId];

  Future<void> loadStats(String postId, {bool force = false}) async {
    if (!force && (_stats.containsKey(postId) || _loadingStats.contains(postId))) {
      return;
    }
    _loadingStats.add(postId);
    try {
      final stats = await _service.getStats(postId);
      if (stats != null) {
        _stats[postId] = stats;
      } else {
        // An older post without counters yet (an admin recount adds them):
        // work out the rating from the ratings themselves.
        final r = RatingStats.fromRatings(await _service.getRatings(postId));
        _stats[postId] = PostStats(
          ratingCount: r.count,
          ratingSum: (r.average * r.count).round(),
          ratingAvg: r.average,
        );
      }
    } catch (e) {
      debugPrint('loadStats failed: $e');
    } finally {
      _loadingStats.remove(postId);
      notifyListeners();
    }
  }

  // ---------- streams for the detail screen ----------

  /// The post itself, live (null once it is deleted or removed).
  Stream<PostedRecipe?> postStream(String postId) =>
      _service.watchPost(postId);

  Stream<List<Rating>> ratingsStream(String postId) =>
      _service.watchRatings(postId);

  Stream<List<Comment>> commentsStream(String postId) =>
      _service.watchComments(postId);

  /// The post's counters (likes, comments, ratings), live.
  Stream<PostStats?> statsStream(String postId) => _service.watchStats(postId);

  /// Whether [userId] likes the post, live.
  Stream<bool> likedStream(String postId, String userId) =>
      _service.watchLiked(postId, userId);

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

  /// Likes or unlikes a post, then refreshes its card's counters.
  Future<String?> setPostLike({
    required String postId,
    required String userId,
    required bool liked,
  }) async {
    final error = await _run(
      () => _service.setPostLike(postId: postId, userId: userId, liked: liked),
    );
    if (error == null) unawaited(loadStats(postId, force: true));
    return error;
  }

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

  /// Adds a comment, or a reply when [parentId] is set. Reuse the same
  /// [commentId] when retrying, so a retry can never post it twice.
  Future<String?> addComment({
    required String postId,
    required String commentId,
    required String userId,
    required String userName,
    required String text,
    String? parentId,
    String? replyToUserName,
    String? photoBase64,
  }) {
    return _run(() => _service.addComment(
          postId: postId,
          commentId: commentId,
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
      () => _service.deleteComment(
        postId: postId,
        commentId: comment.id,
        // A "deleted" placeholder was already taken off the count.
        countIt: !comment.deleted,
      ),
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
