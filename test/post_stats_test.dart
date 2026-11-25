import 'package:flutter_test/flutter_test.dart';
import 'package:meal_mind/models/post_stats.dart';

void main() {
  group('PostStats.fromMap', () {
    test('reads every counter', () {
      final stats = PostStats.fromMap({
        'like_count': 4,
        'comment_count': 7,
        'rating_count': 2,
        'rating_sum': 9,
        'rating_avg': 4.5,
      });
      expect(stats.likeCount, 4);
      expect(stats.commentCount, 7);
      expect(stats.ratingCount, 2);
      expect(stats.ratingSum, 9);
      expect(stats.ratingAvg, 4.5);
      expect(stats.average, 4.5); // same names as RatingStats
      expect(stats.count, 2);
    });

    test('missing counters (an older post) are zero', () {
      final stats = PostStats.fromMap({'like_count': 1});
      expect(stats.likeCount, 1);
      expect(stats.commentCount, 0);
      expect(stats.ratingAvg, 0);
    });

    test('a whole-number average stored as an int still reads', () {
      // The website stores 5 / 1 as the int 5.
      expect(PostStats.fromMap({'rating_avg': 5}).ratingAvg, 5.0);
    });
  });

  group('PostStats.ratingFieldsAfter', () {
    test('first rating', () {
      expect(PostStats.ratingFieldsAfter(PostStats.zero, 4), {
        'rating_count': 1,
        'rating_sum': 4,
        'rating_avg': 4.0,
      });
    });

    test('adds to the existing count and sum, average = sum / count', () {
      const before = PostStats(ratingCount: 2, ratingSum: 9, ratingAvg: 4.5);
      final after = PostStats.ratingFieldsAfter(before, 3);
      expect(after['rating_count'], 3);
      expect(after['rating_sum'], 12);
      expect(after['rating_avg'], 4.0);
    });

    test('average keeps decimals', () {
      const before = PostStats(ratingCount: 2, ratingSum: 9, ratingAvg: 4.5);
      final after = PostStats.ratingFieldsAfter(before, 5);
      expect(after['rating_avg'], closeTo(4.6667, 0.0001));
    });
  });

  test('zeroMap starts every counter at zero', () {
    expect(PostStats.zeroMap().values, everyElement(0));
    expect(PostStats.zeroMap().containsKey('last_comment_id'), isFalse);
  });

  test('each sort uses the matching post_stats field', () {
    expect(FeedSort.newest.statsField, isNull);
    expect(FeedSort.mostLiked.statsField, 'like_count');
    expect(FeedSort.mostCommented.statsField, 'comment_count');
    expect(FeedSort.topRated.statsField, 'rating_avg');
  });
}
