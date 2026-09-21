import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/generation_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';

/// Shown while Gemini works. It starts the generation itself, then goes to
/// the result screen (or back to the form with an error message).
class GenerationLoadingScreen extends StatefulWidget {
  const GenerationLoadingScreen({super.key});

  @override
  State<GenerationLoadingScreen> createState() =>
      _GenerationLoadingScreenState();
}

class _GenerationLoadingScreenState extends State<GenerationLoadingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final request =
        ModalRoute.of(context)!.settings.arguments as GenerationRequest;
    final userId = context.read<AuthProvider>().currentUser?.uid ?? '';
    final recipes = context.read<RecipeProvider>();

    final ok = await recipes.generate(request: request, userId: userId);
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacementNamed(context, AppRoutes.recipeResult);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(recipes.errorMessage ?? 'Something went wrong.')),
      );
      Navigator.pop(context); // back to the form
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // no going back while cooking
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('lib/assets/pot-icon.png', width: 96, height: 96),
                const SizedBox(height: AppSpacing.s16),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s32),
                Text(
                  'SIMMERING YOUR INGREDIENTS INTO A RECIPE…',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
