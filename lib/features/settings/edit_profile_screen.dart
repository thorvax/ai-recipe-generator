import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/username_field.dart';

/// Change your username (it must be free). Email cannot be changed here.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final String _currentUsername;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _currentUsername = auth.displayName;
    _usernameCtrl = TextEditingController(text: _currentUsername);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.clearError();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final profiles = context.read<ProfileProvider>();
    final typed = _usernameCtrl.text.trim().toLowerCase();
    if (typed == _currentUsername) {
      Navigator.pop(context); // nothing changed
      return;
    }
    final saved = await context.read<AuthProvider>().changeUsername(typed);
    if (saved != null) profiles.onNameChanged(saved);
    if (saved != null && mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Username updated')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Edit Profile', style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (auth.errorMessage != null) ...[
                  ErrorBanner(message: auth.errorMessage!),
                  const SizedBox(height: AppSpacing.s16),
                ],
                Text('Username', style: AppTextStyles.body2),
                const SizedBox(height: AppSpacing.s8),
                UsernameField(
                  controller: _usernameCtrl,
                  currentUsername: _currentUsername,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  "Email (you log in with this; it can't be changed)",
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: AppSpacing.s8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                  ),
                  child: Text(
                    email,
                    style: AppTextStyles.body1
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                PrimaryButton(
                  label: 'Save Changes',
                  isLoading: auth.isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
