import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_text_field.dart';

/// A group of selectable chips with a "+ Other" chip that lets the user
/// type their own option. Works as single-select or multi-select.
class OptionChips extends StatefulWidget {
  final List<String> options;
  final Set<String> selected;
  final bool multiSelect;
  final ValueChanged<Set<String>> onChanged;
  final String otherTitle; // dialog title, e.g. "Add your own cuisine"

  const OptionChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.otherTitle,
    this.multiSelect = false,
  });

  @override
  State<OptionChips> createState() => _OptionChipsState();
}

class _OptionChipsState extends State<OptionChips> {
  final List<String> _custom = []; // options the user typed themselves

  void _toggle(String option) {
    final next = Set<String>.from(widget.selected);
    if (next.contains(option)) {
      next.remove(option);
    } else {
      if (!widget.multiSelect) next.clear();
      next.add(option);
    }
    widget.onChanged(next);
  }

  Future<void> _addOther() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _CustomOptionDialog(title: widget.otherTitle),
    );
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;

    final all = [...widget.options, ..._custom];
    final existing = all.where((o) => o.toLowerCase() == text.toLowerCase());
    final option = existing.isNotEmpty ? existing.first : text;
    if (existing.isEmpty) setState(() => _custom.add(text));
    if (!widget.selected.contains(option)) _toggle(option);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final option in [...widget.options, ..._custom])
          AppChip(
            label: option,
            selected: widget.selected.contains(option),
            onTap: () => _toggle(option),
          ),
        _OtherChip(onTap: _addOther),
      ],
    );
  }
}

class _OtherChip extends StatelessWidget {
  final VoidCallback onTap;
  const _OtherChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r24),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.s4),
            Text(
              'Other',
              style: AppTextStyles.body2.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomOptionDialog extends StatefulWidget {
  final String title;
  const _CustomOptionDialog({required this.title});

  @override
  State<_CustomOptionDialog> createState() => _CustomOptionDialogState();
}

class _CustomOptionDialogState extends State<_CustomOptionDialog> {
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
            'Add',
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
