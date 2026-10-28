import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/recipe_ingredient.dart';
import '../../../shared/widgets/app_text_field.dart';

/// Editable list of ingredient rows (name, quantity, unit) with add/remove.
/// Used by the recipe editor for both manual entry and editing.
class IngredientListEditor extends StatefulWidget {
  final List<RecipeIngredient> initial;
  final ValueChanged<List<RecipeIngredient>> onChanged;

  const IngredientListEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<IngredientListEditor> createState() => _IngredientListEditorState();
}

class _IngredientListEditorState extends State<IngredientListEditor> {
  late final List<_Row> _rows = widget.initial.isEmpty
      ? [_Row()]
      : [for (final i in widget.initial) _Row.from(i)];

  void _emit() {
    final list = _rows
        .where((r) => r.name.text.trim().isNotEmpty)
        .map((r) => RecipeIngredient(
              name: r.name.text.trim(),
              quantity: r.quantity.text.trim(),
              unit: r.unit.text.trim(),
            ))
        .toList();
    widget.onChanged(list);
  }

  void _add() => setState(() => _rows.add(_Row()));

  void _remove(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      if (_rows.isEmpty) _rows.add(_Row());
    });
    _emit();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    hint: 'Ingredient name',
                    controller: _rows[i].name,
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    hint: 'Amount',
                    controller: _rows[i].quantity,
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    hint: 'Unit',
                    controller: _rows[i].unit,
                    onChanged: (_) => _emit(),
                  ),
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
            'Add ingredient',
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

class _Row {
  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;

  _Row()
      : name = TextEditingController(),
        quantity = TextEditingController(),
        unit = TextEditingController();

  _Row.from(RecipeIngredient i)
      : name = TextEditingController(text: i.name),
        quantity = TextEditingController(text: i.quantity),
        unit = TextEditingController(text: i.unit);

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
  }
}
