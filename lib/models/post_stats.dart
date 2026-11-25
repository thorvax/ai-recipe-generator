/// Counters for one post, stored at post_stats/{postId}.
///
/// They live outside the post so that a like or comment never re-sends the
/// post (and its photo) to everyone viewing the feed. Every like, comment
/// and rating updates them in the same batch/transaction, and the Firestore
/// rules check each change.
class PostStats {
  final int likeCount;
  final int commentCount;
  final int ratingCount;
  final int ratingSum;

  /// ratingSum / ratingCount, stored so the feed can sort by it.
  final double ratingAvg;

  const PostStats({
    this.likeCount = 0,
    this.commentCount = 0,
    this.ratingCount = 0,
    this.ratingSum = 0,
    this.ratingAvg = 0,
  });

  static const zero = PostStats();

  /// Same names as RatingStats, so the rating widgets can use either.
  double get average => ratingAvg;
  int get count => ratingCount;

  factory PostStats.fromMap(Map<String, dynamic> map) {
    int asInt(Object? v) => v is num ? v.toInt() : 0;
    return PostStats(
      likeCount: asInt(map['like_count']),
      commentCount: asInt(map['comment_count']),
      ratingCount: asInt(map['rating_count']),
      ratingSum: asInt(map['rating_sum']),
      ratingAvg: map['rating_avg'] is num
          ? (map['rating_avg'] as num).toDouble()
          : 0,
    );
  }

  /// The counters a brand-new post starts with.
  static Map<String, dynamic> zeroMap() => {
        'like_count': 0,
        'comment_count': 0,
        'rating_count': 0,
        'rating_sum': 0,
        'rating_avg': 0,
      };

  /// The rating fields after adding one [value]-star rating. Written in a
  /// transaction together with the rating itself (the rules check
  /// avg == sum / count).
  static Map<String, dynamic> ratingFieldsAfter(PostStats before, int value) {
    final count = before.ratingCount + 1;
    final sum = before.ratingSum + value;
    return {
      'rating_count': count,
      'rating_sum': sum,
      'rating_avg': sum / count,
    };
  }
}

/// How the community feed is ordered.
enum FeedSort {
  newest('Newest', null),
  mostLiked('Most liked', 'like_count'),
  mostCommented('Most commented', 'comment_count'),
  topRated('Top rated', 'rating_avg');

  const FeedSort(this.label, this.statsField);

  /// Chip text.
  final String label;

  /// The post_stats field to sort by (null = newest posts first).
  final String? statsField;
}
