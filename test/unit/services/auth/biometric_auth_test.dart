import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/biometric_provider.dart';
import 'package:field_reporter/features/auth/domain/auth_state.dart';

import 'biometric_auth_test.mocks.dart';

@GenerateMocks([LocalAuthentication, FlutterSecureStorage])
void main() {
  group('Biometric Authentication', () {
    late MockLocalAuthentication mockLocalAuth;
    late MockFlutterSecureStorage mockStorage;
    late ProviderContainer container;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      mockStorage = MockFlutterSecureStorage();
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

    group('User can login with biometric authentication', () {
      test(
          'biometric prompt appears when user has previously logged in and enabled biometrics',
          () async {
        // Arrange: user has previously logged in and enabled biometrics
        when(mockStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');
        when(mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'stored_token');
        when(mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user_1');
        when(mockStorage.read(key: 'user_email'))
            .thenAnswer((_) async => 'test@example.com');
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);

        container = createContainer();

        // Act
        final biometricNotifier = container.read(biometricProvider.notifier);
        final canUseBiometrics = await biometricNotifier.canUseBiometrics();
        final hasBiometricsEnabled =
            await biometricNotifier.isBiometricEnabled();

        // Assert: biometric should be available to show prompt
        expect(canUseBiometrics, isTrue);
        expect(hasBiometricsEnabled, isTrue);
      });

      test('successful biometric authentication redirects to Dashboard',
          () async {
        // Arrange
        when(mockStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');
        when(mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'stored_token');
        when(mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user_1');
        when(mockStorage.read(key: 'user_email'))
            .thenAnswer((_) async => 'test@example.com');
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        container = createContainer();

        // Act: authenticate with biometrics
        final biometricNotifier = container.read(biometricProvider.notifier);
        final authResult = await biometricNotifier.authenticateWithBiometrics();

        // Assert: authentication succeeded
        expect(authResult, isTrue);

        // Verify session is restored - check auth state
        final authState = container.read(authProvider);
        expect(authState, isA<AuthAuthenticated>());

        final authenticated = authState as AuthAuthenticated;
        expect(authenticated.userId, equals('user_1'));
        expect(authenticated.email, equals('test@example.com'));
        expect(authenticated.token, equals('stored_token'));
      });

      test('session is restored correctly after biometric authentication',
          () async {
        // Arrange
        when(mockStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');
        when(mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'my_secure_token');
        when(mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user_123');
        when(mockStorage.read(key: 'user_email'))
            .thenAnswer((_) async => 'john@example.com');
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => true);

        container = createContainer();

        // Act
        final biometricNotifier = container.read(biometricProvider.notifier);
        await biometricNotifier.authenticateWithBiometrics();

        // Assert: session restored with correct data
        final authState = container.read(authProvider);
        expect(authState, isA<AuthAuthenticated>());

        final authenticated = authState as AuthAuthenticated;
        expect(authenticated.token, equals('my_secure_token'));
        expect(authenticated.userId, equals('user_123'));
        expect(authenticated.email, equals('john@example.com'));
      });

      test('failed biometric authentication does not login user', () async {
        // Arrange
        when(mockStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');
        when(mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'stored_token');
        when(mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user_1');
        when(mockStorage.read(key: 'user_email'))
            .thenAnswer((_) async => 'test@example.com');
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);
        when(mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => false);

        container = createContainer();

        // Act
        final biometricNotifier = container.read(biometricProvider.notifier);
        final result = await biometricNotifier.authenticateWithBiometrics();

        // Assert
        expect(result, isFalse);
        final authState = container.read(authProvider);
        expect(authState, isA<AuthUnauthenticated>());
      });

      test('biometric prompt does not appear if biometrics not enabled',
          () async {
        // Arrange: user has not enabled biometrics
        when(mockStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => null);
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

        container = createContainer();

        // Act
        final biometricNotifier = container.read(biometricProvider.notifier);
        final hasBiometricsEnabled =
            await biometricNotifier.isBiometricEnabled();

        // Assert
        expect(hasBiometricsEnabled, isFalse);
      });

      test('biometric not available if device does not support it', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        container = createContainer();

        // Act
        final biometricNotifier = container.read(biometricProvider.notifier);
        final canUseBiometrics = await biometricNotifier.canUseBiometrics();

        // Assert
        expect(canUseBiometrics, isFalse);
      });
    });
  });
}
