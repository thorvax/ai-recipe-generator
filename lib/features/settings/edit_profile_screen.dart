import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/primary_button.dart';

/// Change your display name. (Email cannot be changed here.)
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.displayName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.clearError();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AuthProvider>().updateName(_nameCtrl.text);
    if (ok && mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
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
                AppTextField(
                  label: 'Full name',
                  hint: 'Full name',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text('Email', style: AppTextStyles.body2),
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
