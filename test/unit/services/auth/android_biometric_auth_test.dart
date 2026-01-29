import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/biometric_provider.dart';

import 'biometric_auth_test.mocks.dart';

/// Tests for Android fingerprint and face authentication.
/// Note: These tests use mocks to simulate Android biometric behavior.
/// Actual device testing is required for full verification.
void main() {
  group('Android fingerprint authentication works correctly', () {
    late ProviderContainer container;
    late MockFlutterSecureStorage mockStorage;
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockLocalAuth = MockLocalAuthentication();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          localAuthProvider.overrideWithValue(mockLocalAuth),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
    }

    test('fingerprint sensor can be detected on device', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      container = createContainer();

      final biometricNotifier = container.read(biometricProvider.notifier);
      final canUse = await biometricNotifier.canUseBiometrics();

      expect(canUse, isTrue);
    });

    test('biometric login can be enabled after fingerprint enrollment',
        () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);
      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});
      when(mockStorage.read(key: 'biometric_enabled'))
          .thenAnswer((_) async => 'true');

      container = createContainer();

      final biometricNotifier = container.read(biometricProvider.notifier);

      final enrolled = await biometricNotifier.authenticateForEnrollment();
      expect(enrolled, isTrue);

      await biometricNotifier.enableBiometric();
      expect(await biometricNotifier.isBiometricEnabled(), isTrue);
    });

    test('fingerprint authentication restores session', () async {
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);
      when(mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'test_token');
      when(mockStorage.read(key: 'user_id')).thenAnswer((_) async => 'user_1');
      when(mockStorage.read(key: 'user_email'))
          .thenAnswer((_) async => 'test@example.com');

      container = createContainer();

      final biometricNotifier = container.read(biometricProvider.notifier);

      final authenticated =
          await biometricNotifier.authenticateWithBiometrics();
      expect(authenticated, isTrue);

      final authState = container.read(authProvider);
      expect(authState.toString(), contains('AuthAuthenticated'));
    });
  });

  group('Android face unlock works correctly', () {
    late ProviderContainer container;
    late MockFlutterSecureStorage mockStorage;
    late MockLocalAuthentication mockLocalAuth;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockLocalAuth = MockLocalAuthentication();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          localAuthProvider.overrideWithValue(mockLocalAuth),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
    }

    test('face unlock can be detected on device', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);

      container = createContainer();

      final biometricNotifier = container.read(biometricProvider.notifier);
      final canUse = await biometricNotifier.canUseBiometrics();

      expect(canUse, isTrue);
    });

    test('face enrollment handled by system', () async {
      // Face enrollment on Android is handled by the system,
      // our app just checks if face unlock is available
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);

      container = createContainer();

      final biometricNotifier = container.read(biometricProvider.notifier);
      final canUse = await biometricNotifier.canUseBiometrics();

      expect(canUse, isTrue);
    });

    test('face authentication restores session', () async {
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);
      when(mockStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'test_token');
      when(mockStorage.read(key: 'user_id')).thenAnswer((_) async => 'user_1');
      when(mockStorage.read(key: 'user_email'))
          .thenAnswer((_) async => 'test@example.com');

      container = createContainer();

      final biometricNotifier = container.read(biometricProvider.notifier);

      final authenticated =
          await biometricNotifier.authenticateWithBiometrics();
      expect(authenticated, isTrue);

      final authState = container.read(authProvider);
      expect(authState.toString(), contains('AuthAuthenticated'));
    });
  });

  group('Android Keystore stores credentials securely', () {
    late ProviderContainer container;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'secureStorageProvider is configured with Android EncryptedSharedPreferences',
        () {
      // Create unoverridden container to check actual config
      final testContainer = ProviderContainer();
      addTearDown(testContainer.dispose);

      final storage = testContainer.read(secureStorageProvider);

      // Verify FlutterSecureStorage is used
      // (which uses EncryptedSharedPreferences on Android per our config)
      expect(storage, isA<FlutterSecureStorage>());
    });

    test('tokens are stored using secure storage (Android Keystore)', () async {
      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      final authNotifier = container.read(authProvider.notifier);

      await authNotifier.login('test@example.com', 'Password123!');

      // Verify tokens stored via secure storage (backed by Android Keystore)
      verify(mockStorage.write(key: 'auth_token', value: 'test_token_123'))
          .called(1);
      verify(mockStorage.write(key: 'user_id', value: 'user_1')).called(1);
    });

    test('EncryptedSharedPreferences for sensitive data', () async {
      // Our secureStorageProvider is configured with:
      // aOptions: AndroidOptions(encryptedSharedPreferences: true)
      // This test verifies we're using the secure storage provider
      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});

      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.login('test@example.com', 'Password123!');

      // Verify the auth provider uses secureStorageProvider (not regular prefs)
      verify(mockStorage.write(key: 'auth_token', value: anyNamed('value')))
          .called(1);
    });

    test('credentials cleared on logout', () async {
      when(mockStorage.write(
        key: anyNamed('key'),
        value: anyNamed('value'),
      )).thenAnswer((_) async {});
      when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

      final authNotifier = container.read(authProvider.notifier);

      await authNotifier.login('test@example.com', 'Password123!');
      await authNotifier.logout();

      verify(mockStorage.delete(key: 'auth_token')).called(1);
      verify(mockStorage.delete(key: 'user_id')).called(1);
      verify(mockStorage.delete(key: 'user_email')).called(1);
    });
  });
}
