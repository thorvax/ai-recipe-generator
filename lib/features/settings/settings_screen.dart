import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/saved_provider.dart';
import '../../services/media_service.dart';
import '../../shared/widgets/secondary_button.dart';
import '../../shared/widgets/user_avatar.dart';
import 'dietary_preferences_screen.dart';
import 'edit_profile_screen.dart';
import 'info_screen.dart';
import 'widgets/avatar_picker_sheet.dart';
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
    context.read<ProfileProvider>().clear();
    await auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    }
  }

  Future<void> _editAvatar(BuildContext context) async {
    final profiles = context.read<ProfileProvider>();
    if (profiles.isSavingAvatar) return;
    final messenger = ScaffoldMessenger.of(context);

    final action = await showAvatarPickerSheet(
      context,
      canRemove: profiles.myProfile?.hasCustomAvatar ?? false,
    );
    if (action == null) return;

    String? error;
    var changed = false;
    switch (action) {
      case AvatarAction.camera:
      case AvatarAction.gallery:
        final result = await profiles.changeAvatar(
          action == AvatarAction.camera
              ? MediaSource.camera
              : MediaSource.gallery,
        );
        error = result.error;
        changed = result.changed;
      case AvatarAction.remove:
        error = await profiles.removeAvatar();
        changed = error == null;
    }
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else if (changed) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(action == AvatarAction.remove
              ? 'Profile photo removed'
              : 'Profile photo updated'),
        ),
      );
    }
  }

  Widget _avatar(BuildContext context, String? uid, String name) {
    final saving = context.select<ProfileProvider, bool>((p) => p.isSavingAvatar);
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: () => _editAvatar(context),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            children: [
              UserAvatar(uid: uid, name: name, size: 72, iconFallback: true),
              if (saving)
                const Positioned.fill(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.secondary,
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 12,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            _avatar(context, auth.currentUser?.uid, auth.displayName),
            const SizedBox(height: AppSpacing.s16),
            Text(
              '@${auth.displayName}',
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
