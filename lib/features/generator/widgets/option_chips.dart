import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/add_chip.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/custom_option_dialog.dart';

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
      builder: (_) => CustomOptionDialog(title: widget.otherTitle),
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
        AddChip(label: 'Other', onTap: _addOther),
      ],
    );
  }
}
