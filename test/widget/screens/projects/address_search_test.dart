import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/services/location_service.dart';

/// Tests for: User can set project location by searching address
///
/// Acceptance Criteria:
/// - Navigate to create project form
/// - Tap location field
/// - Tap search/address input
/// - Type address or place name
/// - Verify autocomplete suggestions appear
/// - Select a suggestion
/// - Verify map updates to show selected location
/// - Verify coordinates are populated
void main() {
  group('User can set project location by searching address', () {
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

    testWidgets('can navigate to create project form and tap location field',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify we are on create project form
      expect(find.text('Create Project'), findsOneWidget);

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Verify location picker is shown
      expect(find.byKey(const Key('location_picker')), findsOneWidget);
    });

    testWidgets('address search field accepts input', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap search/address input
      final searchField = find.byKey(const Key('address_search_field'));
      expect(searchField, findsOneWidget);

      // Type address
      await tester.enterText(searchField, 'Times Square');
      await tester.pump();

      // Verify text was entered (may appear in text field and elsewhere)
      expect(find.text('Times Square'), findsAtLeast(1));
    });

    testWidgets('autocomplete suggestions appear when typing address',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockSuggestions: [
          AddressSuggestion(
            address: 'Times Square, New York, NY',
            latitude: 40.7580,
            longitude: -73.9855,
          ),
          AddressSuggestion(
            address: 'Times Square, Manhattan, NY',
            latitude: 40.7579,
            longitude: -73.9860,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Type address
      final searchField = find.byKey(const Key('address_search_field'));
      await tester.enterText(searchField, 'Times Square');
      await tester.pumpAndSettle();

      // Verify autocomplete suggestions appear
      expect(find.byKey(const Key('autocomplete_suggestions')), findsOneWidget);
      expect(find.text('Times Square, New York, NY'), findsOneWidget);
      expect(find.text('Times Square, Manhattan, NY'), findsOneWidget);
    });

    testWidgets('selecting suggestion updates map and coordinates',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockSuggestions: [
          AddressSuggestion(
            address: 'Times Square, New York, NY',
            latitude: 40.7580,
            longitude: -73.9855,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Type address
      final searchField = find.byKey(const Key('address_search_field'));
      await tester.enterText(searchField, 'Times Square');
      await tester.pumpAndSettle();

      // Select a suggestion
      await tester.tap(find.text('Times Square, New York, NY'));
      await tester.pumpAndSettle();

      // Verify map updates to show selected location (map preview displays address)
      expect(find.text('Times Square, New York, NY'), findsAtLeast(1));

      // Verify coordinates are populated
      expect(find.textContaining('40.7580'), findsOneWidget);
      expect(find.textContaining('-73.9855'), findsOneWidget);
    });

    testWidgets('selecting suggestion dismisses autocomplete list',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockSuggestions: [
          AddressSuggestion(
            address: 'Times Square, New York, NY',
            latitude: 40.7580,
            longitude: -73.9855,
          ),
          AddressSuggestion(
            address: 'Times Square, Manhattan, NY',
            latitude: 40.7579,
            longitude: -73.9860,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Type address
      final searchField = find.byKey(const Key('address_search_field'));
      await tester.enterText(searchField, 'Times Square');
      await tester.pumpAndSettle();

      // Verify suggestions appear
      expect(find.byKey(const Key('autocomplete_suggestions')), findsOneWidget);

      // Select a suggestion
      await tester.tap(find.text('Times Square, New York, NY'));
      await tester.pumpAndSettle();

      // Verify suggestions list is dismissed
      expect(find.byKey(const Key('autocomplete_suggestions')), findsNothing);
    });

    testWidgets('empty search query hides autocomplete suggestions',
        (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockSuggestions: [
          AddressSuggestion(
            address: 'Times Square, New York, NY',
            latitude: 40.7580,
            longitude: -73.9855,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Type address
      final searchField = find.byKey(const Key('address_search_field'));
      await tester.enterText(searchField, 'Times Square');
      await tester.pumpAndSettle();

      // Verify suggestions appear
      expect(find.byKey(const Key('autocomplete_suggestions')), findsOneWidget);

      // Clear input
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Verify suggestions are hidden
      expect(find.byKey(const Key('autocomplete_suggestions')), findsNothing);
    });

    testWidgets('shows loading indicator while searching', (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockSuggestions: [
          AddressSuggestion(
            address: 'Times Square, New York, NY',
            latitude: 40.7580,
            longitude: -73.9855,
          ),
        ],
        simulateSearchDelay: true,
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Type address
      final searchField = find.byKey(const Key('address_search_field'));
      await tester.enterText(searchField, 'Times Square');
      await tester.pump(const Duration(milliseconds: 400)); // After debounce

      // Verify loading indicator appears
      expect(find.byKey(const Key('search_loading_indicator')), findsOneWidget);

      // Let it complete
      await tester.pumpAndSettle();
    });

    testWidgets('can select location and confirm in form', (tester) async {
      final mockLocationService = MockLocationService(
        permissionStatus: LocationPermissionStatus.granted,
        mockSuggestions: [
          AddressSuggestion(
            address: 'Empire State Building, New York, NY',
            latitude: 40.7484,
            longitude: -73.9857,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        locationService: mockLocationService,
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Type address
      final searchField = find.byKey(const Key('address_search_field'));
      await tester.enterText(searchField, 'Empire State');
      await tester.pumpAndSettle();

      // Select a suggestion
      await tester.tap(find.text('Empire State Building, New York, NY'));
      await tester.pumpAndSettle();

      // Tap Select Location button
      final selectButton = find.widgetWithText(
        GestureDetector,
        'Select Location',
      );
      await tester.tap(selectButton);
      await tester.pumpAndSettle();

      // Verify we're back on the form with the address displayed
      expect(find.byKey(const Key('location_picker')), findsNothing);
      expect(
        find.textContaining('Empire State Building'),
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
  final List<AddressSuggestion> mockSuggestions;
  final bool simulateDelay;
  final bool simulateSearchDelay;

  MockLocationService({
    this.permissionStatus = LocationPermissionStatus.granted,
    this.mockPosition,
    this.mockAddress,
    this.mockSuggestions = const [],
    this.simulateDelay = false,
    this.simulateSearchDelay = false,
  });

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    return permissionStatus;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
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
    if (simulateSearchDelay) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (query.isEmpty) return [];
    return mockSuggestions;
  }

  @override
  Future<LocationPosition> geocodeAddress(String address) async {
    final suggestion = mockSuggestions.firstWhere(
      (s) => s.address == address,
      orElse: () => AddressSuggestion(
        address: address,
        latitude: 40.7128,
        longitude: -74.0060,
      ),
    );
    return LocationPosition(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
    );
  }
}
