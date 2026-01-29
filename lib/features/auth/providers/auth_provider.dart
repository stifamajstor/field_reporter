import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_state.dart';

part 'auth_provider.g.dart';

const _tokenKey = 'auth_token';
const _userIdKey = 'user_id';
const _emailKey = 'user_email';

/// Provider for FlutterSecureStorage instance.
@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}

/// Auth state notifier that manages authentication.
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  bool _simulateNetworkError = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  @override
  AuthState build() {
    return const AuthState.unauthenticated();
  }

  /// Sets whether to simulate network errors (for testing).
  void setNetworkError(bool value) {
    _simulateNetworkError = value;
  }

  /// Attempts to login with the provided credentials.
  ///
  /// Returns true if successful, false if invalid credentials.
  Future<bool> login(String email, String password) async {
    // Check if account is locked
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remaining = _lockoutUntil!.difference(DateTime.now());
      state = AuthState.accountLocked(
        message: 'Account locked due to too many failed attempts',
        lockoutDuration: remaining,
      );
      return false;
    }

    state = const AuthState.loading();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Check for network error
      if (_simulateNetworkError) {
        state = const AuthState.networkError(
            'Network error. Please check your connection.');
        return false;
      }

      // In a real app, this would call the API
      // For now, simulate invalid credentials for specific password
      if (email.isNotEmpty && password == 'Password123!') {
        const token = 'test_token_123';
        const userId = 'user_1';

        // Store credentials securely
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: _tokenKey, value: token);
        await storage.write(key: _userIdKey, value: userId);
        await storage.write(key: _emailKey, value: email);

        // Reset failed attempts on successful login
        _failedAttempts = 0;
        _lockoutUntil = null;

        state = AuthState.authenticated(
          userId: userId,
          email: email,
          token: token,
        );
        return true;
      } else {
        _failedAttempts++;

        if (_failedAttempts >= _maxFailedAttempts) {
          _lockoutUntil = DateTime.now().add(_lockoutDuration);
          state = const AuthState.accountLocked(
            message: 'Account locked due to too many failed attempts',
            lockoutDuration: _lockoutDuration,
          );
        } else {
          state = const AuthState.error('Invalid credentials');
        }
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _tokenKey);
    await storage.delete(key: _userIdKey);
    await storage.delete(key: _emailKey);
    state = const AuthState.unauthenticated();
  }

  /// Checks if user is already authenticated.
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();

    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.read(key: _tokenKey);
      final userId = await storage.read(key: _userIdKey);
      final email = await storage.read(key: _emailKey);

      if (token != null && userId != null && email != null) {
        state = AuthState.authenticated(
          userId: userId,
          email: email,
          token: token,
        );
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Restores session from stored credentials (used by biometric auth).
  void restoreSession({
    required String userId,
    required String email,
    required String token,
  }) {
    state = AuthState.authenticated(
      userId: userId,
      email: email,
      token: token,
    );
  }

  /// Registers a new user account.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, this would call the API
      if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
        const token = 'new_user_token_123';
        final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

        // Store credentials securely
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: _tokenKey, value: token);
        await storage.write(key: _userIdKey, value: userId);
        await storage.write(key: _emailKey, value: email);

        state = AuthState.authenticated(
          userId: userId,
          email: email,
          token: token,
        );
      } else {
        state = const AuthState.error('Please fill in all fields');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

/// Type alias for the auth notifier
typedef AuthNotifier = Auth;
