# Field Reporter - Claude Code Implementation Guide

## Overview

This document provides structured instructions for Claude Code to implement the Field Reporter Flutter application. The app is a mobile-first documentation platform where field workers capture evidence (photos, videos, audio, notes), AI processes it into professional reports, and everything syncs to a multi-tenant backend.

**Important**: This entire application will be built by Claude Code using the PRD JSON files as the source of truth for features and acceptance criteria.

---

## Design System Reference

**CRITICAL**: Before implementing any UI components, screens, or visual elements, you MUST read and follow the design guidelines document:

📄 **[DESIGN_GUIDELINES.md](../DESIGN_GUIDELINES.md)** - The definitive source of truth for all visual design decisions.

This document contains:
- **Color System** - Light and dark mode palettes with exact hex values
- **Typography** - Font families (DM Sans, JetBrains Mono), text styles, and scale
- **Spacing & Layout** - 8px grid system, margins, and padding values
- **Component Patterns** - Buttons, cards, inputs, indicators with code examples
- **Micro-interactions** - Animation curves, timing, haptic feedback rules
- **Dark Mode** - Complete implementation strategy and color mappings
- **Accessibility** - Touch targets, contrast ratios, screen reader support
- **Do's and Don'ts** - Clear examples of what to follow and avoid

### Design Principles (Summary)

The design philosophy is **"Confident Clarity"** with a **"Refined Utilitarian"** aesthetic:
- Swiss/International typography - Clean, confident, hierarchical
- Japanese minimalism - Purposeful negative space, calm restraint
- Professional instrument design - Precision indicators, confident feedback

**NOT:** Generic Material Design, playful/bubbly UI, heavy gradients, busy dashboards

### When to Reference DESIGN_GUIDELINES.md

- Creating any new screen or widget
- Adding colors, fonts, or spacing
- Implementing animations or transitions
- Adding haptic feedback
- Creating loading states or empty states
- Building dark mode support
- Ensuring accessibility compliance

---

## Project Structure

```
field-reporter/
├── android/                    # Android native code
├── ios/                        # iOS native code
├── lib/
│   ├── main.dart              # App entry point
│   ├── app.dart               # App configuration, routing, themes
│   ├── core/                  # Core utilities and shared code
│   │   ├── constants/         # App-wide constants
│   │   ├── errors/            # Error handling, exceptions
│   │   ├── network/           # API client, interceptors
│   │   ├── storage/           # Local database, secure storage
│   │   └── utils/             # Helper functions
│   ├── features/              # Feature modules (domain-driven)
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── projects/
│   │   ├── reports/
│   │   ├── capture/           # Camera, audio, scanning
│   │   ├── entries/           # Entry detail, media viewer
│   │   ├── sync/              # Offline sync management
│   │   ├── ai/                # AI processing features
│   │   ├── pdf/               # PDF generation
│   │   ├── notifications/
│   │   ├── settings/
│   │   └── maps/              # Location and mapping
│   ├── models/                # Data models
│   ├── providers/             # State management (Riverpod)
│   ├── services/              # Business logic services
│   └── widgets/               # Reusable UI components
├── test/                      # Unit and widget tests
├── integration_test/          # Integration tests
├── assets/                    # Images, fonts, etc.
├── prd/                       # PRD JSON files (this folder)
└── pubspec.yaml
```

---

## Technology Stack

### Required Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # Navigation
  go_router: ^12.0.0
  
  # Network
  dio: ^5.3.0
  retrofit: ^4.0.0
  
  # Local Storage
  drift: ^2.13.0          # SQLite database
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  
  # Camera & Media
  camera: ^0.10.5
  video_player: ^2.8.0
  audio_waveforms: ^1.0.4
  record: ^5.0.4
  image_picker: ^1.0.4
  
  # Location & Maps
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  flutter_map: ^6.0.1      # or google_maps_flutter
  latlong2: ^0.9.0
  
  # Sensors
  sensors_plus: ^4.0.2
  flutter_compass: ^0.8.0
  
  # Scanning
  mobile_scanner: ^3.5.2
  
  # Biometrics
  local_auth: ^2.1.6
  
  # Notifications
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.1.0
  
  # File Handling
  path_provider: ^2.1.1
  share_plus: ^7.2.1
  open_file: ^3.3.2
  
  # PDF
  pdf: ^3.10.4
  printing: ^5.11.1
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Utilities
  intl: ^0.18.1
  uuid: ^4.2.1
  connectivity_plus: ^5.0.1
  permission_handler: ^11.0.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.6
  riverpod_generator: ^2.3.0
  retrofit_generator: ^8.0.0
  drift_dev: ^2.13.0
  mockito: ^5.4.3
  integration_test:
    sdk: flutter
```

---

## Implementation Phases

### Phase 1: Foundation (Do First)
**Priority: CRITICAL**
**Estimated Test Cases: ~60**

These must be completed before any other features:

1. **Project Setup**
   - Initialize Flutter project
   - Configure pubspec.yaml with all dependencies
   - Set up folder structure as defined above
   - Configure Android and iOS permissions in native files
   - Set up flavor/environment configuration (dev, staging, prod)

2. **Core Infrastructure** (no PRD file - infrastructure)
   - API client with Dio (base URL, interceptors, error handling)
   - Local database setup with Drift (all tables/models)
   - Secure storage wrapper
   - Network connectivity monitoring
   - Permission handling service
   - Logger utility

3. **Authentication** (`prd-auth.json`)
   - Login screen and flow
   - Registration screen and flow
   - Biometric authentication
   - Token storage and refresh
   - Tenant selection
   - Offline PIN fallback
   - Session management

4. **Database Schema**
   Create Drift tables for:
   ```dart
   - users
   - tenants
   - projects
   - reports
   - entries
   - media
   - sync_queue
   - settings
   ```

### Phase 2: Core Navigation & Dashboard
**Priority: HIGH**
**Estimated Test Cases: ~45**

5. **App Shell & Navigation**
   - Bottom navigation bar
   - Navigation drawer
   - Go Router configuration
   - Deep link handling

6. **Dashboard** (`prd-dashboard.json`)
   - Statistics cards
   - Recent reports list
   - Quick capture FAB
   - Sync status indicator
   - Pull-to-refresh
   - Empty states

### Phase 3: Data Management
**Priority: HIGH**
**Estimated Test Cases: ~60**

7. **Projects** (`prd-projects.json`)
   - Project list screen
   - Project creation form
   - Project detail screen
   - Location picker for projects
   - Map view of projects
   - Team assignment (UI only, backend dependent)
   - Search and filter

8. **Reports** (`prd-reports.json`)
   - Reports list screen
   - Report creation flow
   - Report editor screen
   - Entry list within report
   - Report status management
   - Search, filter, sort
   - Report deletion

### Phase 4: Media Capture
**Priority: HIGH**
**Estimated Test Cases: ~65**

9. **Camera & Media Capture** (`prd-camera-media.json`)
   - Camera preview with overlays (GPS, timestamp, level)
   - Photo capture with EXIF metadata
   - Video recording with audio
   - Camera controls (flash, switch, zoom, focus)
   - Voice memo recording
   - QR/Barcode scanning
   - Local media storage

10. **Device Sensors** (`prd-device-sensors.json`)
    - Accelerometer integration
    - Gyroscope integration
    - Compass/magnetometer
    - Level indicator
    - Shake gesture detection
    - Sensor data capture with entries

11. **Location & Maps** (`prd-location-maps.json`)
    - GPS capture and tracking
    - Reverse geocoding
    - Map display with markers
    - Location picker
    - Route tracking
    - Offline map caching

### Phase 5: Entry Management
**Priority: MEDIUM-HIGH**
**Estimated Test Cases: ~30**

12. **Entry Detail & Media Viewer** (`prd-entry-detail.json`)
    - Entry detail screen (adaptive to type)
    - Photo viewer with zoom/pan
    - Video player with controls
    - Audio player with waveform
    - Metadata display
    - Entry editing
    - Swipe between entries

### Phase 6: Offline & Sync
**Priority: HIGH**
**Estimated Test Cases: ~30**

13. **Offline & Sync** (`prd-offline-sync.json`)
    - Connectivity detection
    - Local data caching
    - Upload queue management
    - Background upload service
    - Chunked upload for large files
    - Conflict resolution
    - Sync status screen
    - WiFi-only sync option

### Phase 7: AI Integration
**Priority: MEDIUM**
**Estimated Test Cases: ~35**

14. **AI Features** (`prd-ai-features.json`)
    - Image description generation (Claude Vision API)
    - Audio/video transcription (Whisper API or similar)
    - Report summary generation
    - AI processing queue
    - Editable AI content
    - Batch AI processing

### Phase 8: Output & Sharing
**Priority: MEDIUM**
**Estimated Test Cases: ~30**

15. **PDF Generation** (`prd-pdf-generation.json`)
    - PDF layout and design
    - Include all entry types
    - QR codes for video links
    - Map image generation
    - Branding/logo support
    - PDF preview and share

### Phase 9: Notifications & Settings
**Priority: MEDIUM**
**Estimated Test Cases: ~55**

16. **Push Notifications** (`prd-notifications.json`)
    - Firebase Cloud Messaging setup
    - Local notifications
    - Notification handling (foreground/background)
    - In-app notification center
    - Notification preferences

17. **Settings** (`prd-settings.json`)
    - Profile management
    - Security settings
    - Quality settings
    - Sync settings
    - Storage management
    - AI preferences
    - Camera preferences

### Phase 10: Polish & Platform-Specific
**Priority: MEDIUM-LOW**
**Estimated Test Cases: ~20**

18. **App Lifecycle** (`prd-app-lifecycle.json`)
    - State restoration
    - Background service management
    - Deep link handling
    - Share intent receiving
    - Crash recovery

---

## How to Use PRD Files

### File Structure
Each PRD JSON file contains an array of test cases:

```json
[
  {
    "category": "functional",      // Type of test
    "description": "What to test",  // Human-readable description
    "steps": [                      // Step-by-step acceptance criteria
      "Step 1",
      "Step 2",
      "..."
    ],
    "passes": false                 // Track completion status
  }
]
```

### Categories Explained
- `functional` - Core feature works correctly
- `ui` - Visual appearance and interactions
- `validation` - Input validation and error states
- `error-handling` - Graceful failure scenarios
- `offline` - Works without network
- `performance` - Speed and efficiency
- `accessibility` - Screen reader and a11y support
- `security` - Data protection
- `storage` - File system operations
- `battery` - Power efficiency
- `ios` / `android` - Platform-specific behavior

### Implementation Workflow

For each feature:

1. **Read the PRD file** for that domain
2. **Identify all test cases** to understand scope
3. **Group related test cases** that can share implementation
4. **Implement the feature** following test case steps as requirements
5. **Test against each step** in the test cases
6. **Mark `passes: true`** when all steps verified
7. **Commit with reference** to PRD file and test case count

### Example Implementation Flow

```
Working on: prd-camera-media.json

Test Case: "User can capture a photo"
Steps:
1. Open camera in photo mode ✓
2. Frame the subject ✓
3. Tap capture button ✓
4. Verify shutter animation plays ✓
5. Verify haptic feedback ✓
6. Verify captured photo preview appears ✓
7. Verify accept/retake options visible ✓

Implementation:
- Create CaptureScreen widget
- Implement CameraController
- Add capture button with animation
- Add HapticFeedback.mediumImpact()
- Create PhotoPreviewScreen
- Add accept/retake buttons

Mark as: passes: true
```

---

## Database Schema Reference

### Core Tables

```dart
// Users table
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get role => text()(); // admin, manager, field_worker
  TextColumn get tenantId => text().references(Tenants, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// Tenants table
class Tenants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get logoUrl => text().nullable()();
  TextColumn get settings => text()(); // JSON
  DateTimeColumn get createdAt => dateTime()();
}

// Projects table
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get status => text()(); // active, completed, archived
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncPending => boolean().withDefault(const Constant(false))();
}

// Reports table
class Reports extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get aiSummary => text().nullable()();
  TextColumn get status => text()(); // draft, processing, complete
  TextColumn get pdfUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncPending => boolean().withDefault(const Constant(false))();
}

// Entries table
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get reportId => text().references(Reports, #id)();
  TextColumn get type => text()(); // photo, video, audio, note, scan
  TextColumn get content => text().nullable()(); // note text or transcription
  TextColumn get aiDescription => text().nullable()();
  TextColumn get annotation => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get address => text().nullable()();
  RealColumn get compassHeading => real().nullable()();
  TextColumn get sensorData => text().nullable()(); // JSON
  IntColumn get sortOrder => integer()();
  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get syncPending => boolean().withDefault(const Constant(false))();
}

// Media table
class Media extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(Entries, #id)();
  TextColumn get type => text()(); // image, video, audio
  TextColumn get localPath => text()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  IntColumn get duration => integer().nullable()(); // seconds for video/audio
  TextColumn get mimeType => text()();
  TextColumn get processingStatus => text()(); // pending, uploading, complete, failed
  IntColumn get uploadProgress => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

// Sync Queue table
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // project, report, entry, media
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // create, update, delete
  TextColumn get payload => text()(); // JSON
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttempt => dateTime().nullable()();
}
```

---

## API Endpoints Reference

### Authentication
```
POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/refresh
POST   /api/auth/logout
GET    /api/auth/me
```

### Projects
```
GET    /api/projects
POST   /api/projects
GET    /api/projects/{id}
PUT    /api/projects/{id}
DELETE /api/projects/{id}
```

### Reports
```
GET    /api/reports
POST   /api/reports
GET    /api/reports/{id}
PUT    /api/reports/{id}
DELETE /api/reports/{id}
POST   /api/reports/{id}/generate-pdf
POST   /api/reports/{id}/generate-summary
```

### Entries
```
GET    /api/reports/{reportId}/entries
POST   /api/entries
GET    /api/entries/{id}
PUT    /api/entries/{id}
DELETE /api/entries/{id}
POST   /api/entries/{id}/transcribe
POST   /api/entries/{id}/describe
```

### Media
```
POST   /api/media/upload
GET    /api/media/{id}
GET    /api/media/{id}/stream
DELETE /api/media/{id}
```

### Sync
```
POST   /api/sync/push
GET    /api/sync/pull?since={timestamp}
```

---

## Key Implementation Notes

### State Management Pattern
Use Riverpod with code generation:

```dart
@riverpod
class ProjectsNotifier extends _$ProjectsNotifier {
  @override
  Future<List<Project>> build() async {
    return ref.read(projectRepositoryProvider).getAll();
  }
  
  Future<void> create(Project project) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(projectRepositoryProvider).create(project);
      return ref.read(projectRepositoryProvider).getAll();
    });
  }
}
```

### Offline-First Pattern
Always write to local DB first, then sync:

```dart
Future<void> createEntry(Entry entry) async {
  // 1. Save locally
  await localDatabase.entries.insert(entry.copyWith(syncPending: true));
  
  // 2. Queue for sync
  await syncQueue.add(SyncItem(
    entityType: 'entry',
    entityId: entry.id,
    action: 'create',
    payload: entry.toJson(),
  ));
  
  // 3. Trigger sync if online
  if (await connectivity.isOnline) {
    syncService.processQueue();
  }
}
```

### Error Handling Pattern
```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}
```

### Permission Handling
```dart
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.status;
  
  if (status.isGranted) return true;
  
  if (status.isDenied) {
    final result = await Permission.camera.request();
    return result.isGranted;
  }
  
  if (status.isPermanentlyDenied) {
    // Show dialog to open settings
    await openAppSettings();
    return false;
  }
  
  return false;
}
```

### UI Implementation Pattern

**Always reference `DESIGN_GUIDELINES.md` before creating UI components.**

Key principles:
1. **Use the theme system** - Never hardcode colors or fonts
2. **Follow spacing constants** - Use `AppSpacing` for all padding/margins
3. **Implement both themes** - All components must support light and dark mode
4. **Add haptic feedback** - Use `HapticFeedback.lightImpact()` for user actions
5. **Respect accessibility** - 48x48 minimum touch targets, semantic labels

```dart
// Example: Creating a themed component
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    padding: AppSpacing.cardInsets,
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: isDark ? null : Border.all(color: AppColors.slate200),
    ),
    child: Text(
      title,
      style: AppTypography.headline3.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
      ),
    ),
  );
}
```

Theme files to create (in order):
1. `lib/core/theme/app_colors.dart`
2. `lib/core/theme/app_typography.dart`
3. `lib/core/theme/app_spacing.dart`
4. `lib/core/theme/app_animations.dart`
5. `lib/core/theme/app_theme.dart`
6. `lib/core/theme/theme_provider.dart`

---

## Testing Strategy

### Unit Tests
- All repository methods
- All service methods
- State management logic
- Utility functions

### Widget Tests
- All screens render correctly
- User interactions work
- Error states display properly

### Integration Tests
- Complete user flows
- Offline scenarios
- Sync scenarios

### Test File Naming
```
test/
├── unit/
│   ├── repositories/
│   │   └── project_repository_test.dart
│   └── services/
│       └── sync_service_test.dart
├── widget/
│   ├── screens/
│   │   └── project_list_screen_test.dart
│   └── widgets/
│       └── capture_button_test.dart
└── integration/
    └── create_report_flow_test.dart
```

---

## Commit Message Format

```
feat(domain): Brief description

- Implements X test cases from prd-{domain}.json
- Test cases: "Description 1", "Description 2"
- Closes #issue (if applicable)

PRD Progress: X/Y tests passing
```

Example:
```
feat(camera): Implement photo capture with overlays

- Implements 8 test cases from prd-camera-media.json
- Test cases: "Camera opens and displays live preview", 
  "User can capture a photo", "Camera displays GPS coordinates overlay",
  "Camera displays timestamp overlay", "Camera shows level indicator"
- Adds CaptureScreen, CameraController, PhotoPreviewScreen

PRD Progress: 8/36 tests passing
```

---

## Progress Tracking

After implementing features, update the PRD JSON files:

```json
{
  "category": "functional",
  "description": "User can capture a photo",
  "steps": [...],
  "passes": true  // ← Update this
}
```

Generate progress report:
```bash
# Count passing tests per file
for f in prd/*.json; do
  total=$(jq length "$f")
  passing=$(jq '[.[] | select(.passes == true)] | length' "$f")
  echo "$f: $passing/$total"
done
```

---

## Quick Start Commands

```bash
# Create project
flutter create --org com.yourcompany field_reporter
cd field_reporter

# Add dependencies (copy from pubspec.yaml above)
flutter pub get

# Generate code (Riverpod, Retrofit, Drift)
dart run build_runner build --delete-conflicting-outputs

# Run on device
flutter run

# Run tests
flutter test

# Run integration tests
flutter test integration_test
```

---

## Final Checklist Before App Store Submission

- [ ] All PRD test cases pass
- [ ] App icons for all sizes (iOS and Android)
- [ ] Splash screens configured
- [ ] Privacy policy URL set
- [ ] Terms of service URL set
- [ ] App Store screenshots (6.5", 5.5" for iOS; phone, tablet for Android)
- [ ] App Store description and keywords
- [ ] ProGuard rules for Android release
- [ ] iOS certificates and provisioning profiles
- [ ] Version number and build number set
- [ ] Remove debug logging
- [ ] Test release builds on physical devices
- [ ] Accessibility audit complete
- [ ] Performance profiling done
- [ ] Memory leak check complete

---

## Support

When stuck on implementation:
1. Re-read the relevant PRD test case steps
2. Check if similar functionality exists in another domain
3. Review Flutter/package documentation
4. The test case steps ARE the requirements - follow them literally

Remember: Each PRD file is the source of truth for that domain. If a behavior isn't in the PRD, it's not required. If it IS in the PRD, it MUST be implemented exactly as described.
