import 'package:cloud_firestore/cloud_firestore.dart';

/// COMMENT entity. Stored at posted_recipes/{postId}/comments/{commentId}.
///
/// Replies are one level deep: a reply's [parentId] is always the id of a
/// top-level comment (null for top-level comments).
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String text;
  final DateTime? createdAt;

  /// Top-level comment this replies to, or null for a top-level comment.
  final String? parentId;

  /// Name of the person being replied to (shown as "@Name").
  final String? replyToUserName;

  /// Optional photo: a compressed base64 JPEG (photo_b64).
  final String? photoBase64;

  /// Soft-deleted top-level comment that still has replies ("tombstone").
  final bool deleted;

  /// Uids of users who hearted this comment.
  final List<String> likedBy;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    this.createdAt,
    this.parentId,
    this.replyToUserName,
    this.photoBase64,
    this.deleted = false,
    this.likedBy = const [],
  });

  bool get isReply => parentId != null;
  int get likeCount => likedBy.length;
  bool isLikedBy(String uid) => likedBy.contains(uid);

  /// New comment document. Null fields are left out (the rules allow them
  /// to be missing).
  Map<String, dynamic> toMap() => {
        'comment_id': id,
        'post_id': postId,
        'user_id': userId,
        'user_name': userName,
        'comment_text': text,
        'created_at': FieldValue.serverTimestamp(),
        if (parentId != null) 'parent_id': parentId,
        if (replyToUserName != null) 'reply_to_user_name': replyToUserName,
        if (photoBase64 != null) 'photo_b64': photoBase64,
        'deleted': false,
        'liked_by': <String>[],
      };

  factory Comment.fromMap(Map<String, dynamic> map, {required String id}) {
    final ts = map['created_at'];
    final parent = map['parent_id'];
    final replyTo = map['reply_to_user_name'];
    final photo = map['photo_b64'];
    final likes = map['liked_by'];
    return Comment(
      id: id,
      postId: map['post_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? 'Cook',
      text: map['comment_text']?.toString() ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
      parentId: (parent is String && parent.isNotEmpty) ? parent : null,
      replyToUserName:
          (replyTo is String && replyTo.isNotEmpty) ? replyTo : null,
      photoBase64: (photo is String && photo.isNotEmpty) ? photo : null,
      deleted: map['deleted'] == true,
      likedBy: likes is List ? likes.whereType<String>().toList() : const [],
    );
  }
}
