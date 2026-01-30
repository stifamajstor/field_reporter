# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview
Field Reporter is a mobile-first documentation platform for field workers, built with Flutter. The app enables offline-first capture of photos, videos, audio, and notes with location metadata, automatic syncing, and PDF report generation. The design philosophy emphasizes "Confident Clarity" - a professional, utilitarian interface inspired by Swiss typography and Japanese minimalism.

## Current Development Status
This project is being developed in phases following PRD specifications located in `ralph-loop/`. The project uses a test-driven development approach with automated progress tracking.

**Completed Phases:**
- ✅ **Phase 1 (Auth)**: All 29 authentication scenarios complete - login/logout, biometrics, offline PIN, session management, multi-tenant
- ✅ **Phase 2 (Dashboard)**: All 20 dashboard scenarios complete - statistics, recent reports, sync status, quick capture FAB, offline support

**Pending Phases (not yet implemented):**
- ⏳ Phase 3: Projects management (create, edit, location, team management)
- ⏳ Phase 4: Reports (create, edit, organize entries)
- ⏳ Phase 5: Camera & Media (photo, video, audio capture with metadata)
- ⏳ Phase 6: Device Sensors (GPS, compass, accelerometer)
- ⏳ Phase 7: Location & Maps (geocoding, map views)
- ⏳ Phase 8: Entry Detail (view, edit individual entries)
- ⏳ Phase 9: Offline Sync (upload queue, retry logic, background sync)
- ⏳ Phase 10: AI Features (summaries, transcription)
- ⏳ Phase 11: PDF Generation (report export)
- ⏳ Phase 12: Notifications (push, local)
- ⏳ Phase 13: Settings (preferences, sync settings)
- ⏳ Phase 14: App Lifecycle (deep links, background tasks)

**Progress Tracking:**
- See `ralph-loop/progress.txt` for detailed scenario-by-scenario completion status
- Run `ralph-loop/progress-summary.sh` to generate current progress summary
- Each PRD file (`ralph-loop/XX-prd-*.json`) contains test scenarios for a phase

## Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Run code generation (for Riverpod, Retrofit, Drift)
dart run build_runner build --delete-conflicting-outputs

# Watch for changes and auto-generate
dart run build_runner watch --delete-conflicting-outputs
```

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/services/auth/biometric_auth_test.dart

# Run tests with coverage
flutter test --coverage

# Run widget tests only
flutter test test/widget/

# Run unit tests only
flutter test test/unit/

# Run integration tests (when available)
flutter test integration_test/

# Generate mocks for unit tests (using mockito)
dart run build_runner build --delete-conflicting-outputs
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Fix formatting issues
dart fix --apply
```

### Build
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android)
flutter build appbundle

# Build iOS
flutter build ios
```

## Architecture

### High-Level Structure
The codebase follows **feature-first architecture** organized around business capabilities. Each feature is self-contained with its own providers, domain models, and presentation layers.

```
lib/
├── core/              # Shared infrastructure
│   ├── theme/        # Design system (colors, typography, spacing, animations)
│   ├── constants/    # App-wide constants
│   ├── network/      # Network clients and configuration
│   ├── storage/      # Local database (Drift) setup
│   ├── utils/        # Utility functions
│   └── errors/       # Error handling
├── features/         # Business features (feature-first organization)
│   ├── auth/        # ✅ Authentication & authorization (COMPLETE)
│   ├── dashboard/   # ✅ Home dashboard (COMPLETE)
│   ├── capture/     # ⏳ Quick capture menu (partial - only menu logic)
│   ├── projects/    # ⏳ Project management (scaffolded - not implemented)
│   ├── reports/     # ⏳ Report creation & viewing (not implemented)
│   ├── entries/     # ⏳ Individual entries management (not implemented)
│   ├── sync/        # ⏳ Background sync logic (partial - providers only)
│   ├── ai/          # ⏳ AI-powered summaries (not implemented)
│   ├── maps/        # ⏳ Location & mapping (not implemented)
│   ├── notifications/ # ⏳ Push & local notifications (partial - domain only)
│   ├── pdf/         # ⏳ PDF generation (not implemented)
│   └── settings/    # ⏳ App settings (partial - basic screen only)
├── models/          # Shared data models
├── services/        # Cross-cutting services (connectivity service implemented)
├── widgets/         # Reusable UI components
│   ├── buttons/     # Primary button implemented
│   ├── cards/       # Stat cards, report cards implemented
│   ├── indicators/  # Sync status, offline indicators implemented
│   ├── layout/      # Empty state implemented
│   └── feedback/    # Skeleton loader implemented
├── providers/       # Global providers
├── app.dart         # Root app configuration
└── main.dart        # Entry point
```

### Feature Module Pattern
Each feature follows a consistent structure:
```
features/<feature_name>/
├── domain/          # Business logic & data models (sealed classes)
├── providers/       # Riverpod state management (with code generation)
├── presentation/    # UI screens and widgets
└── services/        # Feature-specific services (e.g., token_refresh_service.dart)
```

### State Management
- **Riverpod 2.x** with code generation (`riverpod_annotation`, `riverpod_generator`)
- Providers are defined with `@riverpod` annotation and generate `.g.dart` files
- Use `@Riverpod(keepAlive: true)` for singleton-like providers (e.g., auth, storage)
- Domain models use **sealed classes** for type-safe state representation (NOT Freezed)

### Data Layer
- **Drift** for local SQLite database (offline-first) - not yet implemented
- **Flutter Secure Storage** for sensitive data (tokens, credentials) - implemented in auth
- **SharedPreferences** for simple key-value storage (theme, settings) - used for theme persistence
- **Retrofit + Dio** for REST API calls (when online) - not yet implemented

### Navigation
- **GoRouter** for declarative routing - not yet implemented (currently using basic MaterialApp)
- Will support deep linking and navigation state restoration

### Design System
See `DESIGN_GUIDELINES.md` for comprehensive UI/UX specifications. Key design tokens:

**Colors:**
- Primary: Orange `#F97316` (warm, action-oriented)
- Neutrals: Slate scale (900 → 100)
- Semantics: Emerald (success), Amber (warning), Rose (error)
- Dark mode: True black OLED-friendly (`#0A0A0A`)

**Typography:**
- Primary: DM Sans (clean, modern geometric sans)
- Monospace: JetBrains Mono (for technical data - coordinates, timestamps)
- Scale: Display → Headline → Body → Caption → Overline

**Spacing:**
- 8px grid system
- Use `AppSpacing.*` constants (xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48, xxxl: 64)
- Screen margins: 20px horizontal, 24px vertical
- Card padding: 16px

**All design tokens are in:**
- `lib/core/theme/app_colors.dart` - complete light/dark color palette
- `lib/core/theme/app_typography.dart` - complete type scale
- `lib/core/theme/app_spacing.dart` - spacing system
- `lib/core/theme/app_animations.dart` - curves and durations
- `lib/core/theme/app_theme.dart` - complete ThemeData for light/dark modes

## Code Patterns

### Domain Models (Sealed Classes)
Use **sealed classes** for type-safe state representation:
```dart
sealed class AuthState {
  const AuthState();
  const factory AuthState.authenticated({...}) = AuthAuthenticated;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.error(String message) = AuthError;
}
```

Key characteristics:
- Exhaustive pattern matching
- No Freezed dependency
- Manual equality/hashCode implementation when needed
- Immutable with `@immutable` annotation

### Providers (Riverpod)
All providers use code generation with `@riverpod`:
```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => const MyState.initial();
  
  void doSomething() {
    state = state.copyWith(...);
  }
}

// Singleton-like providers
@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(...);
}
```

### Testing Patterns
**Widget Tests:**
```dart
testWidgets('description', (WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: MyWidget()),
  );
  expect(find.text('Expected'), findsOneWidget);
});
```

**Unit Tests with Mocking:**
```dart
@GenerateMocks([LocalAuthentication, FlutterSecureStorage])
void main() {
  late MockLocalAuthentication mockLocalAuth;
  late ProviderContainer container;
  
  setUp(() {
    mockLocalAuth = MockLocalAuthentication();
    container = ProviderContainer(
      overrides: [
        localAuthProvider.overrideWithValue(mockLocalAuth),
      ],
    );
  });
  
  test('scenario', () async {
    when(mockLocalAuth.authenticate(...)).thenAnswer((_) async => true);
    final notifier = container.read(myProvider.notifier);
    await notifier.doSomething();
    expect(container.read(myProvider), expected);
  });
}
```

### Code Generation Dependencies
The project relies heavily on code generation. **Always run build_runner after modifying:**
- `@riverpod` providers → generates `*.g.dart` files
- Drift tables → generates database code (when implemented)
- Retrofit API clients → generates REST client code (when implemented)
- Mockito `@GenerateMocks` → generates mock classes for testing

## Important Conventions

### File Naming
- Dart files: `snake_case.dart`
- Classes: `PascalCase`
- Functions/variables: `camelCase`
- Constants: `camelCase` (not `SCREAMING_SNAKE_CASE`)
- Test files: `*_test.dart`
- Generated files: `*.g.dart` (auto-generated, not manually edited)

### Theme Usage
- **Always reference colors via `AppColors.*`** (never hardcode hex values)
- Use `AppTypography.*` for text styles
- Use `AppSpacing.*` for consistent spacing
- Use `AppAnimations.*` for animation curves/durations
- Support both light and dark modes in all UI

### Offline-First Architecture
- All features must work offline (not yet fully implemented)
- Use Drift for local caching (planned)
- Sync queues managed by `features/sync/` (partial implementation)
- Always show local data first, sync in background
- Display offline indicators when disconnected

### Error Handling
- Network errors should gracefully fallback to cached data
- Show clear error states to users
- Use semantic error types in domain models (e.g., `AuthNetworkError`, `AuthError`, `AuthAccountLocked`)

### User Preferences
- **Testing Framework**: Use `flutter_test` (not Pest - that's for PHP, but the rule specifies Pest preference, so keep it in mind if there's confusion)

## Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Native configuration in `android/` directory
- Biometric authentication uses Android Keystore

### iOS
- Minimum iOS: 12.0
- Native configuration in `ios/` directory
- Camera and location permissions required in `Info.plist`
- Biometric authentication uses iOS Keychain

### macOS
- Experimental support in `macos/` directory

## Dependencies Overview
**State Management:**
- `flutter_riverpod: ^2.4.0` - Riverpod integration with Flutter
- `riverpod_annotation: ^2.3.0` - Annotations for code generation
- `riverpod_generator: ^2.3.0` (dev) - Code generator

**UI:**
- `flutter_svg: ^2.0.9` - SVG rendering
- `cached_network_image: ^3.3.0` - Image caching
- `shimmer: ^3.0.0` - Skeleton loading animations

**Navigation:**
- `go_router: ^12.0.0` - Declarative routing (planned)

**Network:**
- `dio: ^5.3.0` - HTTP client (planned)
- `retrofit: ^4.0.0` - REST API client (planned)

**Local Storage:**
- `drift: ^2.13.0` - SQLite ORM (planned)
- `flutter_secure_storage: ^9.0.0` - Secure credential storage
- `shared_preferences: ^2.2.0` - Simple key-value storage

**Camera & Media:**
- `camera: ^0.10.5` - Camera access (planned)
- `video_player: ^2.8.0` - Video playback (planned)
- `audio_waveforms: ^1.0.4` - Audio visualization (planned)
- `record: ^5.0.4` - Audio recording (planned)
- `image_picker: ^1.0.4` - Gallery picker (planned)

**Location & Maps:**
- `geolocator: ^10.1.0` - GPS location (planned)
- `geocoding: ^2.1.1` - Address geocoding (planned)
- `flutter_map: ^6.0.1` - Map display (planned)

**Sensors:**
- `sensors_plus: ^4.0.2` - Accelerometer (planned)
- `flutter_compass: ^0.8.0` - Compass (planned)

**Security:**
- `local_auth: ^2.1.6` - Biometric authentication

**PDF:**
- `pdf: ^3.10.4` - PDF generation (planned)
- `printing: ^5.11.1` - PDF preview/print (planned)

**Testing:**
- `flutter_test` (SDK) - Testing framework
- `mockito: ^5.4.3` - Mocking library
- `build_runner: ^2.4.6` - Code generation runner

## Project-Specific Context

### ralph-loop Directory
Contains PRD specifications and progress tracking:
- `01-prd-auth.json` through `14-prd-app-lifecycle.json` - Test scenarios for each phase
- `progress.txt` - Line-by-line completion log with timestamps
- `progress-summary.sh` - Script to generate progress summary
- `ralph.sh` - Automation script for iterative development
- `CLAUDE_CODE_INSTRUCTIONS.md` - Additional context for AI assistants

### Design Philosophy: "Confident Clarity"
- Every interaction should feel precise and inevitable (like Tetris)
- Micro-interactions are subtle, not shouty
- No bouncy/springy animations (too playful)
- Professional instrument aesthetic
- Haptics are felt, not noticed
- Skeleton loaders match content shapes exactly

### Testing Approach
- Test-driven development (TDD) using PRD scenarios
- Each scenario has detailed steps and pass/fail criteria
- Both widget tests and unit tests
- Screen reader accessibility testing included
- Platform-specific tests (iOS/Android)

## Additional Resources
- **Design Guidelines**: `DESIGN_GUIDELINES.md` - Comprehensive 1300+ line UI/UX specification
- **README**: `README.md` - Basic project information
- **PRD Files**: `ralph-loop/*.json` - Detailed test scenarios for all features
- **Progress Log**: `ralph-loop/progress.txt` - Real-time completion tracking
