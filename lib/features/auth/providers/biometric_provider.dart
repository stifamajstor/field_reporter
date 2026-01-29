import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';

part 'biometric_provider.g.dart';

const _biometricEnabledKey = 'biometric_enabled';

/// Provider for LocalAuthentication instance.
@Riverpod(keepAlive: true)
LocalAuthentication localAuth(Ref ref) {
  return LocalAuthentication();
}

/// Biometric authentication state.
enum BiometricState {
  initial,
  checking,
  available,
  unavailable,
  authenticating,
  authenticated,
  failed,
}

/// Biometric authentication notifier.
@Riverpod(keepAlive: true)
class Biometric extends _$Biometric {
  @override
  BiometricState build() {
    return BiometricState.initial;
  }

  /// Checks if biometrics can be used on this device.
  Future<bool> canUseBiometrics() async {
    state = BiometricState.checking;

    final localAuth = ref.read(localAuthProvider);

    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();

      if (canCheck && isSupported) {
        final availableBiometrics = await localAuth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          state = BiometricState.available;
          return true;
        }
      }

      state = BiometricState.unavailable;
      return false;
    } catch (e) {
      state = BiometricState.unavailable;
      return false;
    }
  }

  /// Checks if biometric login is enabled for the user.
  Future<bool> isBiometricEnabled() async {
    final storage = ref.read(secureStorageProvider);
    final enabled = await storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Enables biometric authentication for the user.
  Future<void> enableBiometric() async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _biometricEnabledKey, value: 'true');
  }

  /// Disables biometric authentication for the user.
  Future<void> disableBiometric() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _biometricEnabledKey);
  }

  /// Authenticates the user with biometrics and restores session.
  Future<bool> authenticateWithBiometrics() async {
    state = BiometricState.authenticating;

    final localAuth = ref.read(localAuthProvider);

    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to access Field Reporter',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Restore session from secure storage
        await _restoreSession();
        state = BiometricState.authenticated;
        return true;
      }

      state = BiometricState.failed;
      return false;
    } catch (e) {
      state = BiometricState.failed;
      return false;
    }
  }

  /// Restores the user session from secure storage.
  Future<void> _restoreSession() async {
    final storage = ref.read(secureStorageProvider);
    final authNotifier = ref.read(authProvider.notifier);

    final token = await storage.read(key: 'auth_token');
    final userId = await storage.read(key: 'user_id');
    final email = await storage.read(key: 'user_email');

    if (token != null && userId != null && email != null) {
      authNotifier.restoreSession(
        userId: userId,
        email: email,
        token: token,
      );
    }
  }
}
