import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

/// Key for storing theme mode preference.
const _themeModeKey = 'theme_mode';

/// Provider for SharedPreferences instance.
///
/// This must be overridden in the app's main function:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   final prefs = await SharedPreferences.getInstance();
///   runApp(
///     ProviderScope(
///       overrides: [
///         sharedPreferencesProvider.overrideWithValue(prefs),
///       ],
///       child: const App(),
///     ),
///   );
/// }
/// ```
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a SharedPreferences instance',
  );
}

/// Notifier for managing the app's theme mode.
///
/// Persists the user's theme preference to SharedPreferences.
///
/// Usage in widget:
/// ```dart
/// final themeMode = ref.watch(appThemeModeProvider);
/// final themeModeNotifier = ref.read(appThemeModeProvider.notifier);
/// themeModeNotifier.setTheme(ThemeMode.dark);
/// ```
@Riverpod(keepAlive: true)
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_themeModeKey);

    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Sets the theme mode and persists it to storage.
  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Toggles between light and dark mode.
  ///
  /// If currently using system theme, switches to light mode.
  Future<void> toggle() async {
    final newMode = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
    await setTheme(newMode);
  }

  /// Resets to system theme mode.
  Future<void> useSystem() async {
    await setTheme(ThemeMode.system);
  }
}

/// Provider that returns true if dark mode is currently active.
///
/// Takes into account both user preference and system brightness.
@riverpod
bool isDarkMode(Ref ref) {
  final themeMode = ref.watch(appThemeModeProvider);

  if (themeMode == ThemeMode.system) {
    // This will be overridden in the widget tree with actual system brightness
    // Default to false (light mode) if accessed outside of widget context
    return false;
  }

  return themeMode == ThemeMode.dark;
}

/// Extension to easily check dark mode in BuildContext.
extension ThemeModeExtension on BuildContext {
  /// Returns true if dark mode is currently active.
  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }

  /// Returns the current brightness.
  Brightness get brightness => Theme.of(this).brightness;
}
