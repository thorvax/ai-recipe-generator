import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/saved_provider.dart';
import '../../shared/widgets/secondary_button.dart';
import 'dietary_preferences_screen.dart';
import 'edit_profile_screen.dart';
import 'info_screen.dart';
import 'widgets/settings_tile.dart';

/// Profile tab: avatar, name, email and the settings list.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    // Stop live listeners and clear per-user data before signing out.
    context.read<SavedProvider>().stop();
    context.read<CommunityProvider>().stop();
    context.read<RecipeProvider>().clear();
    await auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.currentUser?.email ?? '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 40, color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              auth.displayName,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              email,
              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s24),
            SettingsTile(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () => _open(context, const EditProfileScreen()),
            ),
            const SizedBox(height: AppSpacing.s12),
            SettingsTile(
              icon: Icons.restaurant_outlined,
              label: 'Dietary Preferences',
              onTap: () => _open(context, const DietaryPreferencesScreen()),
            ),
            const SizedBox(height: AppSpacing.s12),
            SettingsTile(
              icon: Icons.info_outline,
              label: 'About',
              onTap: () => _open(context, InfoScreen.about()),
            ),
            const SizedBox(height: AppSpacing.s12),
            SettingsTile(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              onTap: () => _open(context, InfoScreen.privacy()),
            ),
            const SizedBox(height: AppSpacing.s24),
            SecondaryButton(label: 'Log Out', onPressed: () => _logout(context)),
          ],
        ),
      ),
    );
  }
}
