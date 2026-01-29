import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/presentation/login_screen.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/core/theme/app_theme.dart';
import 'package:field_reporter/widgets/buttons/primary_button.dart';

void main() {
  group('Loading states are displayed during authentication', () {
    late MockSecureStorage mockStorage;
    late ProviderContainer container;

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

    testWidgets('loading indicator appears after tapping login',
        (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Password123!');
      await tester.pump();

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump(); // One frame after tap

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for login to complete
      await tester.pumpAndSettle();
    });

    testWidgets('login button is disabled during loading', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Password123!');
      await tester.pump();

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump();

      // Verify login button is disabled during loading
      final button = tester.widget<PrimaryButton>(loginButton);
      expect(button.onPressed, isNull);
      expect(button.isLoading, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('input fields are disabled during loading', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Password123!');
      await tester.pump();

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump();

      // Verify input fields are disabled during loading
      final emailFormField = tester.widget<TextFormField>(emailField);
      final passwordFormField = tester.widget<TextFormField>(passwordField);

      expect(emailFormField.enabled, isFalse);
      expect(passwordFormField.enabled, isFalse);

      await tester.pumpAndSettle();
    });

    testWidgets('loading state clears after successful login', (tester) async {
      var navigatedToDashboard = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: LoginScreen(
              onLoginSuccess: () => navigatedToDashboard = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'Password123!');
      await tester.pump();

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Verify navigation occurred (loading ended successfully)
      expect(navigatedToDashboard, isTrue);
    });

    testWidgets('loading state clears after failed login', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid credentials
      final emailField = find.byKey(const Key('login_email_field'));
      final passwordField = find.byKey(const Key('login_password_field'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pump();

      // Tap login button
      await tester.tap(loginButton);
      await tester.pump();

      // Wait for login to complete
      await tester.pumpAndSettle();

      // Verify loading indicator is gone
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify error message is shown
      expect(find.text('Invalid credentials'), findsOneWidget);

      // Verify form fields are re-enabled
      final emailFormField = tester.widget<TextFormField>(emailField);
      expect(emailFormField.enabled, isTrue);

      // Verify login button is re-enabled
      final button = tester.widget<PrimaryButton>(loginButton);
      expect(button.onPressed, isNotNull);
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
