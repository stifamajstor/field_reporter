# Field Reporter - Design Guidelines

## Design Philosophy: "Confident Clarity"

The app should feel like a trusted professional companion - every interaction confirms "you're doing this right." Inspired by the satisfaction of Tetris row completions, actions should feel **inevitable, precise, and rewarding**.

### Core Principles

1. **Precision over decoration** - Every element serves a purpose
2. **Calm confidence** - Subtle feedback, never shouty
3. **Professional reliability** - The app feels like a precision instrument
4. **Friction-free flow** - Get out of the user's way

### Aesthetic Direction: "Refined Utilitarian"

A blend of:
- **Swiss/International typography** - Clean, confident, hierarchical
- **Japanese minimalism** - Purposeful negative space, calm restraint
- **Professional instrument design** - Precision indicators, confident feedback

**NOT:** Generic Material Design, playful/bubbly UI, heavy gradients, busy dashboards

---

## Color System

### Primary Palette: "Warm Field Professional"

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  AppColors._();

  // ============================================
  // LIGHT MODE COLORS
  // ============================================

  // Core neutrals - inspired by professional field equipment
  static const slate900 = Color(0xFF0F172A);    // Primary text, headers
  static const slate700 = Color(0xFF334155);    // Secondary text
  static const slate500 = Color(0xFF64748B);    // Tertiary text
  static const slate400 = Color(0xFF94A3B8);    // Muted text, placeholders
  static const slate200 = Color(0xFFE2E8F0);    // Borders, dividers
  static const slate100 = Color(0xFFF1F5F9);    // Subtle backgrounds
  static const white = Color(0xFFFFFFFF);       // Cards, primary surfaces

  // Primary accent: Warm Orange - energetic yet controlled, action-oriented
  static const orange500 = Color(0xFFF97316);   // Primary actions, FAB
  static const orange600 = Color(0xFFEA580C);   // Pressed/hover states
  static const orange400 = Color(0xFFFB923C);   // Lighter accent
  static const orange50 = Color(0xFFFFF7ED);    // Subtle highlights
  static const orange100 = Color(0xFFFFEDD5);   // Active backgrounds

  // Semantic colors
  static const emerald500 = Color(0xFF10B981);  // Success, synced, complete
  static const emerald50 = Color(0xFFECFDF5);   // Success background
  static const amber500 = Color(0xFFF59E0B);    // Warning, pending
  static const amber50 = Color(0xFFFFFBEB);     // Warning background
  static const rose500 = Color(0xFFF43F5E);     // Error, failed
  static const rose50 = Color(0xFFFFF1F2);      // Error background

  // ============================================
  // DARK MODE COLORS
  // ============================================

  // Dark surfaces - true black OLED-friendly base
  static const darkBackground = Color(0xFF0A0A0A);  // App background
  static const darkSurface = Color(0xFF141414);     // Cards, elevated surfaces
  static const darkSurfaceHigh = Color(0xFF1F1F1F); // Dialogs, modals
  static const darkSurfaceHigher = Color(0xFF262626); // Tooltips, popovers
  static const darkBorder = Color(0xFF2D2D2D);      // Subtle borders

  // Dark text
  static const darkTextPrimary = Color(0xFFF8FAFC);   // Primary text
  static const darkTextSecondary = Color(0xFF94A3B8); // Secondary text
  static const darkTextMuted = Color(0xFF64748B);     // Muted/disabled

  // Orange accent adapts for dark mode (slightly brighter for contrast)
  static const darkOrange = Color(0xFFFB923C);        // Primary actions in dark
  static const darkOrangePressed = Color(0xFFF97316); // Pressed state
  static const darkOrangeSubtle = Color(0xFF2D1F0F);  // Subtle orange backgrounds

  // Dark semantic colors (slightly desaturated for eye comfort)
  static const darkEmerald = Color(0xFF34D399);       // Success in dark
  static const darkEmeraldSubtle = Color(0xFF0D2818); // Success background
  static const darkAmber = Color(0xFFFBBF24);         // Warning in dark
  static const darkAmberSubtle = Color(0xFF2D2006);   // Warning background
  static const darkRose = Color(0xFFFB7185);          // Error in dark
  static const darkRoseSubtle = Color(0xFF2D0D12);    // Error background
}
```

### Color Usage Guidelines

| Context | Light Mode | Dark Mode |
|---------|------------|-----------|
| Background | `white` | `darkBackground` |
| Cards/Surfaces | `white` | `darkSurface` |
| Primary Text | `slate900` | `darkTextPrimary` |
| Secondary Text | `slate700` | `darkTextSecondary` |
| Muted Text | `slate400` | `darkTextMuted` |
| Primary Button | `orange500` | `darkOrange` |
| Button Pressed | `orange600` | `darkOrangePressed` |
| Borders | `slate200` | `darkBorder` |
| Dividers | `slate100` | `darkBorder` |

---

## Typography System

### Font Families

```dart
// lib/core/theme/app_typography.dart

// Primary: DM Sans - Modern geometric sans-serif with excellent legibility
// Monospace: JetBrains Mono - Technical precision for metadata

// Add to pubspec.yaml:
// fonts:
//   - family: DM Sans
//     fonts:
//       - asset: assets/fonts/DMSans-Regular.ttf
//       - asset: assets/fonts/DMSans-Medium.ttf
//         weight: 500
//       - asset: assets/fonts/DMSans-SemiBold.ttf
//         weight: 600
//       - asset: assets/fonts/DMSans-Bold.ttf
//         weight: 700
//   - family: JetBrains Mono
//     fonts:
//       - asset: assets/fonts/JetBrainsMono-Regular.ttf
```

### Type Scale

```dart
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'DM Sans';
  static const String monoFamily = 'JetBrains Mono';

  // Display - Large screen titles
  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,      // 40px line height
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  // Headline 1 - Screen titles
  static const headline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.29,      // 36px line height
    fontWeight: FontWeight.w500,
    letterSpacing: -0.25,
  );

  // Headline 2 - Section headers
  static const headline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.33,      // 32px line height
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // Headline 3 - Card titles
  static const headline3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.4,       // 28px line height
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // Body Large - Emphasized body text
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.56,      // 28px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Body 1 - Primary content
  static const body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,       // 24px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Body 2 - Secondary content
  static const body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.43,      // 20px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Caption - Labels, hints
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.33,      // 16px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  // Overline - Small labels, tags
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.45,      // 16px line height
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // Monospace - Coordinates, timestamps, metadata
  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.33,      // 16px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Monospace Large - Prominent technical data
  static const monoLarge = TextStyle(
    fontFamily: monoFamily,
    fontSize: 14,
    height: 1.43,      // 20px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // Button text
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}
```

### Typography Usage

| Context | Style | Example |
|---------|-------|---------|
| App bar titles | `headline1` | "Reports" |
| Section headers | `headline2` | "Recent Activity" |
| Card titles | `headline3` | "Construction Site A" |
| Body text | `body1` | Description paragraphs |
| List items | `body2` | Secondary info in lists |
| Labels, hints | `caption` | Form labels, timestamps |
| Tags, badges | `overline` | "PENDING", "DRAFT" |
| GPS coordinates | `mono` | "40.7128°, -74.0060°" |
| Timestamps | `mono` | "2:34:56 PM" |
| Button labels | `button` | "Capture Photo" |

---

## Spacing & Layout System

### 8px Grid System

```dart
// lib/core/theme/app_spacing.dart

class AppSpacing {
  AppSpacing._();

  // Base unit
  static const double unit = 8.0;

  // Spacing scale
  static const double xxs = 2.0;   // 0.25 units
  static const double xs = 4.0;    // 0.5 units
  static const double sm = 8.0;    // 1 unit
  static const double md = 16.0;   // 2 units
  static const double lg = 24.0;   // 3 units
  static const double xl = 32.0;   // 4 units
  static const double xxl = 48.0;  // 6 units
  static const double xxxl = 64.0; // 8 units

  // Screen margins
  static const double screenHorizontal = 20.0;
  static const double screenVertical = 24.0;

  // Content max width (tablets)
  static const double maxContentWidth = 600.0;

  // Card internal padding
  static const double cardPadding = 16.0;

  // List item spacing
  static const double listItemSpacing = 12.0;

  // Section spacing
  static const double sectionSpacing = 32.0;

  // EdgeInsets helpers
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);

  static const EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );
}
```

### Layout Guidelines

1. **Screen margins**: 20px horizontal on mobile
2. **Content max-width**: 600px on tablets (center content)
3. **Safe areas**: Always respect device notches/home indicators
4. **Card spacing**: 12px between cards in lists
5. **Section spacing**: 32px between major sections

### Card Design

```dart
// Standard card properties
borderRadius: BorderRadius.circular(12);
elevation: 0;  // Use subtle border instead in light mode
border: Border.all(color: AppColors.slate200, width: 1);  // Light mode
// In dark mode: use elevation with darkSurface color

// Card internal structure
Padding: 16px all around
Title: headline3
Subtitle: body2 with slate700
Metadata: caption or mono with slate400
```

---

## Component Design Patterns

### 1. Buttons

#### Primary Button (Orange)
```dart
// Filled, rounded rectangle, used for primary actions
Container(
  height: 52,
  decoration: BoxDecoration(
    color: AppColors.orange500,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.camera_alt, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text('Capture Photo', style: AppTypography.button.copyWith(color: Colors.white)),
      ],
    ),
  ),
)

// States:
// Default: orange500 background
// Pressed: orange600 background, scale to 0.98
// Disabled: orange500 at 50% opacity
```

#### Secondary Button (Outlined)
```dart
Container(
  height: 52,
  decoration: BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.slate200, width: 1.5),
  ),
  // Text color: slate700
)
```

#### Text Button
```dart
// No background, just text
// Color: orange500
// Pressed: orange600, slight background tint
```

#### Icon Button
```dart
// 48x48 touch target minimum
// Icon size: 24
// Use IconButton with splash disabled, custom ink well
```

### 2. Entry Cards

```
┌────────────────────────────────────────┐
│ ┌──────────┐                           │
│ │          │  Construction Site A      │  ← headline3
│ │ [thumb]  │  ────────────────────     │
│ │  80x80   │  📍 123 Main St           │  ← caption, slate400
│ └──────────┘  🕐 2:34 PM               │  ← mono, slate400
│                                        │
│  "Visible crack in foundation..."      │  ← body2, slate700, max 2 lines
└────────────────────────────────────────┘

Specs:
- Thumbnail: 80x80, borderRadius: 8
- Card padding: 16
- Gap between thumbnail and text: 12
- Vertical spacing between lines: 4
```

### 3. Status Indicators

```dart
// Sync status bar (subtle, at top of screen or in app bar)
Row(
  children: [
    // Status icon
    Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: statusColor,  // emerald/amber/orange/rose
        shape: BoxShape.circle,
      ),
    ),
    SizedBox(width: 8),
    // Status text
    Text('Synced at 2:34 PM', style: AppTypography.caption),
  ],
)

// Status colors:
// Synced/Complete: emerald500
// Pending: amber500
// Uploading/Active: orange500
// Error/Failed: rose500
```

### 4. Input Fields

```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter project name',
    hintStyle: AppTypography.body1.copyWith(color: AppColors.slate400),
    filled: true,
    fillColor: AppColors.slate100,  // Light mode
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.orange500, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
)
```

### 5. Bottom Navigation

```dart
// 5 tabs with center elevated FAB
BottomNavigationBar:
  - Height: 64 (plus safe area)
  - Background: white / darkSurface
  - Active: orange500 icon (filled) + label
  - Inactive: slate400 icon (outlined) + label

// Center capture button (elevated)
FloatingActionButton(
  backgroundColor: AppColors.orange500,
  elevation: 4,
  child: Icon(Icons.add, size: 28),
)
```

### 6. Camera Overlay

```dart
// Always uses dark theme regardless of app theme
// Minimal, semi-transparent overlays

// Top bar (GPS + flash)
Container(
  color: Colors.black.withOpacity(0.5),
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: Row(
    children: [
      Icon(Icons.flash_auto, color: Colors.white, size: 20),
      Spacer(),
      Text('40.7128°, -74.0060°', style: AppTypography.mono.copyWith(color: Colors.white)),
    ],
  ),
)

// Bottom controls
// Large capture button: 72x72, white ring, center fill
// Secondary buttons: 48x48, semi-transparent background
```

### 7. Empty States

```
        ┌───────────────────────────┐
        │                           │
        │      📋  →  📷            │   ← Simple line icons, slate400
        │                           │
        └───────────────────────────┘

        No reports yet                   ← headline3, slate900

        Start by capturing your first    ← body2, slate500, centered
        photo, video, or note.

        ┌───────────────────────────┐
        │     + Create Report       │    ← Primary button
        └───────────────────────────┘

Spacing:
- Icon to title: 24px
- Title to description: 8px
- Description to button: 32px
```

---

## Micro-interactions & Feedback

### Animation Curves & Timing

```dart
// lib/core/theme/app_animations.dart

class AppAnimations {
  AppAnimations._();

  // Curves
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  // Durations
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration emphasis = Duration(milliseconds: 500);

  // Common animations
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration buttonRelease = Duration(milliseconds: 150);
  static const Duration cardEnter = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration fadeIn = Duration(milliseconds: 200);
}
```

### "Tetris Completion" Moments

The satisfaction comes from *precision and inevitability*, not celebration.

#### Photo Captured
```dart
// 1. Brief white flash (30ms, 15% opacity)
// 2. Thumbnail fades in smoothly (200ms)
// 3. Light haptic tap
// 4. No toast - the thumbnail IS the confirmation

onCapture: () async {
  // Flash overlay
  showFlashOverlay(duration: Duration(milliseconds: 30), opacity: 0.15);

  // Haptic
  HapticFeedback.lightImpact();

  // Animate thumbnail in
  thumbnailController.forward();
}
```

#### Entry Added to Report
```dart
// 1. Card slides in from right (150ms, easeOut)
// 2. Entry count increments with subtle scale pulse (1.0 → 1.05 → 1.0)
// 3. No bounce - smooth and inevitable

SlideTransition(
  position: Tween<Offset>(
    begin: Offset(1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: controller,
    curve: AppAnimations.easeOut,
  )),
  child: entryCard,
)
```

#### Report Complete
```dart
// 1. Status chip color change (slate → emerald, 200ms fade)
// 2. Checkmark icon fades in
// 3. Single light haptic
// 4. "Generate PDF" becomes primary color

AnimatedContainer(
  duration: AppAnimations.standard,
  curve: AppAnimations.easeOut,
  decoration: BoxDecoration(
    color: isComplete ? AppColors.emerald50 : AppColors.slate100,
    // ...
  ),
)
```

#### Sync Complete
```dart
// 1. Sync icon stops spinning, crossfades to checkmark (150ms)
// 2. Badge count fades out (200ms)
// 3. Light haptic only if user was waiting

AnimatedSwitcher(
  duration: AppAnimations.quick,
  child: isSynced
    ? Icon(Icons.check, key: ValueKey('check'))
    : SpinningIcon(Icons.sync, key: ValueKey('sync')),
)
```

### Button Press Animation

```dart
// Scale down to 0.98 on press, return on release
GestureDetector(
  onTapDown: (_) => controller.forward(),
  onTapUp: (_) => controller.reverse(),
  onTapCancel: () => controller.reverse(),
  child: ScaleTransition(
    scale: Tween<double>(begin: 1.0, end: 0.98).animate(controller),
    child: button,
  ),
)
```

### Loading States

```dart
// Skeleton loaders - match content shape exactly
Shimmer.fromColors(
  baseColor: AppColors.slate100,
  highlightColor: AppColors.white,
  child: Container(
    // Match exact dimensions of content being loaded
  ),
)

// Progress indicators
// Linear: for uploads, determinate progress
LinearProgressIndicator(
  value: progress,
  backgroundColor: AppColors.slate100,
  valueColor: AlwaysStoppedAnimation(AppColors.orange500),
)

// Circular: for processing, indeterminate
SizedBox(
  width: 20,
  height: 20,
  child: CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation(AppColors.orange500),
  ),
)
```

### Haptic Feedback Guidelines

| Action | Haptic Type (iOS) | Android Equivalent |
|--------|-------------------|-------------------|
| Button tap | `.light` | `HapticFeedback.lightImpact` |
| Capture photo | `.light` | `HapticFeedback.lightImpact` |
| Toggle switch | `.light` | `HapticFeedback.lightImpact` |
| Error | `.notificationError` | `HapticFeedback.vibrate` |
| Success (completion) | `.light` | `HapticFeedback.lightImpact` |
| Delete swipe | `.medium` | `HapticFeedback.mediumImpact` |

**Rule:** Haptics are felt, not noticed. Always subtle.

---

## Dark Mode Strategy

### Implementation

```dart
// lib/core/theme/theme_provider.dart

@riverpod
class AppThemeMode extends _$AppThemeMode {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    // Load from SharedPreferences, default to system
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
  }
}

// Usage in MaterialApp
MaterialApp(
  themeMode: ref.watch(appThemeModeProvider),
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
)
```

### Design Principles for Dark Mode

1. **True black backgrounds** - OLED-friendly (`#0A0A0A`), battery-saving
2. **Reduced contrast** - Less eye strain in dark environments
3. **Warmer orange accent** - Slightly brighter (`#FB923C`) for visibility
4. **Desaturated semantics** - Success/warning/error colors toned down 10%
5. **Elevation via brightness** - Higher surfaces = slightly lighter

### Color Mapping

| Element | Light Mode | Dark Mode |
|---------|------------|-----------|
| Background | `white` | `darkBackground` (#0A0A0A) |
| Card surface | `white` | `darkSurface` (#141414) |
| Modal/Dialog | `white` | `darkSurfaceHigh` (#1F1F1F) |
| Primary text | `slate900` | `darkTextPrimary` (#F8FAFC) |
| Secondary text | `slate700` | `darkTextSecondary` (#94A3B8) |
| Borders | `slate200` | `darkBorder` (#2D2D2D) |
| Primary action | `orange500` | `darkOrange` (#FB923C) |
| Success | `emerald500` | `darkEmerald` (#34D399) |
| Warning | `amber500` | `darkAmber` (#FBBF24) |
| Error | `rose500` | `darkRose` (#FB7185) |

### Theme Switching

```dart
// Smooth crossfade (300ms) when toggling
AnimatedTheme(
  data: theme,
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  child: child,
)
```

**Notes:**
- Camera overlay always uses dark theme (regardless of app theme)
- Images/thumbnails display with natural colors
- No jarring flash between themes

---

## Accessibility

### Touch Targets

```dart
// Minimum 48x48 touch target for all interactive elements
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: Icon(Icons.close),
    onPressed: onClose,
  ),
)
```

### Color Contrast

| Requirement | Light Mode | Dark Mode |
|-------------|------------|-----------|
| Primary text | `slate900` on `white` = 15.5:1 ✓ | `darkTextPrimary` on `darkBackground` = 17.9:1 ✓ |
| Secondary text | `slate700` on `white` = 7.4:1 ✓ | `darkTextSecondary` on `darkSurface` = 6.2:1 ✓ |
| Orange on white | `orange500` on `white` = 3.0:1 ⚠️ | Use for graphics only |
| Button text | White on `orange500` = 3.3:1 ✓ (large text) | White on `darkOrange` = 2.7:1 ✓ (large text) |

**Note:** Orange accent passes for large text (18px+ or 14px+ bold) but should not be used for body text.

### Focus Indicators

```dart
// Visible 2px orange outline for keyboard/screen reader focus
Focus(
  child: Container(
    decoration: BoxDecoration(
      border: isFocused
        ? Border.all(color: AppColors.orange500, width: 2)
        : null,
    ),
  ),
)
```

### Screen Reader Support

```dart
// All interactive elements must have semantic labels
Semantics(
  label: 'Capture photo',
  button: true,
  child: captureButton,
)

// Images must have descriptions
Image.file(
  file,
  semanticLabel: 'Photo of construction site showing foundation crack',
)
```

### Reduced Motion

```dart
// Respect system setting
final reduceMotion = MediaQuery.of(context).disableAnimations;

AnimatedContainer(
  duration: reduceMotion ? Duration.zero : AppAnimations.standard,
  // ...
)
```

### Dynamic Text Scaling

```dart
// Support system font scaling up to 200%
// Use textScaler instead of fixed font sizes where appropriate
Text(
  'Report Title',
  style: AppTypography.headline3,
  // Automatically scales with system settings
)

// For critical layouts, set maximum scale
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(
      MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.5),
    ),
  ),
  child: criticalLayoutWidget,
)
```

---

## Navigation Structure

### Bottom Navigation

```
┌─────┬─────┬─────┬─────┬─────┐
│  🏠 │  📁 │  ⊕  │  📋 │  ⚙  │
│Home │Proj │     │Rpts │Set  │
└─────┴─────┴─────┴─────┴─────┘
              ↑
         Quick Capture
         (elevated FAB style)
```

- **Home**: Dashboard with stats, recent activity
- **Projects**: Project list and management
- **Capture** (center): Elevated FAB, opens capture menu
- **Reports**: Report list and management
- **Settings**: Profile, preferences, sync status

### Quick Capture Menu

```dart
// Expands upward with staggered animation
// Each option slides in 50ms apart
// Tap outside or capture button to close

Column(
  children: [
    CaptureOption(icon: Icons.camera_alt, label: 'Photo', delay: 0),
    CaptureOption(icon: Icons.videocam, label: 'Video', delay: 50),
    CaptureOption(icon: Icons.mic, label: 'Audio', delay: 100),
    CaptureOption(icon: Icons.edit_note, label: 'Note', delay: 150),
  ],
)
```

### Page Transitions

```dart
// Standard slide transition for navigation
CustomTransitionPage(
  child: page,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.easeOut,
      )),
      child: child,
    );
  },
)
```

---

## Screen-by-Screen Design Notes

### Dashboard

- **Greeting**: "Good morning, [Name]" (time-based)
- **Stats**: Simple number cards (not charts) - Reports this week, Pending sync, Storage used
- **Recent**: Compact list of 3-5 recent reports
- **Sync status**: Always visible in app bar or subtitle
- **Empty state**: Encourages first capture with friendly message

### Camera

- **Viewfinder**: Full-screen, edge-to-edge
- **Overlays**: Minimal - GPS, timestamp, level indicator only
- **Controls**: Bottom-aligned, large touch targets (minimum 48x48)
- **Preview**: After capture shows accept/retake buttons
- **Mode indicator**: Current mode (photo/video) visible but unobtrusive

### Report Editor

- **Timeline view**: Entries displayed chronologically
- **Drag handles**: Visible on left side for reorder
- **Swipe to delete**: Red background revealed on swipe
- **AI summary**: Collapsible section at top
- **Generate PDF**: Floating button, becomes primary when report complete

### Settings

- **Grouped sections**: Headers separate related settings
- **Toggles**: Standard switch for on/off settings
- **Navigation items**: Chevron indicates drill-down
- **Profile**: Photo and name at top
- **Danger zone**: Delete account, clear cache at bottom with rose accent

---

## File Structure

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart        # Color palette (light + dark)
│       ├── app_typography.dart    # Text styles
│       ├── app_spacing.dart       # Spacing constants
│       ├── app_theme.dart         # ThemeData (light + dark)
│       ├── app_animations.dart    # Curves & durations
│       └── theme_provider.dart    # Theme state (Riverpod)
└── widgets/
    ├── buttons/
    │   ├── primary_button.dart
    │   ├── secondary_button.dart
    │   └── icon_button.dart
    ├── cards/
    │   ├── entry_card.dart
    │   ├── project_card.dart
    │   ├── report_card.dart
    │   └── stat_card.dart
    ├── inputs/
    │   ├── app_text_field.dart
    │   └── search_field.dart
    ├── indicators/
    │   ├── sync_status.dart
    │   ├── progress_indicator.dart
    │   └── status_badge.dart
    ├── feedback/
    │   ├── toast.dart
    │   └── skeleton_loader.dart
    └── layout/
        ├── screen_container.dart
        └── empty_state.dart
```

---

## Do's and Don'ts

### Do's ✓

- **Do** use the 8px grid for all spacing
- **Do** use semantic colors consistently (emerald=success, amber=warning, rose=error)
- **Do** provide haptic feedback for user actions
- **Do** use monospace font for coordinates, timestamps, and technical data
- **Do** respect safe areas and notches
- **Do** test both light and dark modes
- **Do** provide loading skeletons that match content shapes
- **Do** use the orange accent sparingly for primary actions only
- **Do** maintain 48x48 minimum touch targets

### Don'ts ✗

- **Don't** use more than 2-3 colors per screen (excluding semantic)
- **Don't** add decorative elements that don't serve a purpose
- **Don't** use heavy shadows or gradients
- **Don't** use bouncy/springy animations (too playful)
- **Don't** show toast notifications for every action (thumbnails confirm captures)
- **Don't** use pure black (#000000) in light mode or pure white (#FFFFFF) in dark mode for text
- **Don't** use orange for error states (use rose)
- **Don't** nest cards within cards
- **Don't** use small text for interactive elements

---

## Code Examples

### Creating a Primary Button

```dart
class PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.buttonPress,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkOrange : AppColors.orange500;
    final pressedColor = isDark ? AppColors.darkOrangePressed : AppColors.orange600;

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null ? (_) {
        _controller.reverse();
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
      } : null,
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppAnimations.quick,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: widget.onPressed != null
                ? backgroundColor
                : backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
```

### Creating a Status Badge

```dart
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;

  const StatusBadge({
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (backgroundColor, textColor) = switch (type) {
      StatusType.success => (
        isDark ? AppColors.darkEmeraldSubtle : AppColors.emerald50,
        isDark ? AppColors.darkEmerald : AppColors.emerald500,
      ),
      StatusType.warning => (
        isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
        isDark ? AppColors.darkAmber : AppColors.amber500,
      ),
      StatusType.error => (
        isDark ? AppColors.darkRoseSubtle : AppColors.rose50,
        isDark ? AppColors.darkRose : AppColors.rose500,
      ),
      StatusType.neutral => (
        isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
        isDark ? AppColors.darkTextSecondary : AppColors.slate700,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.overline.copyWith(color: textColor),
      ),
    );
  }
}

enum StatusType { success, warning, error, neutral }
```

### Creating an Entry Card

```dart
class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback? onTap;

  const EntryCard({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: isDark
              ? null
              : Border.all(color: AppColors.slate200, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: entry.thumbnailPath != null
                    ? Image.file(File(entry.thumbnailPath!), fit: BoxFit.cover)
                    : Container(
                        color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                        child: Icon(
                          _iconForType(entry.type),
                          color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title ?? 'Untitled Entry',
                    style: AppTypography.headline3.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (entry.address != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.address!,
                            style: AppTypography.caption.copyWith(
                              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(entry.capturedAt),
                    style: AppTypography.mono.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                  if (entry.content != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.content!,
                      style: AppTypography.body2.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(EntryType type) => switch (type) {
    EntryType.photo => Icons.camera_alt_outlined,
    EntryType.video => Icons.videocam_outlined,
    EntryType.audio => Icons.mic_outlined,
    EntryType.note => Icons.edit_note_outlined,
    EntryType.scan => Icons.qr_code_scanner_outlined,
  };
}
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-28 | Initial design system |

---

*This document is the source of truth for all UI development in Field Reporter. All screens, components, and interactions should follow these guidelines to ensure a consistent, professional user experience.*
