import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../domain/auth_state.dart';
import '../providers/auth_provider.dart';

/// Login screen with email and password fields.
///
/// Follows the "Confident Clarity" design philosophy.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.onLoginSuccess,
  });

  /// Callback when login succeeds.
  final VoidCallback? onLoginSuccess;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final authState = ref.watch(authProvider);

    // Listen for auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        widget.onLoginSuccess?.call();
      }
    });

    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Title section
                    Text(
                      'Field Reporter',
                      style: AppTypography.display.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      'Login to your account',
                      style: AppTypography.body1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.verticalXl,

                    // Email field
                    TextFormField(
                      key: const Key('login_email_field'),
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400,
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
                    AppSpacing.verticalMd,

                    // Password field
                    TextFormField(
                      key: const Key('login_password_field'),
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.slate400,
                          ),
                          onPressed:
                              isLoading ? null : _togglePasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.verticalLg,

                    // Error message
                    if (authState is AuthError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          authState.message,
                          style: AppTypography.body2.copyWith(
                            color:
                                isDark ? AppColors.darkRose : AppColors.rose500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login button
                    PrimaryButton(
                      key: const Key('login_button'),
                      label: 'Login',
                      onPressed: isLoading ? null : _handleLogin,
                      isLoading: isLoading,
                    ),
                    AppSpacing.verticalMd,

                    // Forgot password link
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              // TODO: Implement forgot password
                            },
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.textButton.copyWith(
                          color: isDark
                              ? AppColors.darkOrange
                              : AppColors.orange500,
                        ),
                      ),
                    ),
                    AppSpacing.verticalMd,

                    // Create account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTypography.body2.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate500,
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  // TODO: Navigate to registration
                                },
                          child: Text(
                            'Create Account',
                            style: AppTypography.textButton.copyWith(
                              color: isDark
                                  ? AppColors.darkOrange
                                  : AppColors.orange500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
