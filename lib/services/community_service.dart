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

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posted_recipes');

  // ---------- posts ----------

  /// Newest 50 posts, live.
  Stream<List<PostedRecipe>> watchPosts() {
    return _posts
        .orderBy('posted_at', descending: true)
        .limit(50)
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

  Stream<List<Comment>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('created_at')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Comment.fromMap(d.data(), id: d.id))
            .toList());
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
  }) {
    final ref = _posts.doc(postId).collection('comments').doc();
    final comment = Comment(
      id: ref.id,
      postId: postId,
      userId: userId,
      userName: userName,
      text: text,
    );
    return ref.set(comment.toMap()).timeout(timeout);
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _posts
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete()
        .timeout(timeout);
  }
}
