import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'auth_token';
const _refreshTokenKey = 'refresh_token';
const _tokenExpirationKey = 'token_expiration';

/// Threshold before expiration to trigger refresh (5 minutes).
const _refreshThreshold = Duration(minutes: 5);

/// Result of a token refresh operation.
class TokenRefreshResult {
  const TokenRefreshResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}

/// Service that handles automatic token refresh.
class TokenRefreshService {
  TokenRefreshService({
    required FlutterSecureStorage storage,
    this.simulateError = false,
  }) : _storage = storage;

  final FlutterSecureStorage _storage;
  final bool simulateError;

  /// Checks if the current token needs to be refreshed.
  Future<bool> needsRefresh() async {
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

    // Refresh if within threshold of expiration
    return now.isAfter(expiration.subtract(_refreshThreshold));
  }

  /// Refreshes the access token using the stored refresh token.
  /// Returns null if refresh fails or no refresh token exists.
  Future<TokenRefreshResult?> refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      return null;
    }

    try {
      if (simulateError) {
        throw Exception('Simulated API error');
      }

      // Simulate API call to refresh token
      await Future.delayed(const Duration(milliseconds: 100));

      // In real app, this would call POST /api/auth/refresh
      final newAccessToken =
          'refreshed_token_${DateTime.now().millisecondsSinceEpoch}';
      final newRefreshToken =
          'refresh_${DateTime.now().millisecondsSinceEpoch}';
      final newExpiration = DateTime.now().add(const Duration(hours: 1));

      // Store new tokens
      await _storage.write(key: _tokenKey, value: newAccessToken);
      await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
      await _storage.write(
        key: _tokenExpirationKey,
        value: newExpiration.millisecondsSinceEpoch.toString(),
      );

      return TokenRefreshResult(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresAt: newExpiration,
      );
    } catch (e) {
      return null;
    }
  }

  /// Performs an API action, refreshing the token first if needed.
  /// This enables transparent token refresh before API calls.
  Future<T> performWithRefresh<T>(Future<T> Function() apiAction) async {
    if (await needsRefresh()) {
      await refreshToken();
    }
    return apiAction();
  }
}
