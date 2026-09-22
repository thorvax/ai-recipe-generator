import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/add_chip.dart';
import '../../shared/widgets/app_chip.dart';
import '../../shared/widgets/custom_option_dialog.dart';
import '../../shared/widgets/primary_button.dart';

/// Lets the user pick default dietary needs. These pre-fill the
/// Ingredient Input form so they don't have to reselect them every time.
class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  static const _presets = [
    'Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free', 'Low-carb',
  ];

  late List<String> _options;
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final saved = context.read<AuthProvider>().dietaryNeeds;
    _options = [
      ..._presets,
      for (final n in saved)
        if (!_presets.any((p) => p.toLowerCase() == n.toLowerCase())) n,
    ];
    _selected = Set.of(saved);
  }

  Future<void> _addCustom() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => const CustomOptionDialog(title: 'Add your own dietary need'),
    );
    final text = value?.trim() ?? '';
    if (text.isEmpty) return;

    final existing =
        _options.where((o) => o.toLowerCase() == text.toLowerCase());
    setState(() {
      if (existing.isEmpty) {
        _options.add(text);
        _selected.add(text);
      } else {
        _selected.add(existing.first);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context
        .read<AuthProvider>()
        .updateDietaryPreferences(_selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Preferences saved')));
      Navigator.pop(context);
    } else {
      final error = context.read<AuthProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not save. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Dietary Preferences',
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These apply automatically every time you generate a recipe. '
                'You can still change them per recipe on the Home tab.',
                style: AppTextStyles.body2
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s24),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  for (final option in _options)
                    AppChip(
                      label: option,
                      selected: _selected.contains(option),
                      onTap: () => setState(() {
                        if (!_selected.remove(option)) _selected.add(option);
                      }),
                    ),
                  AddChip(label: 'Other', onTap: _addCustom),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Save Preferences',
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
