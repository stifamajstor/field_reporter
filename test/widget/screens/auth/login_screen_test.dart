import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/presentation/login_screen.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/core/theme/app_theme.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('User can login with email and password', (tester) async {
      // Track navigation to dashboard
      var navigatedToDashboard = false;

      // Create mock secure storage
      final mockStorage = MockSecureStorage();

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: LoginScreen(
              onLoginSuccess: () {
                navigatedToDashboard = true;
              },
            ),
          ),
        ),
      );

      // Step 1 & 2: Launch the app and verify login screen is displayed
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Login'), findsWidgets); // Title and button text

      // Verify email and password fields exist
      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(loginButton, findsOneWidget);

      // Step 3: Enter valid email address in email field
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Step 4: Enter valid password in password field
      await tester.enterText(passwordField, 'Password123!');
      await tester.pump();

      // Step 5: Tap the 'Login' button
      await tester.tap(loginButton);
      await tester.pump();

      // Step 6: Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Step 7: Verify successful login redirects to Dashboard
      expect(navigatedToDashboard, isTrue);

      // Step 8: Verify user token is stored securely in local storage
      expect(mockStorage.storedValues['auth_token'], equals('test_token_123'));

      container.dispose();
    });

    testWidgets('Login form validates email format', (tester) async {
      // Create mock secure storage
      final mockStorage = MockSecureStorage();

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LoginScreen(),
          ),
        ),
      );

      // Step 1: Navigate to login screen (already there)
      expect(find.byType(LoginScreen), findsOneWidget);

      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      // Step 2: Enter invalid email format
      await tester.enterText(emailField, 'notanemail');
      await tester.pump();

      // Step 3: Tap password field to trigger validation
      await tester.tap(passwordField);
      await tester.pump();

      // Also tap login button to ensure form validation runs
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Step 4: Verify email validation error is displayed
      expect(find.text('Please enter a valid email'), findsOneWidget);

      // Step 5: Enter valid email format
      await tester.enterText(emailField, 'valid@example.com');
      await tester.pump();

      // Tap login button to re-validate
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Step 6: Verify validation error disappears
      expect(find.text('Please enter a valid email'), findsNothing);

      container.dispose();
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
