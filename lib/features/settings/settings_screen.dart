import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/saved_provider.dart';
import '../../shared/widgets/secondary_button.dart';

/// TEMPORARY profile tab: name, email, log out.
/// The full Settings design is built in Step 7.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.s24),
            Text(user?.displayName ?? 'Cook', style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.s4),
            Text(
              user?.email ?? '',
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            SecondaryButton(
              label: 'Log out',
              onPressed: () async {
                context.read<SavedProvider>().stop();
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
    );
  }
}
