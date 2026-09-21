import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';

/// Bottom sheet asking for an optional caption before posting.
/// Returns the caption (may be empty), or null if dismissed.
Future<String?> showPostRecipeSheet(
  BuildContext context, {
  required String recipeName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r24)),
    ),
    builder: (_) => _PostRecipeSheet(recipeName: recipeName),
  );
}

class _PostRecipeSheet extends StatefulWidget {
  final String recipeName;
  const _PostRecipeSheet({required this.recipeName});

  @override
  State<_PostRecipeSheet> createState() => _PostRecipeSheetState();
}

class _PostRecipeSheetState extends State<_PostRecipeSheet> {
  static const _maxLength = 200;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    var caption = _ctrl.text.trim();
    if (caption.length > _maxLength) caption = caption.substring(0, _maxLength);
    Navigator.pop(context, caption);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24, AppSpacing.s12, AppSpacing.s24, AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.r4),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text('Post to community', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Share "${widget.recipeName}" so other cooks can view, rate and comment on it.',
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s16),
              AppTextField(
                hint: 'Add a caption (optional)',
                controller: _ctrl,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.s24),
              PrimaryButton(label: 'Post Recipe', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
