import 'package:cloud_firestore/cloud_firestore.dart';

/// What can be reported to the admins.
enum ReportType { post, comment, avatar }

/// The thing being reported.
class ReportTarget {
  final ReportType type;
  final String postId;

  /// Only for comments.
  final String? commentId;

  /// Who made the post/comment, or whose picture it is.
  final String targetUserId;

  const ReportTarget({
    required this.type,
    required this.postId,
    required this.targetUserId,
    this.commentId,
  });
}

/// Sends reports to `reports/{reporterUid}_{targetKey}`. The website's
/// Admin page (/admin) reads them; admins act there. The format must match
/// the website's resources/js/lib/admin-service.ts and the Firestore rules.
class ReportService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const Duration timeout = Duration(seconds: 8);

  static const List<String> reasons = [
    'Illegal content',
    'Offensive or hateful',
    'Spam or scam',
    'Not about food',
    'Other',
  ];

  static const int maxDetails = 200;

  /// One key per reported thing; reports about the same thing share it.
  static String targetKey(ReportTarget target) {
    switch (target.type) {
      case ReportType.post:
        return 'post_${target.postId}';
      case ReportType.comment:
        return 'comment_${target.postId}_${target.commentId ?? ''}';
      case ReportType.avatar:
        return 'avatar_${target.targetUserId}';
    }
  }

  /// "Spam or scam", or "Other: details" when details were typed.
  static String reason(String reason, String details) {
    var extra = details.trim();
    if (extra.length > maxDetails) extra = extra.substring(0, maxDetails);
    return extra.isEmpty ? reason : '$reason: $extra';
  }

  /// Returns false if this user already reported this thing.
  Future<bool> send({
    required String reporterUid,
    required ReportTarget target,
    required String reason,
  }) async {
    final key = targetKey(target);
    final ref = _db.collection('reports').doc('${reporterUid}_$key');

    final existing = await ref.get().timeout(timeout);
    if (existing.exists) return false;

    await ref.set({
      'reporter_id': reporterUid,
      'target_key': key,
      'type': target.type.name,
      'post_id': target.postId,
      if (target.commentId != null) 'comment_id': target.commentId,
      'target_user_id': target.targetUserId,
      'reason': reason,
      'created_at': FieldValue.serverTimestamp(),
    }).timeout(timeout);
    return true;
  }
}
