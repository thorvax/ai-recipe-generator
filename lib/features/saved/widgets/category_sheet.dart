import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/category.dart';
import '../../../providers/saved_provider.dart';
import '../../../shared/widgets/add_chip.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/custom_option_dialog.dart';
import '../../../shared/widgets/primary_button.dart';

/// Opens the "Choose a category" bottom sheet.
/// Returns the chosen category name, or null if the user dismissed it.
Future<String?> showCategorySheet(
  BuildContext context, {
  String? initial,
  String confirmLabel = 'Save Recipe',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r24)),
    ),
    builder: (_) => _CategorySheet(initial: initial, confirmLabel: confirmLabel),
  );
}

class _CategorySheet extends StatefulWidget {
  final String? initial;
  final String confirmLabel;

  const _CategorySheet({this.initial, required this.confirmLabel});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final List<String> _options = List.of(Category.presets);
  String? _selected;

  bool _has(String name) =>
      _options.any((o) => o.toLowerCase() == name.toLowerCase());

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    if (widget.initial != null && !_has(widget.initial!)) {
      _options.add(widget.initial!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustom());
  }

  /// Adds the user's own categories after the presets.
  Future<void> _loadCustom() async {
    final names = await context.read<SavedProvider>().categoryNames();
    if (!mounted) return;
    setState(() {
      for (final n in names) {
        if (!_has(n)) _options.add(n);
      }
    });
  }

  Future<void> _addCustom() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => const CustomOptionDialog(title: 'New category'),
    );
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;

    final existing =
        _options.where((o) => o.toLowerCase() == text.toLowerCase());
    setState(() {
      if (existing.isEmpty) {
        _options.add(text);
        _selected = text;
      } else {
        _selected = existing.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24, AppSpacing.s12, AppSpacing.s24, AppSpacing.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.r4),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text('Choose a category', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.s24),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final option in _options)
                    AppChip(
                      label: option,
                      selected: _selected == option,
                      onTap: () => setState(() => _selected = option),
                    ),
                  AddChip(label: 'Custom category', onTap: _addCustom),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: widget.confirmLabel,
              onPressed: _selected == null
                  ? null
                  : () => Navigator.pop(context, _selected),
            ),
          ],
        ),
      ),
    );
  }
}
