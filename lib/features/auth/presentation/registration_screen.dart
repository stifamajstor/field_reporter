import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../domain/auth_state.dart';
import '../providers/auth_provider.dart';

/// Registration screen for creating a new account.
///
/// Follows the "Confident Clarity" design philosophy.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({
    super.key,
    this.onRegistrationSuccess,
  });

  /// Callback when registration succeeds.
  final VoidCallback? onRegistrationSuccess;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _showSuccessMessage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
          ),
        );
        return;
      }

      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
        setState(() {
          _showSuccessMessage = true;
        });
        // Delay slightly to show success message before navigating
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onRegistrationSuccess?.call();
        });
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
                    // Title section
                    Text(
                      'Create Account',
                      style: AppTypography.display.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      'Sign up to get started',
                      style: AppTypography.body1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.verticalXl,

                    // Success message
                    if (_showSuccessMessage)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkEmeraldSubtle
                                : AppColors.emerald50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Account created successfully',
                            style: AppTypography.body2.copyWith(
                              color: isDark
                                  ? AppColors.darkEmerald
                                  : AppColors.emerald500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // Full name field
                    TextFormField(
                      key: const Key('registration_name_field'),
                      controller: _nameController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Full name',
                        prefixIcon: Icon(
                          Icons.person_outlined,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.verticalMd,

                    // Email field
                    TextFormField(
                      key: const Key('registration_email_field'),
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
                      key: const Key('registration_password_field'),
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
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
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!value.contains(RegExp(r'[A-Z]'))) {
                          return 'Password must contain an uppercase letter';
                        }
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return 'Password must contain a number';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.verticalMd,

                    // Confirm password field
                    TextFormField(
                      key: const Key('registration_confirm_password_field'),
                      controller: _confirmPasswordController,
                      enabled: !isLoading,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      decoration: InputDecoration(
                        hintText: 'Confirm password',
                        prefixIcon: Icon(
                          Icons.lock_outlined,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.slate400,
                          ),
                          onPressed: isLoading
                              ? null
                              : _toggleConfirmPasswordVisibility,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.verticalMd,

                    // Terms and conditions checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          key: const Key('registration_terms_checkbox'),
                          value: _acceptedTerms,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _acceptedTerms = value ?? false;
                                  });
                                },
                          activeColor: isDark
                              ? AppColors.darkOrange
                              : AppColors.orange500,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.body2.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.slate500,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkOrange
                                          : AppColors.orange500,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // TODO: Open terms of service
                                      },
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.darkOrange
                                          : AppColors.orange500,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // TODO: Open privacy policy
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

                    // Register button
                    PrimaryButton(
                      key: const Key('registration_button'),
                      label: 'Register',
                      onPressed: isLoading ? null : _handleRegister,
                      isLoading: isLoading,
                    ),
                    AppSpacing.verticalMd,

                    // Already have account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
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
                                  Navigator.of(context).pop();
                                },
                          child: Text(
                            'Login',
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
