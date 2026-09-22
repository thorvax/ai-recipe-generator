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

  @override
  void initState() {
    super.initState();
    // A pre-filled selection (e.g. from saved Dietary Preferences) may
    // include a custom option that isn't in the preset list. Without this,
    // it would be "selected" but have no chip to show for it.
    for (final option in widget.selected) {
      final inPresets =
          widget.options.any((o) => o.toLowerCase() == option.toLowerCase());
      if (!inPresets) _custom.add(option);
    }
  }

  @override
  void didUpdateWidget(OptionChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Covers a selection that arrives after the first build (e.g. the
    // parent screen loads saved preferences via a post-frame callback).
    for (final option in widget.selected) {
      final known = widget.options.any((o) => o.toLowerCase() == option.toLowerCase()) ||
          _custom.any((o) => o.toLowerCase() == option.toLowerCase());
      if (!known) setState(() => _custom.add(option));
    }
  }

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
