import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../domain/password_reset_state.dart';
import '../providers/password_reset_provider.dart';

/// Forgot password screen for requesting password reset.
///
/// Follows the "Confident Clarity" design philosophy.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.onBackToLogin,
  });

  /// Callback to navigate back to login screen.
  final VoidCallback? onBackToLogin;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(passwordResetProvider.notifier)
          .sendResetLink(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final resetState = ref.watch(passwordResetProvider);
    final isLoading = resetState is PasswordResetLoading;
    final isSuccess = resetState is PasswordResetSuccess;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
          onPressed: widget.onBackToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: isSuccess
                  ? _buildSuccessContent(isDark, resetState.email)
                  : _buildFormContent(isDark, isLoading, resetState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent(bool isDark, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: isDark ? AppColors.darkEmerald : AppColors.emerald500,
        ),
        AppSpacing.verticalLg,
        Text(
          'Reset link sent!',
          style: AppTypography.headline1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.verticalMd,
        Text(
          'Check your email at $email for instructions to reset your password.',
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.verticalXl,
        TextButton(
          onPressed: widget.onBackToLogin,
          child: Text(
            'Back to Login',
            style: AppTypography.textButton.copyWith(
              color: isDark ? AppColors.darkOrange : AppColors.orange500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(
    bool isDark,
    bool isLoading,
    PasswordResetState resetState,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset Password',
            style: AppTypography.display.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSm,
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalXl,

          // Email field
          TextFormField(
            key: const Key('forgot_password_email_field'),
            controller: _emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onFieldSubmitted: (_) => _handleSendResetLink(),
            decoration: InputDecoration(
              hintText: 'Email address',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!_isValidEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          AppSpacing.verticalLg,

          // Error message
          if (resetState is PasswordResetError)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                resetState.message,
                style: AppTypography.body2.copyWith(
                  color: isDark ? AppColors.darkRose : AppColors.rose500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Send reset link button
          PrimaryButton(
            key: const Key('send_reset_link_button'),
            label: 'Send Reset Link',
            onPressed: isLoading ? null : _handleSendResetLink,
            isLoading: isLoading,
          ),
          AppSpacing.verticalMd,

          // Back to login link
          TextButton(
            onPressed: isLoading ? null : widget.onBackToLogin,
            child: Text(
              'Back to Login',
              style: AppTypography.textButton.copyWith(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
