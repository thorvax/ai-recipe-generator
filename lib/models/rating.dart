import 'package:cloud_firestore/cloud_firestore.dart';

/// RATING entity. Stored at posted_recipes/{postId}/ratings/{userId}.
/// The document id is the rater's user id, so a user can rate a post only once.
class Rating {
  final String postId;
  final String userId;
  final int value; // 1 to 5 stars
  final DateTime? createdAt;

  const Rating({
    required this.postId,
    required this.userId,
    required this.value,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'rating_id': userId,
        'post_id': postId,
        'user_id': userId,
        'rating_value': value,
        'created_at': FieldValue.serverTimestamp(),
      };

  factory Rating.fromMap(Map<String, dynamic> map) {
    final ts = map['created_at'];
    return Rating(
      postId: map['post_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      value: (map['rating_value'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Average + count, calculated from the RATING records (never stored).
class RatingStats {
  final double average;
  final int count;

  const RatingStats({required this.average, required this.count});

  factory RatingStats.fromRatings(List<Rating> ratings) {
    if (ratings.isEmpty) return const RatingStats(average: 0, count: 0);
    final total = ratings.fold<int>(0, (sum, r) => sum + r.value);
    return RatingStats(average: total / ratings.length, count: ratings.length);
  }
}
