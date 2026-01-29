import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/connectivity_service.dart';
import '../domain/offline_pin_state.dart';
import 'auth_provider.dart';

part 'offline_pin_provider.g.dart';

const _pinEnabledKey = 'offline_pin_enabled';
const _pinHashKey = 'offline_pin_hash';

/// Offline PIN authentication notifier.
@Riverpod(keepAlive: true)
class OfflinePin extends _$OfflinePin {
  @override
  OfflinePinState build() {
    return const OfflinePinState();
  }

  /// Enables offline PIN authentication.
  /// Must be called while online.
  Future<bool> enableOfflinePin() async {
    final connectivity = ref.read(connectivityServiceProvider);
    if (!connectivity.isOnline) {
      state = state.copyWith(error: 'Cannot enable PIN while offline');
      return false;
    }

    final storage = ref.read(secureStorageProvider);
    await storage.write(key: _pinEnabledKey, value: 'true');

    state = state.copyWith(isEnabled: true, error: null);
    return true;
  }

  /// Disables offline PIN authentication and clears stored PIN.
  Future<void> disableOfflinePin() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _pinEnabledKey);
    await storage.delete(key: _pinHashKey);

    state = const OfflinePinState();
  }

  /// Sets a new 6-digit PIN.
  /// Returns true if PIN was set successfully.
  Future<bool> setPin(String pin) async {
    if (!_isValidPin(pin)) {
      state = state.copyWith(error: 'PIN must be exactly 6 digits');
      return false;
    }

    final storage = ref.read(secureStorageProvider);
    final hashedPin = _hashPin(pin);
    await storage.write(key: _pinHashKey, value: hashedPin);

    state = state.copyWith(isPinSet: true, error: null);
    return true;
  }

  /// Checks if offline PIN authentication is required.
  /// Call this on app start to determine authentication flow.
  Future<void> checkOfflineAuthRequired() async {
    final connectivity = ref.read(connectivityServiceProvider);
    final storage = ref.read(secureStorageProvider);

    final isOffline = !connectivity.isOnline;
    final pinEnabled = await storage.read(key: _pinEnabledKey);
    final pinHash = await storage.read(key: _pinHashKey);

    if (isOffline && pinEnabled == 'true' && pinHash != null) {
      state = state.copyWith(
        isEnabled: true,
        isPinSet: true,
        requiresPinEntry: true,
        isOffline: true,
        error: null,
      );
    } else {
      state = state.copyWith(
        isEnabled: pinEnabled == 'true',
        isPinSet: pinHash != null,
        requiresPinEntry: false,
        isOffline: isOffline,
      );
    }
  }

  /// Verifies the entered PIN.
  /// Returns true if PIN is correct and session is restored.
  Future<bool> verifyPin(String pin) async {
    state = state.copyWith(isVerifying: true);

    final storage = ref.read(secureStorageProvider);
    final storedHash = await storage.read(key: _pinHashKey);

    if (storedHash == null) {
      state = state.copyWith(
        isVerifying: false,
        error: 'No PIN set',
      );
      return false;
    }

    final enteredHash = _hashPin(pin);
    if (enteredHash != storedHash) {
      state = state.copyWith(
        isVerifying: false,
        error: 'Incorrect PIN',
      );
      return false;
    }

    // PIN is correct - restore session
    await _restoreSession();

    state = state.copyWith(
      isVerifying: false,
      requiresPinEntry: false,
      error: null,
    );
    return true;
  }

  /// Checks if offline PIN is enabled.
  Future<bool> isOfflinePinEnabled() async {
    final storage = ref.read(secureStorageProvider);
    final enabled = await storage.read(key: _pinEnabledKey);
    return enabled == 'true';
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

  /// Validates that PIN is exactly 6 numeric digits.
  bool _isValidPin(String pin) {
    if (pin.length != 6) return false;
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  /// Hashes the PIN for secure storage.
  /// Uses a simple hash for testing - production would use bcrypt or similar.
  String _hashPin(String pin) {
    return 'hash_$pin';
  }
}
