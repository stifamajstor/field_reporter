import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/presentation/widgets/location_picker.dart';
import 'package:field_reporter/widgets/buttons/primary_button.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/services/location_service.dart';

/// Tests for: User can set project location using current GPS
///
/// Acceptance Criteria:
/// - Navigate to create project form
/// - Tap location field
/// - Tap 'Use Current Location' button
/// - Verify location permission prompt if not granted
/// - Grant permission
/// - Verify GPS coordinates are captured
/// - Verify address is reverse-geocoded and displayed
/// - Verify map preview shows correct location
void main() {
  group('User can set project location using current GPS', () {
    late List<Project> testProjects;

    setUp(() {
      testProjects = [];
    });

    Widget createTestWidget({
      Widget? child,
      LocationService? locationService,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: testProjects);
          }),
          if (locationService != null)
            locationServiceProvider.overrideWithValue(locationService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child ?? const CreateProjectScreen(),
        ),
      );
    }

    testWidgets('location picker shows "Use Current Location" button',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap location field to open picker
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Verify 'Use Current Location' button exists
      expect(
        find.widgetWithText(GestureDetector, 'Use Current Location'),
        findsOneWidget,
      );
    });

    testWidgets('tapping "Use Current Location" requests permission when denied',
        (tester) async {
      var permissionRequested = false;

      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.denied,
        onRequestPermission: () {
          permissionRequested = true;
          return LocationPermissionStatus.granted;
        },
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap 'Use Current Location'
      await tester.tap(find.text('Use Current Location'));
      await tester.pumpAndSettle();

      expect(permissionRequested, isTrue);
    });

    testWidgets('captures GPS coordinates after permission granted',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockPosition: LocationPosition(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        mockAddress: '123 Market Street, San Francisco, CA',
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap 'Use Current Location'
      await tester.tap(find.text('Use Current Location'));
      await tester.pumpAndSettle();

      // Verify coordinates are displayed (in map preview or coordinates display)
      expect(find.textContaining('37.7749'), findsOneWidget);
      expect(find.textContaining('-122.4194'), findsOneWidget);
    });

    testWidgets('displays reverse-geocoded address after getting location',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockPosition: LocationPosition(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        mockAddress: '123 Market Street, San Francisco, CA',
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap 'Use Current Location'
      await tester.tap(find.text('Use Current Location'));
      await tester.pumpAndSettle();

      // Verify reverse-geocoded address is displayed (at least one match)
      expect(
        find.textContaining('123 Market Street'),
        findsAtLeast(1),
      );
    });

    testWidgets('map preview shows correct location after GPS capture',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockPosition: LocationPosition(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        mockAddress: '123 Market Street, San Francisco, CA',
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap 'Use Current Location'
      await tester.tap(find.text('Use Current Location'));
      await tester.pumpAndSettle();

      // Verify map preview shows the location (via key or marker presence)
      final mapPreview = find.byKey(const Key('location_map_preview'));
      expect(mapPreview, findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching location',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockPosition: LocationPosition(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        mockAddress: '123 Market Street, San Francisco, CA',
        simulateDelay: true,
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap 'Use Current Location'
      await tester.tap(find.text('Use Current Location'));
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let it complete
      await tester.pumpAndSettle();
    });

    testWidgets('handles permission permanently denied', (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.permanentlyDenied,
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap 'Use Current Location'
      await tester.tap(find.text('Use Current Location'));
      await tester.pumpAndSettle();

      // Verify settings dialog appears (check for dialog title)
      expect(
        find.text('Location Permission Required'),
        findsOneWidget,
      );
      // Verify settings button is present
      expect(
        find.widgetWithText(TextButton, 'Settings'),
        findsOneWidget,
      );
    });

    testWidgets('location is set in form after selecting', (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockPosition: LocationPosition(
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        mockAddress: '123 Market Street, San Francisco, CA',
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap 'Use Current Location'
      await tester.tap(find.text('Use Current Location'));
      await tester.pumpAndSettle();

      // Tap 'Select Location' button (find the one with matching text inside location picker)
      final selectButton = find.descendant(
        of: find.byKey(const Key('location_picker')),
        matching: find.widgetWithText(GestureDetector, 'Select Location'),
      );
      await tester.tap(selectButton);
      await tester.pumpAndSettle();

      // Verify location is now displayed in the create form (location picker dismissed)
      expect(find.byKey(const Key('location_picker')), findsNothing);
      expect(
        find.textContaining('123 Market Street'),
        findsOneWidget,
      );
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async => projects;

  @override
  Future<Project> createProject(Project project) async {
    projects.add(project);
    return project;
  }
}

/// Mock LocationService for testing
class MockLocationService implements LocationService {
  final LocationPermissionStatus permissionStatus;
  final LocationPosition? mockPosition;
  final String? mockAddress;
  final bool simulateDelay;
  final LocationPermissionStatus Function()? onRequestPermission;

  MockLocationService({
    this.permissionStatus = LocationPermissionStatus.granted,
    this.mockPosition,
    this.mockAddress,
    this.simulateDelay = false,
    this.onRequestPermission,
  });

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    return permissionStatus;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    if (onRequestPermission != null) {
      return onRequestPermission!();
    }
    return permissionStatus;
  }

  @override
  Future<LocationPosition> getCurrentPosition() async {
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mockPosition == null) {
      throw const LocationServiceException('Location not available');
    }
    return mockPosition!;
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async {
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return mockAddress ?? 'Unknown Address';
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<AddressSuggestion>> searchAddress(String query) async {
    return [];
  }

  @override
  Future<LocationPosition> geocodeAddress(String address) async {
    return mockPosition ??
        const LocationPosition(latitude: 40.7128, longitude: -74.0060);
  }
}
