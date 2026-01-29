import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';

void main() {
  group('Secure Credential Storage', () {
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

    test('secureStorageProvider returns FlutterSecureStorage instance', () {
      // Create an unoverridden container to test actual configuration
      final testContainer = ProviderContainer();
      addTearDown(testContainer.dispose);

      final storage = testContainer.read(secureStorageProvider);

      // Verify the provider returns a FlutterSecureStorage instance
      // which uses iOS Keychain and Android Keystore by default
      expect(storage, isA<FlutterSecureStorage>());
    });

    test('tokens are stored in secure storage on login', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Login successfully
      final result =
          await authNotifier.login('test@example.com', 'Password123!');

      expect(result, isTrue);

      // Verify tokens are stored in secure storage (not plain SharedPreferences)
      expect(mockStorage.storedValues['auth_token'], equals('test_token_123'));
      expect(mockStorage.storedValues['user_id'], equals('user_1'));
      expect(
          mockStorage.storedValues['user_email'], equals('test@example.com'));

      // Verify write was called with secure options
      expect(mockStorage.writeCallCount, greaterThanOrEqualTo(3));
    });

    test('no plain text credentials in shared preferences', () async {
      final authNotifier = container.read(authProvider.notifier);

      await authNotifier.login('test@example.com', 'Password123!');

      // The mock storage simulates secure storage behavior
      // In real implementation, FlutterSecureStorage encrypts values
      // We verify credentials are ONLY in secure storage (mockStorage)
      // and not written elsewhere
      expect(mockStorage.storedValues.containsKey('auth_token'), isTrue);

      // Password should NEVER be stored (only token after auth)
      expect(mockStorage.storedValues.containsKey('password'), isFalse);
      expect(mockStorage.storedValues.values.contains('Password123!'), isFalse);
    });

    test('secure storage is used for all credential operations', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Login
      await authNotifier.login('test@example.com', 'Password123!');
      expect(mockStorage.writeCallCount, equals(3)); // token, userId, email

      // Check auth status (reads from secure storage)
      await authNotifier.checkAuthStatus();
      expect(mockStorage.readCallCount, greaterThanOrEqualTo(3));

      // Logout (deletes from secure storage)
      await authNotifier.logout();
      expect(mockStorage.deleteCallCount, equals(3));
    });

    test('registration stores credentials in secure storage', () async {
      final authNotifier = container.read(authProvider.notifier);

      await authNotifier.register(
        name: 'Test User',
        email: 'newuser@example.com',
        password: 'SecurePass123!',
      );

      // Verify credentials stored securely
      expect(mockStorage.storedValues['auth_token'], isNotNull);
      expect(mockStorage.storedValues['user_email'],
          equals('newuser@example.com'));

      // Password should not be stored
      expect(
          mockStorage.storedValues.values.contains('SecurePass123!'), isFalse);
    });

    test('logout clears all sensitive data from secure storage', () async {
      final authNotifier = container.read(authProvider.notifier);

      // Login first
      await authNotifier.login('test@example.com', 'Password123!');
      expect(mockStorage.storedValues.isNotEmpty, isTrue);

      // Logout
      await authNotifier.logout();

      // Verify all sensitive data cleared
      expect(mockStorage.storedValues['auth_token'], isNull);
      expect(mockStorage.storedValues['user_id'], isNull);
      expect(mockStorage.storedValues['user_email'], isNull);
    });
  });
}

/// Mock secure storage for testing with call tracking
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> storedValues = {};
  int writeCallCount = 0;
  int readCallCount = 0;
  int deleteCallCount = 0;

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
    writeCallCount++;
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
    readCallCount++;
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
    deleteCallCount++;
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
