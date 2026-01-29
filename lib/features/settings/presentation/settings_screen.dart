import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/biometric_provider.dart';

/// Settings screen with biometric authentication toggle and logout.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    this.onLogout,
  });

  /// Callback invoked when logout is successful.
  final VoidCallback? onLogout;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;
  String? _successMessage;
  Timer? _successMessageTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBiometricState);
  }

  @override
  void dispose() {
    _successMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final biometricNotifier = ref.read(biometricProvider.notifier);

    final canUseBiometrics =
        await biometricNotifier.checkBiometricAvailability();
    final isEnabled = await biometricNotifier.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _biometricAvailable = canUseBiometrics;
        _biometricEnabled = isEnabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _showLogoutConfirmation() async {
    final brightness = Theme.of(context).brightness;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        title: Text(
          'Log Out',
          style: AppTypography.headline3.copyWith(
            color: AppColors.textPrimary(brightness),
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTypography.body1.copyWith(
            color: AppColors.textSecondary(brightness),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('logout_cancel_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary(brightness),
              ),
            ),
          ),
          TextButton(
            key: const Key('logout_confirm_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Log Out',
              style: AppTypography.button.copyWith(
                color: AppColors.error(brightness),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    // Perform logout - clears tokens and sensitive data
    await ref.read(authProvider.notifier).logout();

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Navigate to login
    widget.onLogout?.call();
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable biometric - need to authenticate first
      final biometricNotifier = ref.read(biometricProvider.notifier);
      final authenticated = await biometricNotifier.authenticateForEnrollment();

      if (authenticated) {
        await biometricNotifier.enableBiometric();
        if (mounted) {
          setState(() {
            _biometricEnabled = true;
            _successMessage = 'Biometric login enabled';
          });

          // Clear success message after delay
          _successMessageTimer?.cancel();
          _successMessageTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _successMessage = null;
              });
            }
          });
        }
      }
    } else {
      // Disable biometric
      final biometricNotifier = ref.read(biometricProvider.notifier);
      await biometricNotifier.disableBiometric();
      if (mounted) {
        setState(() {
          _biometricEnabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.headline1.copyWith(
            color: AppColors.textPrimary(brightness),
          ),
        ),
        backgroundColor: AppColors.background(brightness),
        elevation: 0,
      ),
      backgroundColor: AppColors.background(brightness),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Container(
                      padding: AppSpacing.cardInsets,
                      decoration: BoxDecoration(
                        color: AppColors.successBackground(brightness),
                        borderRadius: AppSpacing.borderRadiusLg,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success(brightness),
                            size: AppSpacing.iconSize,
                          ),
                          AppSpacing.horizontalSm,
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: AppTypography.body1.copyWith(
                                color: AppColors.success(brightness),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Security section header
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Security',
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ),
                // Biometric toggle
                if (_biometricAvailable)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: brightness == Brightness.light
                          ? Border.all(color: AppColors.border(brightness))
                          : null,
                    ),
                    child: Padding(
                      padding: AppSpacing.cardInsets,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Biometric Login',
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textPrimary(brightness),
                                  ),
                                ),
                                AppSpacing.verticalXs,
                                Text(
                                  'Use fingerprint or face recognition to login',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary(brightness),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                            activeColor: AppColors.primary(brightness),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Spacer before account section
                const SizedBox(height: AppSpacing.xl),
                // Account section header
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Account',
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                  ),
                ),
                // Logout button
                GestureDetector(
                  key: const Key('logout_button'),
                  onTap: _showLogoutConfirmation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface(brightness),
                      borderRadius: AppSpacing.borderRadiusLg,
                      border: brightness == Brightness.light
                          ? Border.all(color: AppColors.border(brightness))
                          : null,
                    ),
                    child: Padding(
                      padding: AppSpacing.cardInsets,
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: AppColors.error(brightness),
                            size: AppSpacing.iconSize,
                          ),
                          AppSpacing.horizontalSm,
                          Expanded(
                            child: Text(
                              'Logout',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.error(brightness),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted(brightness),
                            size: AppSpacing.iconSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
