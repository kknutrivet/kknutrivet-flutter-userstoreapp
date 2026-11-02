import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/common.dart';
import '../../../providers/app_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showToast('Please enter a valid email address', isError: true);
      return;
    }
    AppHaptics.light();
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).forgotPassword(email);
      setState(() => _sent = true);
    } catch (e) {
      showToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeCanvas,
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: AppTheme.serif(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _sent
            ? AppCard(
                variant: AppCardVariant.elevated,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryWash,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_rounded,
                          color: AppColors.primaryDeep, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Check your inbox',
                      style: AppTheme.serif(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If an account exists for ${_email.text.trim()}, we have sent password reset instructions to your email.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            : AppCard(
                variant: AppCardVariant.elevated,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Forgot your password?',
                      style: AppTheme.serif(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter your registered email address and we will send you a password reset link.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Registered Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Send Reset Link',
                      icon: const Icon(Icons.send_rounded, size: 16),
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                      fullWidth: true,
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
