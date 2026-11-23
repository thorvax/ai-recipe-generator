import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment.dart';
import '../models/posted_recipe.dart';
import '../models/rating.dart';
import '../models/recipe.dart';

/// Firestore access for the community: posts, ratings, comments.
/// No UI code here.
class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Duration timeout = Duration(seconds: 8);

  /// Posts in the feed. Kept small because posts can carry a photo.
  static const int feedLimit = 20;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posted_recipes');

  // ---------- posts ----------

  /// Newest [feedLimit] posts, live.
  Stream<List<PostedRecipe>> watchPosts() {
    return _posts
        .orderBy('posted_at', descending: true)
        .limit(feedLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PostedRecipe.fromMap(d.data(), id: d.id))
            .toList());
  }

  /// Returns false if this user already posted this recipe.
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
    if (existing.exists) return false;

    final post = PostedRecipe(
      id: docId,
      userId: userId,
      posterName: posterName,
      recipeId: recipeId,
      caption: caption,
      recipe: recipe,
      photoBase64: photoBase64,
    );
    await ref.set(post.toMap()).timeout(timeout);
    return true;
  }

  Future<void> deletePost(String postId) =>
      _posts.doc(postId).delete().timeout(timeout);

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
  Future<void> addRating({
    required String postId,
    required String userId,
    required int value,
  }) {
    final rating = Rating(postId: postId, userId: userId, value: value);
    return _posts
        .doc(postId)
        .collection('ratings')
        .doc(userId)
        .set(rating.toMap())
        .timeout(timeout);
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

  /// Adds a comment, or a reply when [parentId] is set.
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
    String? parentId,
    String? replyToUserName,
    String? photoBase64,
  }) {
    final ref = _comments(postId).doc();
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
    return ref.set(comment.toMap()).timeout(timeout);
  }

  /// Keeps the comment as a "deleted" placeholder so its replies stay
  /// readable. Only the fields the rules allow are changed.
  Future<void> softDeleteComment({
    required String postId,
    required String commentId,
  }) {
    return _comments(postId).doc(commentId).update({
      'deleted': true,
      'comment_text': '',
      'photo_b64': FieldValue.delete(),
    }).timeout(timeout);
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _comments(postId).doc(commentId).delete().timeout(timeout);
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
