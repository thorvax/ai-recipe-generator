import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/secondary_button.dart';

/// TEMPORARY placeholder so we can test login. Replaced in Step 5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final name = auth.currentUser?.displayName ?? 'Cook';

    return Scaffold(
      appBar: AppBar(title: const Text('MealMind')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hello, $name!', style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.s8),
              Text(auth.currentUser?.email ?? '', style: AppTextStyles.body2),
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
