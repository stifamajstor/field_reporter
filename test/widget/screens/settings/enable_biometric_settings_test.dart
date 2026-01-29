import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/biometric_provider.dart';
import 'package:field_reporter/features/settings/presentation/settings_screen.dart';

import 'enable_biometric_settings_test.mocks.dart';

@GenerateMocks([LocalAuthentication, FlutterSecureStorage])
void main() {
  group('User can enable biometric authentication after login', () {
    late MockLocalAuthentication mockLocalAuth;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      mockStorage = MockFlutterSecureStorage();
    });

    Widget createTestWidget(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      );
    }

    ProviderContainer createAuthenticatedContainer() {
      final container = ProviderContainer(
        overrides: [
          localAuthProvider.overrideWithValue(mockLocalAuth),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      // Set user as authenticated (simulating logged in state)
      container.read(authProvider.notifier).restoreSession(
            userId: 'user_1',
            email: 'test@example.com',
            token: 'test_token',
          );

      return container;
    }

    testWidgets('Settings screen displays Enable Biometric Login option',
        (tester) async {
      // Arrange: user is logged in
      when(mockStorage.read(key: 'biometric_enabled'))
          .thenAnswer((_) async => null);
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final container = createAuthenticatedContainer();
      addTearDown(container.dispose);

      // Act: navigate to Settings
      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Assert: Find 'Enable Biometric Login' option
      expect(find.text('Enable Biometric Login'), findsOneWidget);
    });

    testWidgets('Toggle biometric login on triggers system biometric prompt',
        (tester) async {
      // Arrange
      when(mockStorage.read(key: 'biometric_enabled'))
          .thenAnswer((_) async => null);
      when(mockStorage.write(key: 'biometric_enabled', value: 'true'))
          .thenAnswer((_) async {});
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);

      final container = createAuthenticatedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Act: Toggle biometric login on
      final toggle = find.byType(Switch);
      expect(toggle, findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Assert: Verify system biometric prompt was triggered
      verify(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).called(1);
    });

    testWidgets(
        'Successful biometric enrollment displays success message and persists setting',
        (tester) async {
      // Arrange
      when(mockStorage.read(key: 'biometric_enabled'))
          .thenAnswer((_) async => null);
      when(mockStorage.write(key: 'biometric_enabled', value: 'true'))
          .thenAnswer((_) async {});
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => true);

      final container = createAuthenticatedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Act: Toggle biometric login on
      final toggle = find.byType(Switch);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Assert: Verify success message is displayed
      expect(find.text('Biometric login enabled'), findsOneWidget);

      // Assert: Verify setting is persisted
      verify(mockStorage.write(key: 'biometric_enabled', value: 'true'))
          .called(1);
    });

    testWidgets('Toggle shows enabled state after successful enrollment',
        (tester) async {
      // Arrange: biometric already enabled
      when(mockStorage.read(key: 'biometric_enabled'))
          .thenAnswer((_) async => 'true');
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final container = createAuthenticatedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Assert: Toggle should be on
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('Failed biometric enrollment does not enable setting',
        (tester) async {
      // Arrange
      when(mockStorage.read(key: 'biometric_enabled'))
          .thenAnswer((_) async => null);
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);
      when(mockLocalAuth.authenticate(
        localizedReason: anyNamed('localizedReason'),
        options: anyNamed('options'),
      )).thenAnswer((_) async => false);

      final container = createAuthenticatedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Act: Toggle biometric login on
      final toggle = find.byType(Switch);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      // Assert: Toggle should still be off
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      // Assert: Setting should not be persisted
      verifyNever(mockStorage.write(key: 'biometric_enabled', value: 'true'));
    });

    testWidgets('Biometric option is hidden when device does not support it',
        (tester) async {
      // Arrange: device does not support biometrics
      when(mockStorage.read(key: 'biometric_enabled'))
          .thenAnswer((_) async => null);
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

      final container = createAuthenticatedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Assert: Biometric option should not be visible
      expect(find.text('Enable Biometric Login'), findsNothing);
    });
  });
}
