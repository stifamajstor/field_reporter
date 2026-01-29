import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/presentation/forgot_password_screen.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/core/theme/app_theme.dart';

import 'login_screen_test.dart';

void main() {
  group('ForgotPasswordScreen', () {
    testWidgets('User can request password reset', (tester) async {
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
            home: const ForgotPasswordScreen(),
          ),
        ),
      );

      // Step 3: Verify password reset form appears
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Reset Password'), findsWidgets);

      // Verify email field exists
      final emailField = find.byKey(const Key('forgot_password_email_field'));
      expect(emailField, findsOneWidget);

      // Verify send reset link button exists
      final sendButton = find.byKey(const Key('send_reset_link_button'));
      expect(sendButton, findsOneWidget);

      // Step 4: Enter registered email address
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Step 5: Tap 'Send Reset Link' button
      await tester.tap(sendButton);
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for request to complete
      await tester.pumpAndSettle();

      // Step 6: Verify success message is displayed
      expect(find.textContaining('Reset link sent'), findsOneWidget);

      // Step 7: Verify instruction to check email is shown
      expect(find.textContaining('Check your email'), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows validation error for empty email', (tester) async {
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
            home: const ForgotPasswordScreen(),
          ),
        ),
      );

      // Tap send button without entering email
      final sendButton = find.byKey(const Key('send_reset_link_button'));
      await tester.tap(sendButton);
      await tester.pump();

      // Verify validation error
      expect(find.text('Please enter your email'), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows validation error for invalid email format',
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
            home: const ForgotPasswordScreen(),
          ),
        ),
      );

      // Enter invalid email
      final emailField = find.byKey(const Key('forgot_password_email_field'));
      await tester.enterText(emailField, 'notanemail');
      await tester.pump();

      // Tap send button
      final sendButton = find.byKey(const Key('send_reset_link_button'));
      await tester.tap(sendButton);
      await tester.pump();

      // Verify validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);

      container.dispose();
    });
  });
}
