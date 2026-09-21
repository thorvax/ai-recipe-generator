import 'package:cloud_firestore/cloud_firestore.dart';

/// COMMENT entity. Stored at posted_recipes/{postId}/comments/{commentId}.
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String text;
  final DateTime? createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.text,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'comment_id': id,
        'post_id': postId,
        'user_id': userId,
        'user_name': userName,
        'comment_text': text,
        'created_at': FieldValue.serverTimestamp(),
      };

  factory Comment.fromMap(Map<String, dynamic> map, {required String id}) {
    final ts = map['created_at'];
    return Comment(
      id: id,
      postId: map['post_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? 'Cook',
      text: map['comment_text']?.toString() ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
