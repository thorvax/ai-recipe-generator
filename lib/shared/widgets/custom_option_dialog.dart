import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_text_field.dart';

/// Small dialog with one text field. Pops with the typed text (or null).
/// Used for "+ Other" options and "+ Custom category".
class CustomOptionDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;

  const CustomOptionDialog({
    super.key,
    required this.title,
    this.confirmLabel = 'Add',
  });

  @override
  State<CustomOptionDialog> createState() => _CustomOptionDialogState();
}

class _CustomOptionDialogState extends State<CustomOptionDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _ctrl.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(widget.title, style: AppTextStyles.heading2),
      content: AppTextField(
        hint: 'Type here...',
        controller: _ctrl,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
