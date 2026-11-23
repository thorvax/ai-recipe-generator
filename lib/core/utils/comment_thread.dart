import '../../models/comment.dart';

/// A top-level comment and its replies (oldest → newest).
class CommentThread {
  final Comment parent;
  final List<Comment> replies;

  /// True when [parent] is a stand-in for a parent that no longer exists.
  final bool synthetic;

  const CommentThread({
    required this.parent,
    required this.replies,
    this.synthetic = false,
  });

  /// Deleted parent (tombstone) or a missing one.
  bool get parentGone => synthetic || parent.deleted;
}

/// How the comment threads are ordered.
enum CommentSort { recent, mostLiked }

/// A comment still being written (no server time yet) counts as the newest.
final DateTime _pending = DateTime.utc(9999);
DateTime _timeOf(Comment c) => c.createdAt ?? _pending;

int _oldestFirst(Comment a, Comment b) => _timeOf(a).compareTo(_timeOf(b));
int _newestFirst(Comment a, Comment b) => _timeOf(b).compareTo(_timeOf(a));

/// Most hearts first; ties go to the newer comment.
int _mostLikedFirst(Comment a, Comment b) {
  final byLikes = b.likeCount.compareTo(a.likeCount);
  return byLikes != 0 ? byLikes : _newestFirst(a, b);
}

/// Groups a flat comment list into threads.
///
/// - Top-level comments and replies are sorted oldest → newest.
/// - Replies whose parent is missing hang under a synthetic deleted parent.
/// - Deleted parents with no replies left are dropped.
/// - Deleted replies are dropped (replies are normally hard-deleted).
List<CommentThread> buildThreads(List<Comment> comments) {
  final parents = <String, Comment>{};
  final repliesByParent = <String, List<Comment>>{};

  for (final c in comments) {
    final parentId = c.parentId;
    if (parentId == null) {
      parents[c.id] = c;
    } else if (!c.deleted) {
      (repliesByParent[parentId] ??= []).add(c);
    }
  }

  final threads = <CommentThread>[];

  for (final parent in parents.values) {
    final replies = repliesByParent.remove(parent.id) ?? <Comment>[];
    if (parent.deleted && replies.isEmpty) continue;
    replies.sort(_oldestFirst);
    threads.add(CommentThread(parent: parent, replies: replies));
  }

  // Orphans: their parent was hard-deleted (or is not loaded).
  repliesByParent.forEach((parentId, replies) {
    replies.sort(_oldestFirst);
    final first = replies.first;
    threads.add(CommentThread(
      parent: Comment(
        id: parentId,
        postId: first.postId,
        userId: '',
        userName: '',
        text: '',
        createdAt: first.createdAt,
        deleted: true,
      ),
      replies: replies,
      synthetic: true,
    ));
  });

  threads.sort((a, b) => _oldestFirst(a.parent, b.parent));
  return threads;
}

/// Orders threads by their top-level comment. Replies keep their order.
/// - [CommentSort.recent]: newest first.
/// - [CommentSort.mostLiked]: most hearts first, ties to the newer one.
List<CommentThread> sortThreads(List<CommentThread> threads, CommentSort mode) {
  final sorted = List<CommentThread>.of(threads);
  final compare = mode == CommentSort.recent ? _newestFirst : _mostLikedFirst;
  sorted.sort((a, b) => compare(a.parent, b.parent));
  return sorted;
}

/// The one reply shown while a thread is collapsed: the most recent one
/// under [CommentSort.recent], the most hearted under [CommentSort.mostLiked].
/// Null when there are no replies.
Comment? previewReply(CommentThread thread, CommentSort mode) {
  if (thread.replies.isEmpty) return null;
  final compare = mode == CommentSort.recent ? _newestFirst : _mostLikedFirst;
  return thread.replies.reduce((a, b) => compare(a, b) <= 0 ? a : b);
}
