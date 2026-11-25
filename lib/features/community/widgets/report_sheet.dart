import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/report_service.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

/// One thing the user can report, e.g. "This post" or "Their profile picture".
class ReportSubject {
  final String label;
  final ReportTarget target;

  const ReportSubject(this.label, this.target);
}

/// Opens the report sheet. The first subject is picked by default.
Future<void> showReportSheet(
  BuildContext context, {
  required String reporterUid,
  required List<ReportSubject> subjects,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r24)),
    ),
    builder: (_) => _ReportSheet(reporterUid: reporterUid, subjects: subjects),
  );
}

class _ReportSheet extends StatefulWidget {
  final String reporterUid;
  final List<ReportSubject> subjects;

  const _ReportSheet({required this.reporterUid, required this.subjects});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _details = TextEditingController();
  int _subject = 0;
  String? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null) return;
    setState(() => _sending = true);

    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final sent = await ReportService().send(
        reporterUid: widget.reporterUid,
        target: widget.subjects[_subject].target,
        reason: ReportService.reason(reason, _details.text),
      );
      message = sent
          ? 'Thanks. An admin will check it.'
          : 'You already reported this. An admin will check it.';
    } on TimeoutException {
      message = 'Could not reach the server. Check your connection and try again.';
    } catch (e) {
      debugPrint('report failed: $e');
      message = 'Something went wrong. Please try again.';
    }

    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keeps the text field above the keyboard.
      padding: EdgeInsets.only(
        left: AppSpacing.s24,
        right: AppSpacing.s24,
        top: AppSpacing.s24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Admins can remove things that break the rules. '
              'Your name is not shown to the person you report.',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
            if (widget.subjects.length > 1) ...[
              const SizedBox(height: AppSpacing.s16),
              Text('What are you reporting?', style: AppTextStyles.body2),
              const SizedBox(height: AppSpacing.s8),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (var i = 0; i < widget.subjects.length; i++)
                    AppChip(
                      label: widget.subjects[i].label,
                      selected: i == _subject,
                      onTap: () => setState(() => _subject = i),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            Text('Why?', style: AppTextStyles.body2),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final reason in ReportService.reasons)
                  AppChip(
                    label: reason,
                    selected: reason == _reason,
                    onTap: () => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              label: 'Details (optional)',
              controller: _details,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Send report',
              isLoading: _sending,
              onPressed: _reason == null ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
