import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';

/// Shown instead of Home until an email account taps the link in the
/// verification email (same as the website's VerifyEmailScreen). Proves the
/// person really owns the email, so nobody can sign up with someone else's
/// address. Google accounts skip this.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  /// Seconds to wait between "Resend" taps (Firebase also limits it).
  static const int _cooldownSeconds = 60;

  Timer? _timer;
  int _cooldown = 0;
  bool _hasSent = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    // Right after sign-up an email was just sent: wait before resending.
    // Older accounts logging in were never sent one: no wait.
    final sentAt = auth.lastVerificationSentAt;
    if (sentAt != null) {
      _hasSent = true;
      final waited = DateTime.now().difference(sentAt).inSeconds;
      _startCooldown(_cooldownSeconds - waited);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) auth.clearError();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) return;
    setState(() => _cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.sendVerificationEmail();
    if (!ok || !mounted) return;
    setState(() => _hasSent = true);
    _startCooldown(_cooldownSeconds);
    messenger.showSnackBar(
      const SnackBar(content: Text('Verification email sent')),
    );
  }

  Future<void> _check() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final verified = await auth.checkEmailVerified();
    if (!verified || !mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Email verified. Welcome to MealMind!')),
    );
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.currentUser?.email ?? '';
    final bodyStyle =
        AppTextStyles.body2.copyWith(color: AppColors.textSecondary);
    final emailStyle = AppTextStyles.body2.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.s48),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(
                _hasSent ? 'Check your email' : 'Verify your email',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text.rich(
                textAlign: TextAlign.center,
                _hasSent
                    ? TextSpan(style: bodyStyle, children: [
                        const TextSpan(text: 'We sent a verification link to '),
                        TextSpan(text: email, style: emailStyle),
                        const TextSpan(
                          text: '. Tap it to verify your account, then come '
                              'back here.',
                        ),
                      ])
                    : TextSpan(style: bodyStyle, children: [
                        const TextSpan(
                          text: 'To keep your account safe, please confirm '
                              'that ',
                        ),
                        TextSpan(text: email, style: emailStyle),
                        const TextSpan(
                          text: " is yours. We'll email you a link to tap.",
                        ),
                      ]),
              ),
              if (_hasSent) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  "Can't find it? Check your spam or promotions folder.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
              if (auth.errorMessage != null) ...[
                ErrorBanner(message: auth.errorMessage!),
                const SizedBox(height: AppSpacing.s16),
              ],
              if (_hasSent) ...[
                PrimaryButton(
                  label: "I've verified my email",
                  isLoading: auth.isLoading,
                  onPressed: _check,
                ),
                const SizedBox(height: AppSpacing.s12),
                SecondaryButton(
                  label: _cooldown > 0
                      ? 'Resend email (${_cooldown}s)'
                      : 'Resend email',
                  onPressed: _cooldown > 0 || auth.isLoading ? null : _send,
                ),
              ] else
                PrimaryButton(
                  label: 'Send verification email',
                  isLoading: auth.isLoading,
                  onPressed: _send,
                ),
              const SizedBox(height: AppSpacing.s16),
              TextButton(
                onPressed: _logout,
                child: Text(
                  'Wrong email? Log out and sign up again',
                  style: bodyStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
