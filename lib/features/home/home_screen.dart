import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/generation_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/gemini_service.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';

/// TEMPORARY screen for testing. Replaced in Step 5 by the real
/// Ingredient Input screen. It includes a button to test Gemini.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;
  String? _result;

  Future<void> _testGemini() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final recipe = await GeminiService().generateRecipe(
        request: const GenerationRequest(
          ingredients: ['chicken', 'rice', 'garlic', 'egg'],
          mealType: 'Dinner',
          cuisine: 'Filipino',
          servings: 2,
        ),
        userId: auth.currentUser?.uid ?? 'test',
      );

      final buffer = StringBuffer()
        ..writeln(recipe.name)
        ..writeln(recipe.summaryLabel)
        ..writeln()
        ..writeln('INGREDIENTS');
      for (final i in recipe.ingredients) {
        buffer.writeln('• ${i.display}');
      }
      buffer
        ..writeln()
        ..writeln('STEPS');
      for (final s in recipe.steps) {
        buffer.writeln('${s.stepNumber}. ${s.instruction}');
      }
      _result = buffer.toString();
    } on GeminiException catch (e) {
      _result = 'Error: ${e.message}';
    } catch (e) {
      _result = 'Unexpected error: $e';
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final name = auth.currentUser?.displayName ?? 'Cook';

    return Scaffold(
      appBar: AppBar(title: const Text('MealMind')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $name!', style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.s4),
              Text(
                auth.currentUser?.email ?? '',
                style: AppTextStyles.body2
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s32),
              PrimaryButton(
                label: 'Test recipe generation',
                isLoading: _loading,
                onPressed: _testGemini,
              ),
              if (_result != null) ...[
                const SizedBox(height: AppSpacing.s16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                  ),
                  child: Text(_result!, style: AppTextStyles.body2),
                ),
              ],
              const SizedBox(height: AppSpacing.s32),
              SecondaryButton(
                label: 'Log out',
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.login, (r) => false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
