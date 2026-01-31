import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/presentation/main_shell.dart';

/// Field Reporter Application
///
/// Root app widget with theme configuration and auth-based routing.
class FieldReporterApp extends ConsumerWidget {
  const FieldReporterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Field Reporter',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

/// Simple auth gate to navigate between login and main shell.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show main shell if authenticated, otherwise show login
    if (authState is AuthAuthenticated) {
      return const MainShell();
    }

    return LoginScreen(
      onLoginSuccess: () {
        // Navigation is handled by watching authProvider in build
      },
    );
  }
}
