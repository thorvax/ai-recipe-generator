import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/recipe_step.dart';
import '../../../shared/widgets/app_text_field.dart';

/// Editable, ordered list of cooking steps with add/remove/reorder.
/// Used by the recipe editor for both manual entry and editing.
class StepListEditor extends StatefulWidget {
  final List<RecipeStep> initial;
  final ValueChanged<List<RecipeStep>> onChanged;

  const StepListEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<StepListEditor> createState() => _StepListEditorState();
}

class _StepListEditorState extends State<StepListEditor> {
  late final List<TextEditingController> _steps = widget.initial.isEmpty
      ? [TextEditingController()]
      : [
          for (final s in widget.initial)
            TextEditingController(text: s.instruction),
        ];

  void _emit() {
    final list = <RecipeStep>[];
    for (final c in _steps) {
      final text = c.text.trim();
      if (text.isNotEmpty) {
        list.add(RecipeStep(stepNumber: list.length + 1, instruction: text));
      }
    }
    widget.onChanged(list);
  }

  void _add() => setState(() => _steps.add(TextEditingController()));

  void _remove(int index) {
    setState(() {
      _steps[index].dispose();
      _steps.removeAt(index);
      if (_steps.isEmpty) _steps.add(TextEditingController());
    });
    _emit();
  }

  void _move(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _steps.length) return;
    setState(() {
      final item = _steps.removeAt(index);
      _steps.insert(target, item);
    });
    _emit();
  }

  @override
  void dispose() {
    for (final c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: AppSpacing.s12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: AppTextField(
                    hint: 'Describe this step',
                    controller: _steps[i],
                    maxLines: 2,
                    onChanged: (_) => _emit(),
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.keyboard_arrow_up,
                          color: AppColors.textSecondary),
                      onPressed: i == 0 ? null : () => _move(i, -1),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary),
                      onPressed:
                          i == _steps.length - 1 ? null : () => _move(i, 1),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => _remove(i),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: Text(
            'Add step',
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
