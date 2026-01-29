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
  @override
  AuthState build() {
    return const AuthState.unauthenticated();
  }

  /// Attempts to login with the provided credentials.
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, this would call the API
      // For now, accept any valid-looking credentials
      if (email.isNotEmpty && password.isNotEmpty) {
        const token = 'test_token_123';
        const userId = 'user_1';

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
        state = const AuthState.error('Invalid credentials');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
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
}

/// Type alias for the auth notifier
typedef AuthNotifier = Auth;
