import 'package:flutter_test/flutter_test.dart';
import 'package:meal_mind/services/report_service.dart';

// Same cases as the website's resources/js/lib/admin-service.test.ts, so a
// report sent from the phone groups with the same report from the website.
void main() {
  group('targetKey', () {
    test('gives each kind of target its own key', () {
      ReportTarget target(ReportType type) => ReportTarget(
            type: type,
            postId: 'bob_r1',
            commentId: 'c9',
            targetUserId: 'bob',
          );

      expect(ReportService.targetKey(target(ReportType.post)), 'post_bob_r1');
      expect(
        ReportService.targetKey(target(ReportType.comment)),
        'comment_bob_r1_c9',
      );
      expect(ReportService.targetKey(target(ReportType.avatar)), 'avatar_bob');
    });

    test('reports of the same picture share a key, wherever they came from', () {
      expect(
        ReportService.targetKey(const ReportTarget(
          type: ReportType.avatar,
          postId: 'post-a',
          targetUserId: 'bob',
        )),
        ReportService.targetKey(const ReportTarget(
          type: ReportType.avatar,
          postId: 'post-b',
          commentId: 'c1',
          targetUserId: 'bob',
        )),
      );
    });
  });

  group('reason', () {
    test('is just the reason without details', () {
      expect(ReportService.reason('Spam or scam', '   '), 'Spam or scam');
    });

    test('adds trimmed details and stays within the rule limit', () {
      expect(
        ReportService.reason('Other', '  selling pills '),
        'Other: selling pills',
      );
      expect(
        ReportService.reason('Other', 'x' * 500).length,
        lessThanOrEqualTo(300),
      );
    });
  });

  test('type names match the Firestore rules', () {
    expect(ReportType.values.map((type) => type.name), [
      'post',
      'comment',
      'avatar',
    ]);
  });
}
