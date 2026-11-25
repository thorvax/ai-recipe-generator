import 'package:flutter_test/flutter_test.dart';
import 'package:meal_mind/core/utils/comment_thread.dart';
import 'package:meal_mind/models/comment.dart';

Comment c(
  String id, {
  int? minute,
  String? parent,
  bool deleted = false,
  int likes = 0,
}) {
  return Comment(
    id: id,
    postId: 'p1',
    userId: 'u_$id',
    userName: 'User $id',
    text: 'text $id',
    createdAt: minute == null ? null : DateTime.utc(2026, 11, 22, 10, minute),
    parentId: parent,
    deleted: deleted,
    likedBy: [for (var i = 0; i < likes; i++) 'liker$i'],
  );
}

List<String> parentIds(List<CommentThread> t) =>
    t.map((x) => x.parent.id).toList();
List<String> replyIds(CommentThread t) => t.replies.map((x) => x.id).toList();

void main() {
  group('buildThreads', () {
    test('groups replies under parents, both oldest first', () {
      final threads = buildThreads([
        c('b', minute: 5),
        c('r2', minute: 9, parent: 'a'),
        c('a', minute: 1),
        c('r1', minute: 3, parent: 'a'),
      ]);
      expect(parentIds(threads), ['a', 'b']);
      expect(replyIds(threads[0]), ['r1', 'r2']);
      expect(threads[1].replies, isEmpty);
    });

    test('pending comments (no server time) sort last', () {
      final threads = buildThreads([
        c('pending'),
        c('a', minute: 1),
        c('rp', parent: 'a'),
        c('r1', minute: 2, parent: 'a'),
      ]);
      expect(parentIds(threads), ['a', 'pending']);
      expect(replyIds(threads[0]), ['r1', 'rp']);
    });

    test('orphan replies hang under a synthetic deleted parent', () {
      final threads = buildThreads([
        c('a', minute: 1),
        c('o2', minute: 8, parent: 'gone'),
        c('o1', minute: 4, parent: 'gone'),
      ]);
      expect(parentIds(threads), ['a', 'gone']);
      final orphan = threads[1];
      expect(orphan.synthetic, isTrue);
      expect(orphan.parentGone, isTrue);
      expect(replyIds(orphan), ['o1', 'o2']);
    });

    test('tombstone with replies stays, tombstone without is dropped', () {
      final threads = buildThreads([
        c('kept', minute: 1, deleted: true),
        c('r', minute: 2, parent: 'kept'),
        c('dropped', minute: 3, deleted: true),
      ]);
      expect(parentIds(threads), ['kept']);
      expect(threads[0].parentGone, isTrue);
      expect(threads[0].synthetic, isFalse);
    });

    test('deleted replies are left out', () {
      final threads = buildThreads([
        c('a', minute: 1),
        c('r', minute: 2, parent: 'a', deleted: true),
      ]);
      expect(threads.single.replies, isEmpty);
    });

    test('empty input gives no threads', () {
      expect(buildThreads(const []), isEmpty);
    });
  });

  group('sortThreads', () {
    final threads = buildThreads([
      c('old', minute: 1, likes: 3),
      c('mid', minute: 5, likes: 1),
      c('new', minute: 9, likes: 3),
      c('r', minute: 10, parent: 'old'),
    ]);

    test('recent: newest first, replies keep their order', () {
      final sorted = sortThreads(threads, CommentSort.recent);
      expect(parentIds(sorted), ['new', 'mid', 'old']);
      expect(replyIds(sorted.last), ['r']);
    });

    test('most liked: hearts descending, ties to the newer one', () {
      final sorted = sortThreads(threads, CommentSort.mostLiked);
      expect(parentIds(sorted), ['new', 'old', 'mid']);
    });

    test('recent puts a pending comment first', () {
      final sorted = sortThreads(
        buildThreads([c('a', minute: 1), c('pending')]),
        CommentSort.recent,
      );
      expect(parentIds(sorted), ['pending', 'a']);
    });

    test('does not change the input list', () {
      final before = parentIds(threads);
      sortThreads(threads, CommentSort.recent);
      expect(parentIds(threads), before);
    });
  });

  group('previewReply', () {
    final thread = buildThreads([
      c('a', minute: 0),
      c('r1', minute: 1, parent: 'a', likes: 2),
      c('r2', minute: 2, parent: 'a', likes: 5),
      c('r3', minute: 3, parent: 'a', likes: 5),
      c('r4', minute: 4, parent: 'a'),
    ]).single;

    test('recent: the most recent reply', () {
      expect(previewReply(thread, CommentSort.recent)!.id, 'r4');
    });

    test('most liked: most hearts, ties to the newer one', () {
      expect(previewReply(thread, CommentSort.mostLiked)!.id, 'r3');
    });

    test('null when there are no replies', () {
      final lonely = buildThreads([c('a', minute: 0)]).single;
      expect(previewReply(lonely, CommentSort.recent), isNull);
    });
  });

  group('commentsSince', () {
    final postedAt = DateTime.utc(2026, 11, 22, 10, 5);

    test('hides comments from before the post, keeps later ones', () {
      final kept = commentsSince([
        c('old', minute: 1),
        c('same', minute: 5),
        c('new', minute: 9),
      ], postedAt);
      expect(kept.map((x) => x.id), ['same', 'new']);
    });

    test('keeps comments still being sent (no server time yet)', () {
      final kept = commentsSince([c('pending')], postedAt);
      expect(kept.single.id, 'pending');
    });

    test('keeps everything while the post time is unknown', () {
      final kept = commentsSince([c('old', minute: 1)], null);
      expect(kept.single.id, 'old');
    });
  });

  group('Comment map', () {
    test('new comment writes defaults and leaves out empty fields', () {
      final map = c('a', minute: 1).toMap();
      expect(map['deleted'], false);
      expect(map['liked_by'], isEmpty);
      expect(map.containsKey('parent_id'), isFalse);
      expect(map.containsKey('photo_b64'), isFalse);
      expect(map.containsKey('reply_to_user_name'), isFalse);
    });

    test('reads old comments without the new fields', () {
      final comment = Comment.fromMap({
        'post_id': 'p1',
        'user_id': 'u1',
        'user_name': 'Ana',
        'comment_text': 'hi',
      }, id: 'x');
      expect(comment.parentId, isNull);
      expect(comment.deleted, isFalse);
      expect(comment.likedBy, isEmpty);
      expect(comment.photoBase64, isNull);
    });

    test('reads likes and reply fields', () {
      final comment = Comment.fromMap({
        'parent_id': 'a',
        'reply_to_user_name': 'Ana',
        'liked_by': ['u1', 'u2'],
        'deleted': true,
      }, id: 'x');
      expect(comment.parentId, 'a');
      expect(comment.replyToUserName, 'Ana');
      expect(comment.likeCount, 2);
      expect(comment.isLikedBy('u2'), isTrue);
      expect(comment.deleted, isTrue);
    });
  });
}
