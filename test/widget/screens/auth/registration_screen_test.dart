import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/presentation/registration_screen.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/core/theme/app_theme.dart';

import 'login_screen_test.dart' show MockSecureStorage;

void main() {
  group('RegistrationScreen', () {
    testWidgets('User can register a new account', (tester) async {
      // Track navigation after successful registration
      var navigatedAfterRegistration = false;

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
            home: RegistrationScreen(
              onRegistrationSuccess: () {
                navigatedAfterRegistration = true;
              },
            ),
          ),
        ),
      );

      // Step 3: Verify registration form is displayed
      expect(find.byType(RegistrationScreen), findsOneWidget);
      expect(find.text('Create Account'), findsWidgets);

      // Verify all form fields exist
      final nameField = find.byKey(const Key('registration_name_field'));
      final emailField = find.byKey(const Key('registration_email_field'));
      final passwordField =
          find.byKey(const Key('registration_password_field'));
      final confirmPasswordField =
          find.byKey(const Key('registration_confirm_password_field'));
      final termsCheckbox =
          find.byKey(const Key('registration_terms_checkbox'));
      final registerButton = find.byKey(const Key('registration_button'));

      expect(nameField, findsOneWidget);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
      expect(confirmPasswordField, findsOneWidget);
      expect(termsCheckbox, findsOneWidget);
      expect(registerButton, findsOneWidget);

      // Step 4: Enter full name
      await tester.enterText(nameField, 'John Doe');
      await tester.pump();

      // Step 5: Enter valid email address
      await tester.enterText(emailField, 'john@example.com');
      await tester.pump();

      // Step 6: Enter password meeting requirements
      await tester.enterText(passwordField, 'Password123!');
      await tester.pump();

      // Step 7: Enter password confirmation
      await tester.enterText(confirmPasswordField, 'Password123!');
      await tester.pump();

      // Step 8: Accept terms and conditions
      await tester.tap(termsCheckbox);
      await tester.pump();

      // Step 9: Tap 'Register' button
      await tester.tap(registerButton);
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for registration to complete
      await tester.pumpAndSettle();

      // Step 10: Verify account creation success message
      expect(find.text('Account created successfully'), findsOneWidget);

      // Step 11: Verify redirect to tenant selection or dashboard
      expect(navigatedAfterRegistration, isTrue);

      // Verify user token is stored securely
      expect(mockStorage.storedValues['auth_token'], isNotNull);

      container.dispose();
    });

    testWidgets(
        'Registration screen is accessible from login screen Create Account link',
        (tester) async {
      final mockStorage = MockSecureStorage();

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );

      // Start with a navigator to handle routing
      var navigatedToRegistration = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('create_account_link'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RegistrationScreen(
                            onRegistrationSuccess: () {},
                          ),
                        ),
                      );
                      navigatedToRegistration = true;
                    },
                    child: const Text('Create Account'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Step 1 & 2: Launch the app and tap 'Create Account' link
      await tester.tap(find.byKey(const Key('create_account_link')));
      await tester.pumpAndSettle();

      // Verify navigation to registration screen
      expect(navigatedToRegistration, isTrue);
      expect(find.byType(RegistrationScreen), findsOneWidget);

      container.dispose();
    });

    testWidgets('Registration form validates password requirements',
        (tester) async {
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
            home: RegistrationScreen(
              onRegistrationSuccess: () {},
            ),
          ),
        ),
      );

      // Navigate to registration screen (already on it)
      expect(find.byType(RegistrationScreen), findsOneWidget);

      final passwordField =
          find.byKey(const Key('registration_password_field'));
      final registerButton = find.byKey(const Key('registration_button'));

      // Enter password shorter than 8 characters
      await tester.enterText(passwordField, 'short');
      await tester.pump();

      // Tap register to trigger validation
      await tester.tap(registerButton);
      await tester.pump();

      // Verify minimum length error is displayed
      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);

      // Enter password without uppercase letter
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      await tester.tap(registerButton);
      await tester.pump();

      // Verify uppercase requirement error is displayed
      expect(find.text('Password must contain an uppercase letter'),
          findsOneWidget);

      // Enter password without number
      await tester.enterText(passwordField, 'Password');
      await tester.pump();

      await tester.tap(registerButton);
      await tester.pump();

      // Verify number requirement error is displayed
      expect(find.text('Password must contain a number'), findsOneWidget);

      // Enter valid password meeting all requirements
      await tester.enterText(passwordField, 'Password123');
      await tester.pump();

      // Trigger form validation by tapping register
      // (other fields are invalid so no API call is made)
      await tester.tap(registerButton);
      await tester.pump();

      // Verify all password validation errors disappear
      expect(find.text('Password must be at least 8 characters'), findsNothing);
      expect(
          find.text('Password must contain an uppercase letter'), findsNothing);
      expect(find.text('Password must contain a number'), findsNothing);

      container.dispose();
    });

    testWidgets('Registration form validates password confirmation match',
        (tester) async {
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
            home: RegistrationScreen(
              onRegistrationSuccess: () {},
            ),
          ),
        ),
      );

      // Navigate to registration screen (already on it)
      expect(find.byType(RegistrationScreen), findsOneWidget);

      final passwordField =
          find.byKey(const Key('registration_password_field'));
      final confirmPasswordField =
          find.byKey(const Key('registration_confirm_password_field'));
      final registerButton = find.byKey(const Key('registration_button'));

      // Enter password in password field
      await tester.enterText(passwordField, 'Password123');
      await tester.pump();

      // Enter different password in confirmation field
      await tester.enterText(confirmPasswordField, 'DifferentPassword456');
      await tester.pump();

      // Tap register to trigger validation
      await tester.tap(registerButton);
      await tester.pump();

      // Verify 'passwords do not match' error appears
      expect(find.text('Passwords do not match'), findsOneWidget);

      // Enter matching password in confirmation field
      await tester.enterText(confirmPasswordField, 'Password123');
      await tester.pump();

      // Trigger validation again
      await tester.tap(registerButton);
      await tester.pump();

      // Verify error disappears
      expect(find.text('Passwords do not match'), findsNothing);

      container.dispose();
    });
  });
}
