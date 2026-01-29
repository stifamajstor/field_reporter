import 'package:flutter/foundation.dart';

/// Represents the authentication state of the app.
@immutable
sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated({
    required String userId,
    required String email,
    required String token,
  }) = AuthAuthenticated;
  const factory AuthState.error(String message) = AuthError;
  const factory AuthState.networkError(String message) = AuthNetworkError;
  const factory AuthState.accountLocked({
    required String message,
    required Duration lockoutDuration,
  }) = AuthAccountLocked;
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.userId,
    required this.email,
    required this.token,
  });

  final String userId;
  final String email;
  final String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          token == other.token;

  @override
  int get hashCode => userId.hashCode ^ email.hashCode ^ token.hashCode;
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

final class AuthNetworkError extends AuthState {
  const AuthNetworkError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthNetworkError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

final class AuthAccountLocked extends AuthState {
  const AuthAccountLocked({
    required this.message,
    required this.lockoutDuration,
  });

  final String message;
  final Duration lockoutDuration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAccountLocked &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          lockoutDuration == other.lockoutDuration;

  @override
  int get hashCode => message.hashCode ^ lockoutDuration.hashCode;
}
