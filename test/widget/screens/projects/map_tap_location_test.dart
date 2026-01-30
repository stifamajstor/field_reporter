import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/services/location_service.dart';

void main() {
  group('Map tap location selection', () {
    late MockLocationService mockLocationService;

    setUp(() {
      mockLocationService = MockLocationService();
    });

    Widget createTestWidget({Widget? child}) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() => _MockProjectsNotifier()),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child ?? const CreateProjectScreen(),
        ),
      );
    }

    testWidgets('tapping map displays marker at tapped location',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Navigate to create project form - already on it
      expect(find.text('Create Project'), findsOneWidget);

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Verify map is displayed
      expect(find.byKey(const Key('location_picker')), findsOneWidget);
      expect(find.byKey(const Key('location_map_preview')), findsOneWidget);

      // Find the map container and tap on it
      final mapFinder = find.byKey(const Key('location_map_preview'));
      expect(mapFinder, findsOneWidget);

      // Tap on the map at a specific location
      await tester.tap(mapFinder);
      await tester.pumpAndSettle();

      // Verify marker appears at tapped location (indicated by location icon)
      expect(find.byIcon(Icons.location_on), findsAtLeast(1));

      // Verify address is reverse-geocoded (mock returns "123 Test Street, Test City")
      // It appears in both the text field and the map preview, so expect at least one
      expect(find.textContaining('123 Test Street'), findsAtLeast(1));

      // Verify coordinates update (shown in the map preview as "lat, lng")
      // The tap is at center of map, so offset is 0, coordinates are 40.7128, -74.0060
      expect(find.textContaining('-74.0060'), findsOneWidget);
    });

    testWidgets('tapping map reverse geocodes the coordinates', (tester) async {
      // Configure mock to return specific reverse geocode result
      mockLocationService.reverseGeocodeResult = '456 New Address, New York';

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap on map
      await tester.tap(find.byKey(const Key('location_map_preview')));
      await tester.pumpAndSettle();

      // Verify the reverse geocoded address appears (in text field and/or map preview)
      expect(find.textContaining('456 New Address'), findsAtLeast(1));
    });

    testWidgets('selecting map location updates select button state',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap location field
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Tap on map to select location
      await tester.tap(find.byKey(const Key('location_map_preview')));
      await tester.pumpAndSettle();

      // Find and tap the Select Location button (inside PrimaryButton)
      final selectButtonFinder = find.widgetWithText(
        GestureDetector,
        'Select Location',
      );
      expect(selectButtonFinder, findsOneWidget);

      await tester.tap(selectButtonFinder);
      await tester.pumpAndSettle();

      // The bottom sheet should close and address should appear in form
      expect(find.byKey(const Key('location_picker')), findsNothing);
      expect(find.textContaining('123 Test Street'), findsOneWidget);
    });
  });
}

/// Mock location service for testing
class MockLocationService implements LocationService {
  String reverseGeocodeResult = '123 Test Street, Test City';
  double defaultLatitude = 40.7128;
  double defaultLongitude = -74.0060;

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    return LocationPermissionStatus.granted;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    return LocationPermissionStatus.granted;
  }

  @override
  Future<LocationPosition> getCurrentPosition() async {
    return LocationPosition(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
    );
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async {
    return reverseGeocodeResult;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<AddressSuggestion>> searchAddress(String query) async {
    return [
      AddressSuggestion(
        address: '$query, Test City',
        latitude: defaultLatitude,
        longitude: defaultLongitude,
      ),
    ];
  }

  @override
  Future<LocationPosition> geocodeAddress(String address) async {
    return LocationPosition(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
    );
  }
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  @override
  Future<List<Project>> build() async {
    return [];
  }

  @override
  Future<Project> createProject(Project project) async {
    return project;
  }
}
