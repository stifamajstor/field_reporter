import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/presentation/login_screen.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/core/theme/app_theme.dart';

void main() {
  group('Password visibility toggle works correctly', () {
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

    testWidgets('password is masked by default', (tester) async {
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

      // Enter password
      final passwordField = find.byKey(const Key('login_password_field'));
      await tester.enterText(passwordField, 'TestPassword123');
      await tester.pump();

      // Verify password is masked - icon shows visibility_outlined (meaning tap to show)
      // When password is hidden, icon shows "eye" to indicate tapping will show it
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Also verify the actual TextField is obscured by checking descendant EditableText
      final editableText = tester.widget<EditableText>(
        find.descendant(
          of: passwordField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('tapping visibility toggle makes password visible',
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

      // Enter password
      final passwordField = find.byKey(const Key('login_password_field'));
      await tester.enterText(passwordField, 'TestPassword123');
      await tester.pump();

      // Verify password is initially masked
      var editableText = tester.widget<EditableText>(
        find.descendant(
          of: passwordField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isTrue);

      // Find and tap the visibility toggle
      final visibilityToggle = find.byIcon(Icons.visibility_outlined);
      expect(visibilityToggle, findsOneWidget);
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Verify password is now visible
      editableText = tester.widget<EditableText>(
        find.descendant(
          of: passwordField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isFalse);
    });

    testWidgets('tapping visibility toggle again masks password',
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

      // Enter password
      final passwordField = find.byKey(const Key('login_password_field'));
      await tester.enterText(passwordField, 'TestPassword123');
      await tester.pump();

      // First tap - show password
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Verify password is visible
      var editableText = tester.widget<EditableText>(
        find.descendant(
          of: passwordField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isFalse);

      // The icon should have changed to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Second tap - hide password again
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Verify password is masked again
      editableText = tester.widget<EditableText>(
        find.descendant(
          of: passwordField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('visibility icon changes based on state', (tester) async {
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

      // Initially shows visibility_outlined (indicating password is hidden, tap to show)
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Tap to show password
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now shows visibility_off_outlined (indicating password is shown, tap to hide)
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap to hide password
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      // Back to visibility_outlined
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
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
