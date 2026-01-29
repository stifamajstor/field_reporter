import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/offline_pin_provider.dart';
import 'package:field_reporter/features/auth/domain/auth_state.dart';
import 'package:field_reporter/services/connectivity_service.dart';

import 'offline_pin_auth_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage, ConnectivityService])
void main() {
  group('Offline PIN Fallback Authentication', () {
    late MockFlutterSecureStorage mockStorage;
    late MockConnectivityService mockConnectivity;
    late ProviderContainer container;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockConnectivity = MockConnectivityService();
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          connectivityServiceProvider.overrideWithValue(mockConnectivity),
        ],
      );
    }

    group('Offline PIN fallback allows access when biometrics unavailable', () {
      test('user can enable offline PIN in settings while online', () async {
        // Arrange: device is online
        when(mockConnectivity.isOnline).thenReturn(true);
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        container = createContainer();

        // Act: enable offline PIN
        final pinNotifier = container.read(offlinePinProvider.notifier);
        await pinNotifier.enableOfflinePin();

        // Assert: PIN is enabled
        final isEnabled = container.read(offlinePinProvider).isEnabled;
        expect(isEnabled, isTrue);
      });

      test('user can set a 6-digit PIN', () async {
        // Arrange
        when(mockConnectivity.isOnline).thenReturn(true);
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});
        when(mockStorage.read(key: 'offline_pin_enabled'))
            .thenAnswer((_) async => 'true');

        container = createContainer();

        // Act: set 6-digit PIN
        final pinNotifier = container.read(offlinePinProvider.notifier);
        await pinNotifier.enableOfflinePin();
        final result = await pinNotifier.setPin('123456');

        // Assert: PIN is set successfully
        expect(result, isTrue);
        verify(mockStorage.write(
                key: 'offline_pin_hash', value: anyNamed('value')))
            .called(1);
      });

      test('PIN must be exactly 6 digits', () async {
        // Arrange
        when(mockConnectivity.isOnline).thenReturn(true);
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        container = createContainer();

        // Act & Assert: 5-digit PIN fails
        final pinNotifier = container.read(offlinePinProvider.notifier);
        await pinNotifier.enableOfflinePin();

        final shortResult = await pinNotifier.setPin('12345');
        expect(shortResult, isFalse);

        // Act & Assert: 7-digit PIN fails
        final longResult = await pinNotifier.setPin('1234567');
        expect(longResult, isFalse);

        // Act & Assert: non-numeric PIN fails
        final alphaResult = await pinNotifier.setPin('123abc');
        expect(alphaResult, isFalse);
      });

      test('PIN entry screen appears when device is offline and app reopens',
          () async {
        // Arrange: device is offline, PIN was previously set
        when(mockConnectivity.isOnline).thenReturn(false);
        when(mockStorage.read(key: 'offline_pin_enabled'))
            .thenAnswer((_) async => 'true');
        when(mockStorage.read(key: 'offline_pin_hash'))
            .thenAnswer((_) async => 'hashed_pin_value');
        when(mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'stored_token');
        when(mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user_1');
        when(mockStorage.read(key: 'user_email'))
            .thenAnswer((_) async => 'test@example.com');

        container = createContainer();

        // Act: check auth requirements on app reopen
        final pinNotifier = container.read(offlinePinProvider.notifier);
        await pinNotifier.checkOfflineAuthRequired();

        // Assert: PIN entry is required
        final pinState = container.read(offlinePinProvider);
        expect(pinState.requiresPinEntry, isTrue);
        expect(pinState.isOffline, isTrue);
      });

      test('correct PIN grants access to offline-cached data', () async {
        // Arrange: device offline, user has cached credentials
        when(mockConnectivity.isOnline).thenReturn(false);
        when(mockStorage.read(key: 'offline_pin_enabled'))
            .thenAnswer((_) async => 'true');
        when(mockStorage.read(key: 'offline_pin_hash'))
            .thenAnswer((_) async => _hashPin('123456'));
        when(mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'offline_token');
        when(mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user_offline');
        when(mockStorage.read(key: 'user_email'))
            .thenAnswer((_) async => 'offline@example.com');

        container = createContainer();

        // Act: enter correct PIN
        final pinNotifier = container.read(offlinePinProvider.notifier);
        await pinNotifier.checkOfflineAuthRequired();
        final result = await pinNotifier.verifyPin('123456');

        // Assert: access granted
        expect(result, isTrue);

        // Verify auth state is restored
        final authState = container.read(authProvider);
        expect(authState, isA<AuthAuthenticated>());

        final authenticated = authState as AuthAuthenticated;
        expect(authenticated.userId, equals('user_offline'));
        expect(authenticated.email, equals('offline@example.com'));
      });

      test('incorrect PIN denies access', () async {
        // Arrange
        when(mockConnectivity.isOnline).thenReturn(false);
        when(mockStorage.read(key: 'offline_pin_enabled'))
            .thenAnswer((_) async => 'true');
        when(mockStorage.read(key: 'offline_pin_hash'))
            .thenAnswer((_) async => _hashPin('123456'));
        when(mockStorage.read(key: 'auth_token'))
            .thenAnswer((_) async => 'offline_token');
        when(mockStorage.read(key: 'user_id'))
            .thenAnswer((_) async => 'user_offline');
        when(mockStorage.read(key: 'user_email'))
            .thenAnswer((_) async => 'offline@example.com');

        container = createContainer();

        // Act: enter wrong PIN
        final pinNotifier = container.read(offlinePinProvider.notifier);
        await pinNotifier.checkOfflineAuthRequired();
        final result = await pinNotifier.verifyPin('654321');

        // Assert: access denied
        expect(result, isFalse);

        // Auth state should remain unauthenticated
        final authState = container.read(authProvider);
        expect(authState, isA<AuthUnauthenticated>());
      });

      test('PIN cannot be enabled while offline', () async {
        // Arrange: device is offline
        when(mockConnectivity.isOnline).thenReturn(false);

        container = createContainer();

        // Act: try to enable PIN
        final pinNotifier = container.read(offlinePinProvider.notifier);
        final result = await pinNotifier.enableOfflinePin();

        // Assert: fails because offline
        expect(result, isFalse);
      });

      test('disabling offline PIN removes stored PIN hash', () async {
        // Arrange
        when(mockConnectivity.isOnline).thenReturn(true);
        when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});

        container = createContainer();

        // Act: disable offline PIN
        final pinNotifier = container.read(offlinePinProvider.notifier);
        await pinNotifier.disableOfflinePin();

        // Assert: PIN data is cleared
        verify(mockStorage.delete(key: 'offline_pin_enabled')).called(1);
        verify(mockStorage.delete(key: 'offline_pin_hash')).called(1);
      });
    });
  });
}

/// Helper to create consistent PIN hash for testing.
/// In production, this would use a proper crypto hash.
String _hashPin(String pin) {
  // Simple hash for testing - production would use bcrypt or similar
  return 'hash_$pin';
}
