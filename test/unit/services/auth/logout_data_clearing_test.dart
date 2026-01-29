import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/biometric_provider.dart';

void main() {
  group('App clears sensitive data on logout', () {
    late ProviderContainer container;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('auth tokens are removed on logout', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Login first to populate storage
      await authNotifier.login('test@example.com', 'Password123!');
      expect(mockStorage.storedValues['auth_token'], isNotNull);
      expect(mockStorage.storedValues['user_id'], isNotNull);

      // Logout
      await authNotifier.logout();

      // Verify auth tokens are removed
      expect(mockStorage.storedValues['auth_token'], isNull);
      expect(mockStorage.storedValues['user_id'], isNull);
    });

    test('cached user data is cleared on logout', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Login first
      await authNotifier.login('test@example.com', 'Password123!');
      expect(mockStorage.storedValues['user_email'], isNotNull);

      // Logout
      await authNotifier.logout();

      // Verify user data is cleared
      expect(mockStorage.storedValues['user_email'], isNull);
    });

    test('biometric credentials are retained for next login', () async {
      final authNotifier = container.read(authProvider.notifier);
      final biometricNotifier = container.read(biometricProvider.notifier);

      // Enable biometrics before login
      await biometricNotifier.enableBiometric();
      expect(await biometricNotifier.isBiometricEnabled(), isTrue);

      // Login
      await authNotifier.login('test@example.com', 'Password123!');

      // Logout
      await authNotifier.logout();

      // Verify biometric setting is retained
      expect(await biometricNotifier.isBiometricEnabled(), isTrue);
      expect(mockStorage.storedValues['biometric_enabled'], equals('true'));
    });

    test('all auth data cleared but biometric preference preserved', () async {
      final authNotifier = container.read(authProvider.notifier);
      final biometricNotifier = container.read(biometricProvider.notifier);

      // Enable biometrics
      await biometricNotifier.enableBiometric();

      // Login and verify data stored
      await authNotifier.login('user@example.com', 'Password123!');
      expect(mockStorage.storedValues.length, greaterThanOrEqualTo(4));

      // Logout
      await authNotifier.logout();

      // Verify only biometric enabled is retained
      expect(mockStorage.storedValues['auth_token'], isNull);
      expect(mockStorage.storedValues['user_id'], isNull);
      expect(mockStorage.storedValues['user_email'], isNull);
      expect(mockStorage.storedValues['biometric_enabled'], equals('true'));
    });

    test('logout clears data completely when biometrics not enabled', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Login without enabling biometrics
      await authNotifier.login('test@example.com', 'Password123!');

      // Logout
      await authNotifier.logout();

      // Verify all data is cleared
      expect(mockStorage.storedValues['auth_token'], isNull);
      expect(mockStorage.storedValues['user_id'], isNull);
      expect(mockStorage.storedValues['user_email'], isNull);
      expect(mockStorage.storedValues['biometric_enabled'], isNull);
    });

    test('check secure storage after logout via checkAuthStatus', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Login
      await authNotifier.login('test@example.com', 'Password123!');

      // Logout
      await authNotifier.logout();

      // Check auth status should show unauthenticated
      await authNotifier.checkAuthStatus();
      final state = container.read(authProvider);
      expect(state.toString(), contains('AuthUnauthenticated'));
    });
  });
}

/// Mock secure storage for testing
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> storedValues = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      storedValues[key] = value;
    } else {
      storedValues.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storedValues[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storedValues.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storedValues.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(storedValues);
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storedValues.containsKey(key);
  }

  @override
  IOSOptions get iOptions => const IOSOptions();

  @override
  AndroidOptions get aOptions => const AndroidOptions();

  @override
  LinuxOptions get lOptions => const LinuxOptions();

  @override
  WebOptions get webOptions => const WebOptions();

  @override
  MacOsOptions get mOptions => const MacOsOptions();

  @override
  WindowsOptions get wOptions => const WindowsOptions();

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async => true;

  @override
  Stream<bool> get onCupertinoProtectedDataAvailabilityChanged =>
      Stream.value(true);

  @override
  void registerListener({
    required String key,
    required void Function(String?) listener,
  }) {}

  @override
  void unregisterListener({
    required String key,
    required void Function(String?) listener,
  }) {}

  @override
  void unregisterAllListeners() {}

  @override
  void unregisterAllListenersForKey({required String key}) {}
}
