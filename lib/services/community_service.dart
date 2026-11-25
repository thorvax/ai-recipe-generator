import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment.dart';
import '../models/post_stats.dart';
import '../models/posted_recipe.dart';
import '../models/rating.dart';
import '../models/recipe.dart';

/// Firestore access for the community: posts, likes, ratings, comments and
/// the per-post counters (post_stats). No UI code here.
///
/// Every like, comment and rating also updates post_stats/{postId} in the
/// same batch or transaction; the Firestore rules refuse it otherwise.
class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Duration timeout = Duration(seconds: 8);

  /// Writes that carry a photo (up to ~400 KB) need longer on slow mobile
  /// data. Note: a timeout only stops *waiting*; Firestore still finishes
  /// the queued write in the background.
  static const Duration photoTimeout = Duration(seconds: 30);

  /// Posts per page in the feed ("Load more" adds another page).
  /// Kept small because posts can carry a photo.
  static const int feedPageSize = 20;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posted_recipes');

  DocumentReference<Map<String, dynamic>> _statsRef(String postId) =>
      _db.collection('post_stats').doc(postId);

  // ---------- posts ----------

  /// Newest [limit] posts, live.
  Stream<List<PostedRecipe>> watchPosts({int limit = feedPageSize}) {
    return _posts
        .orderBy('posted_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PostedRecipe.fromMap(d.data(), id: d.id))
            .toList());
  }

  /// One post, live. Emits null when it does not exist (deleted/removed).
  /// The detail screen uses this so it does not depend on the feed page.
  Stream<PostedRecipe?> watchPost(String postId) {
    return _posts.doc(postId).snapshots().map((d) {
      final data = d.data();
      return data == null ? null : PostedRecipe.fromMap(data, id: d.id);
    });
  }

  /// Loads posts by id (for the sorted feeds). Missing posts are skipped.
  /// Posts never change after they are created, so callers may cache them.
  Future<List<PostedRecipe>> getPosts(List<String> ids) async {
    final result = <PostedRecipe>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final snap = await _posts
          .where(FieldPath.documentId, whereIn: chunk)
          .get()
          .timeout(timeout);
      result.addAll(
        snap.docs.map((d) => PostedRecipe.fromMap(d.data(), id: d.id)),
      );
    }
    return result;
  }

  /// Returns false if this user already posted this recipe.
  ///
  /// If the earlier attempt is still uploading (the user retried after a
  /// timeout), it counts as posted instead of "already posted".
  /// The post's counters start at zero in the same batch.
  Future<bool> createPost({
    required String userId,
    required String posterName,
    required String recipeId,
    required Recipe recipe,
    required String caption,
    String? photoBase64,
  }) async {
    final docId = '${userId}_$recipeId';
    final ref = _posts.doc(docId);

    final existing = await ref.get().timeout(timeout);
    if (existing.exists) return existing.metadata.hasPendingWrites;

    final post = PostedRecipe(
      id: docId,
      userId: userId,
      posterName: posterName,
      recipeId: recipeId,
      caption: caption,
      recipe: recipe,
      photoBase64: photoBase64,
    );
    final batch = _db.batch()
      ..set(ref, post.toMap())
      ..set(_statsRef(docId), PostStats.zeroMap());
    await batch.commit().timeout(photoBase64 == null ? timeout : photoTimeout);
    return true;
  }

  /// Deletes the post and its counters.
  Future<void> deletePost(String postId) {
    final batch = _db.batch()
      ..delete(_posts.doc(postId))
      ..delete(_statsRef(postId));
    return batch.commit().timeout(timeout);
  }

  // ---------- counters ----------

  /// The post's counters, live (null until they exist).
  Stream<PostStats?> watchStats(String postId) {
    return _statsRef(postId).snapshots().map((d) {
      final data = d.data();
      return data == null ? null : PostStats.fromMap(data);
    });
  }

  /// The post's counters once (null if this post has none yet).
  Future<PostStats?> getStats(String postId) async {
    final snap = await _statsRef(postId).get().timeout(timeout);
    final data = snap.data();
    return data == null ? null : PostStats.fromMap(data);
  }

  /// Post ids with their counters, ordered by [field] (highest first), live.
  Stream<List<(String, PostStats)>> watchTopStats(String field, int limit) {
    return _db
        .collection('post_stats')
        .orderBy(field, descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs) (d.id, PostStats.fromMap(d.data())),
            ]);
  }

  // ---------- likes ----------

  /// Whether [userId] likes the post, live.
  Stream<bool> watchLiked(String postId, String userId) {
    return _posts
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((d) => d.exists);
  }

  /// Likes or unlikes the post. The like and the counter change together.
  Future<void> setPostLike({
    required String postId,
    required String userId,
    required bool liked,
  }) {
    final likeRef = _posts.doc(postId).collection('likes').doc(userId);
    final batch = _db.batch();
    if (liked) {
      batch.set(likeRef, {
        'user_id': userId,
        'post_id': postId,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      batch.delete(likeRef);
    }
    batch.set(
      _statsRef(postId),
      {'like_count': FieldValue.increment(liked ? 1 : -1)},
      SetOptions(merge: true),
    );
    return batch.commit().timeout(timeout);
  }

  // ---------- ratings ----------

  Stream<List<Rating>> watchRatings(String postId) {
    return _posts
        .doc(postId)
        .collection('ratings')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Rating.fromMap(d.data())).toList());
  }

  Future<List<Rating>> getRatings(String postId) async {
    final snap =
        await _posts.doc(postId).collection('ratings').get().timeout(timeout);
    return snap.docs.map((d) => Rating.fromMap(d.data())).toList();
  }

  /// Document id = userId, so each user can rate a post only once.
  /// A transaction keeps the count, sum and average exact even when two
  /// people rate at the same time.
  Future<void> addRating({
    required String postId,
    required String userId,
    required int value,
  }) {
    final rating = Rating(postId: postId, userId: userId, value: value);
    final ratingRef = _posts.doc(postId).collection('ratings').doc(userId);
    final statsRef = _statsRef(postId);
    return _db.runTransaction((tx) async {
      final statsSnap = await tx.get(statsRef);
      final data = statsSnap.data();
      final before = data == null ? PostStats.zero : PostStats.fromMap(data);
      tx.set(ratingRef, rating.toMap());
      tx.set(
        statsRef,
        PostStats.ratingFieldsAfter(before, value),
        SetOptions(merge: true),
      );
    }).timeout(timeout);
  }

  // ---------- comments ----------

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _posts.doc(postId).collection('comments');

  Stream<List<Comment>> watchComments(String postId) {
    return _comments(postId)
        .orderBy('created_at')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Comment.fromMap(d.data(), id: d.id))
            .toList());
  }

  /// The counter change that goes with adding/removing comment [commentId].
  Map<String, dynamic> _commentCount(String commentId, int delta) => {
        'comment_count': FieldValue.increment(delta),
        'last_comment_id': commentId,
      };

  /// Adds a comment, or a reply when [parentId] is set.
  ///
  /// [commentId] is chosen by the composer and reused when the user taps
  /// send again after an error. If that comment is already saved or still
  /// uploading, nothing is written again, so a retry never duplicates it.
  Future<void> addComment({
    required String postId,
    required String commentId,
    required String userId,
    required String userName,
    required String text,
    String? parentId,
    String? replyToUserName,
    String? photoBase64,
  }) async {
    final ref = _comments(postId).doc(commentId);
    if (await _existsLocally(ref)) return;

    final comment = Comment(
      id: ref.id,
      postId: postId,
      userId: userId,
      userName: userName,
      text: text,
      parentId: parentId,
      replyToUserName: replyToUserName,
      photoBase64: photoBase64,
    );
    final batch = _db.batch()
      ..set(ref, comment.toMap())
      ..set(
        _statsRef(postId),
        _commentCount(commentId, 1),
        SetOptions(merge: true),
      );
    await batch.commit().timeout(photoBase64 == null ? timeout : photoTimeout);
  }

  /// True when the device already has this document, including a write
  /// that is still waiting to upload. Reads the local cache only (instant).
  Future<bool> _existsLocally(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final snap = await ref.get(const GetOptions(source: Source.cache));
      return snap.exists;
    } catch (_) {
      return false; // not in the cache
    }
  }

  /// Keeps the comment as a "deleted" placeholder so its replies stay
  /// readable. Only the fields the rules allow are changed, and the
  /// comment count goes down.
  Future<void> softDeleteComment({
    required String postId,
    required String commentId,
  }) {
    final batch = _db.batch()
      ..update(_comments(postId).doc(commentId), {
        'deleted': true,
        'comment_text': '',
        'photo_b64': FieldValue.delete(),
      })
      ..set(
        _statsRef(postId),
        _commentCount(commentId, -1),
        SetOptions(merge: true),
      );
    return batch.commit().timeout(timeout);
  }

  /// Removes the comment. [countIt] is false for a comment that was already
  /// a "deleted" placeholder (it was taken off the count back then).
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    bool countIt = true,
  }) {
    final batch = _db.batch()..delete(_comments(postId).doc(commentId));
    if (countIt) {
      batch.set(
        _statsRef(postId),
        _commentCount(commentId, -1),
        SetOptions(merge: true),
      );
    }
    return batch.commit().timeout(timeout);
  }

  /// Adds or removes [userId]'s heart. Only liked_by changes.
  Future<void> setCommentLike({
    required String postId,
    required String commentId,
    required String userId,
    required bool liked,
  }) {
    return _comments(postId).doc(commentId).update({
      'liked_by': liked
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    }).timeout(timeout);
  }
}
