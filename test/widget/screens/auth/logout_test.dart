import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:field_reporter/features/auth/domain/auth_state.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/biometric_provider.dart';
import 'package:field_reporter/features/settings/presentation/settings_screen.dart';
import 'package:field_reporter/core/theme/app_theme.dart';

void main() {
  group('Logout functionality', () {
    testWidgets('User can logout from the app', (tester) async {
      // Track navigation to login screen
      var navigatedToLogin = false;

      // Create mock secure storage with pre-existing tokens
      final mockStorage = MockSecureStorage();
      mockStorage.storedValues['auth_token'] = 'test_token_123';
      mockStorage.storedValues['user_id'] = 'user_1';
      mockStorage.storedValues['user_email'] = 'test@example.com';

      // Create mock local auth
      final mockLocalAuth = MockLocalAuthentication();

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          localAuthProvider.overrideWithValue(mockLocalAuth),
        ],
      );

      // Pre-authenticate the user
      container.read(authProvider.notifier).restoreSession(
            userId: 'user_1',
            email: 'test@example.com',
            token: 'test_token_123',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: SettingsScreen(
              onLogout: () {
                navigatedToLogin = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: User is already logged in (verified by pre-authentication above)
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      // Step 2: User is on Settings screen (verified by widget being displayed)
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Step 3: Tap 'Logout' button
      final logoutButton = find.byKey(const Key('logout_button'));
      expect(logoutButton, findsOneWidget);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Step 4: Verify confirmation dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      // Step 5: Confirm logout
      final confirmButton = find.byKey(const Key('logout_confirm_button'));
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Step 6: Verify user is redirected to login screen
      expect(navigatedToLogin, isTrue);

      // Step 7: Verify local tokens are cleared
      expect(mockStorage.storedValues['auth_token'], isNull);
      expect(mockStorage.storedValues['user_id'], isNull);

      // Step 8: Verify cached sensitive data is cleared
      expect(mockStorage.storedValues['user_email'], isNull);

      // Verify auth state is unauthenticated
      expect(container.read(authProvider), isA<AuthUnauthenticated>());

      container.dispose();
    });

    testWidgets('User can cancel logout from confirmation dialog',
        (tester) async {
      var navigatedToLogin = false;

      final mockStorage = MockSecureStorage();
      mockStorage.storedValues['auth_token'] = 'test_token_123';
      mockStorage.storedValues['user_id'] = 'user_1';
      mockStorage.storedValues['user_email'] = 'test@example.com';

      final mockLocalAuth = MockLocalAuthentication();

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          localAuthProvider.overrideWithValue(mockLocalAuth),
        ],
      );

      container.read(authProvider.notifier).restoreSession(
            userId: 'user_1',
            email: 'test@example.com',
            token: 'test_token_123',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: SettingsScreen(
              onLogout: () {
                navigatedToLogin = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap logout button
      final logoutButton = find.byKey(const Key('logout_button'));
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Cancel logout
      final cancelButton = find.byKey(const Key('logout_cancel_button'));
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify user is NOT redirected to login
      expect(navigatedToLogin, isFalse);

      // Verify tokens are still present
      expect(mockStorage.storedValues['auth_token'], equals('test_token_123'));
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      container.dispose();
    });
  });
}

/// Mock LocalAuthentication for testing
class MockLocalAuthentication extends LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => false;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return [];
  }

  @override
  Future<bool> isDeviceSupported() async {
    return false;
  }
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
    required ValueChanged<String?> listener,
  }) {}

  @override
  void unregisterListener({
    required String key,
    required ValueChanged<String?> listener,
  }) {}

  @override
  void unregisterAllListeners() {}

  @override
  void unregisterAllListenersForKey({required String key}) {}
}
