import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenExpirationKey = 'token_expiration';
const _refreshTokenKey = 'refresh_token';
const _authTokenKey = 'auth_token';
const _userIdKey = 'user_id';
const _userEmailKey = 'user_email';
const _returnUrlKey = 'return_url';

/// Result of an API action that may fail due to session expiry.
class ApiActionResult<T> {
  const ApiActionResult._({
    this.data,
    this.isSessionExpired = false,
    this.message,
    this.returnUrl,
  });

  factory ApiActionResult.success(T data) {
    return ApiActionResult._(data: data);
  }

  factory ApiActionResult.sessionExpired({
    required String message,
    String? returnUrl,
  }) {
    return ApiActionResult._(
      isSessionExpired: true,
      message: message,
      returnUrl: returnUrl,
    );
  }

  final T? data;
  final bool isSessionExpired;
  final String? message;
  final String? returnUrl;
}

/// Service that handles session expiration detection and redirect.
class SessionExpiryService {
  SessionExpiryService({
    required FlutterSecureStorage storage,
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  /// Checks if the current session is expired.
  /// Returns true if token is expired and cannot be refreshed.
  Future<bool> isSessionExpired() async {
    final expirationStr = await _storage.read(key: _tokenExpirationKey);
    if (expirationStr == null) {
      return true;
    }

    final expirationMs = int.tryParse(expirationStr);
    if (expirationMs == null) {
      return true;
    }

    final expiration = DateTime.fromMillisecondsSinceEpoch(expirationMs);
    final now = DateTime.now();

    if (now.isAfter(expiration)) {
      // Token is expired, check if we can refresh
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      return refreshToken == null;
    }

    return false;
  }

  /// Performs an API action, checking for session expiry first.
  /// Returns [ApiActionResult] with session expired info if session is invalid.
  Future<ApiActionResult<T>> performApiAction<T>(
    Future<T> Function() action, {
    required String currentPath,
  }) async {
    if (await isSessionExpired()) {
      // Clear stored credentials
      await _clearSession();

      // Store return URL for post-login redirect
      await _storage.write(key: _returnUrlKey, value: currentPath);

      return ApiActionResult.sessionExpired(
        message: 'Your session has expired. Please log in again.',
        returnUrl: currentPath,
      );
    }

    // Session is valid, perform the action
    final result = await action();
    return ApiActionResult.success(result);
  }

  /// Clears stored session data.
  Future<void> _clearSession() async {
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
  }

  /// Gets and clears the stored return URL.
  /// Returns null if no return URL was stored.
  Future<String?> getAndClearReturnUrl() async {
    final returnUrl = await _storage.read(key: _returnUrlKey);
    if (returnUrl != null) {
      await _storage.delete(key: _returnUrlKey);
    }
    return returnUrl;
  }
}
