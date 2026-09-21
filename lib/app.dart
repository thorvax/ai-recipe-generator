import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/generator/generation_loading_screen.dart';
import 'features/generator/recipe_result_screen.dart';
import 'features/home/main_shell.dart';
import 'features/splash/splash_screen.dart';

class MealMindApp extends StatelessWidget {
  const MealMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signup: (_) => const SignUpScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.home: (_) => const MainShell(),
        AppRoutes.generating: (_) => const GenerationLoadingScreen(),
        AppRoutes.recipeResult: (_) => const RecipeResultScreen(),
      },
    );
  }
}
