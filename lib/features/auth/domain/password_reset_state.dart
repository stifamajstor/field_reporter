import 'package:flutter/foundation.dart';

/// Represents the state of a password reset request.
@immutable
sealed class PasswordResetState {
  const PasswordResetState();

  const factory PasswordResetState.initial() = PasswordResetInitial;
  const factory PasswordResetState.loading() = PasswordResetLoading;
  const factory PasswordResetState.success(String email) = PasswordResetSuccess;
  const factory PasswordResetState.error(String message) = PasswordResetError;
}

final class PasswordResetInitial extends PasswordResetState {
  const PasswordResetInitial();
}

final class PasswordResetLoading extends PasswordResetState {
  const PasswordResetLoading();
}

final class PasswordResetSuccess extends PasswordResetState {
  const PasswordResetSuccess(this.email);

  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordResetSuccess &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}

final class PasswordResetError extends PasswordResetState {
  const PasswordResetError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordResetError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
