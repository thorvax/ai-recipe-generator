import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.pushReplacementNamed(
      context,
      loggedIn ? AppRoutes.home : AppRoutes.login,
    );
  }

  Widget _dot() => Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: Image.asset(
                  'lib/assets/pot-icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'MealMind',
              style: AppTextStyles.heading1
                  .copyWith(color: AppColors.white, fontSize: 32),
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [_dot(), const SizedBox(width: AppSpacing.s16), _dot()],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Recipes from what you already have',
              style: AppTextStyles.body1.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
