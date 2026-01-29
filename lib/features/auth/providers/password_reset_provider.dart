import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/password_reset_state.dart';

part 'password_reset_provider.g.dart';

/// Provider for password reset functionality.
@riverpod
class PasswordReset extends _$PasswordReset {
  @override
  PasswordResetState build() {
    return const PasswordResetState.initial();
  }

  /// Sends a password reset email to the provided address.
  Future<void> sendResetLink(String email) async {
    state = const PasswordResetState.loading();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, this would call the API
      if (email.isNotEmpty) {
        state = PasswordResetState.success(email);
      } else {
        state = const PasswordResetState.error('Please enter your email');
      }
    } catch (e) {
      state = PasswordResetState.error(e.toString());
    }
  }

  /// Resets the state to initial.
  void reset() {
    state = const PasswordResetState.initial();
  }
}
