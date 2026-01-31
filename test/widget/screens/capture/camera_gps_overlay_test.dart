import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/providers/gps_overlay_provider.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/location_service.dart';
import 'package:field_reporter/services/permission_service.dart';

// Re-export the provider for tests
export 'package:field_reporter/features/capture/providers/gps_overlay_provider.dart';

/// Mock permission service for testing.
class MockPermissionService implements PermissionService {
  PermissionStatus _cameraStatus = PermissionStatus.granted;

  void setCameraStatus(PermissionStatus status) {
    _cameraStatus = status;
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async => _cameraStatus;

  @override
  Future<PermissionStatus> requestCameraPermission() async => _cameraStatus;

  @override
  Future<PermissionStatus> checkMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

/// Mock camera service for testing.
class MockCameraService implements CameraService {
  @override
  CameraLensDirection get lensDirection => CameraLensDirection.back;

  @override
  FlashMode get currentFlashMode => FlashMode.auto;

  @override
  Future<void> setFlashMode(FlashMode mode) async {}

  @override
  Future<void> openCamera() async {}

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {}

  @override
  Future<String?> capturePhoto({double? compassHeading}) async =>
      '/path/to/photo.jpg';

  @override
  Future<void> startRecording({bool enableAudio = true}) async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async => null;

  @override
  Future<void> closeCamera() async {}

  @override
  Future<void> switchCamera() async {}
}

/// Mock location service for testing.
class MockLocationService implements LocationService {
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.granted;
  LocationPosition _currentPosition = const LocationPosition(
    latitude: 45.8150,
    longitude: 15.9819,
  );
  final _positionController = StreamController<LocationPosition>.broadcast();

  void setPermissionStatus(LocationPermissionStatus status) {
    _permissionStatus = status;
  }

  void setCurrentPosition(LocationPosition position) {
    _currentPosition = position;
    _positionController.add(position);
  }

  void emitPosition(LocationPosition position) {
    _positionController.add(position);
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async => _permissionStatus;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      _permissionStatus;

  @override
  Future<LocationPosition> getCurrentPosition() async => _currentPosition;

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async =>
      'Test Location';

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<AddressSuggestion>> searchAddress(String query) async => [];

  @override
  Future<LocationPosition> geocodeAddress(String address) async =>
      _currentPosition;

  Stream<LocationPosition> get positionStream => _positionController.stream;

  void dispose() {
    _positionController.close();
  }
}

void main() {
  group('Camera displays GPS coordinates overlay', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;
    late MockLocationService mockLocationService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
      mockLocationService = MockLocationService();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      mockLocationService.dispose();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          cameraServiceProvider.overrideWithValue(mockCameraService),
          locationServiceProvider.overrideWithValue(mockLocationService),
        ],
        child: const MaterialApp(
          home: CameraCaptureScreen(),
        ),
      );
    }

    testWidgets(
        'displays GPS coordinates in corner when location permission granted',
        (tester) async {
      // Step 1: Ensure location permission granted
      mockLocationService.setPermissionStatus(LocationPermissionStatus.granted);
      mockLocationService.setCurrentPosition(const LocationPosition(
        latitude: 45.8150,
        longitude: 15.9819,
      ));

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 3: Verify GPS coordinates displayed in corner
      expect(find.byKey(const Key('gps_overlay')), findsOneWidget);
      expect(find.textContaining('45.8150'), findsOneWidget);
      expect(find.textContaining('15.9819'), findsOneWidget);
    });

    testWidgets('coordinates update as device moves', (tester) async {
      // Step 4: Verify coordinates update as device moves
      mockLocationService.setPermissionStatus(LocationPermissionStatus.granted);
      mockLocationService.setCurrentPosition(const LocationPosition(
        latitude: 45.8150,
        longitude: 15.9819,
      ));

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            cameraServiceProvider.overrideWithValue(mockCameraService),
            locationServiceProvider.overrideWithValue(mockLocationService),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: CameraCaptureScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial coordinates
      expect(find.textContaining('45.8150'), findsOneWidget);

      // Simulate device movement by updating the position in the provider
      mockLocationService.setCurrentPosition(const LocationPosition(
        latitude: 45.8200,
        longitude: 15.9900,
      ));
      container.read(gpsOverlayProvider.notifier).updatePosition(
            const LocationPosition(
              latitude: 45.8200,
              longitude: 15.9900,
            ),
          );
      await tester.pumpAndSettle();

      // Verify coordinates updated
      expect(find.textContaining('45.8200'), findsOneWidget);
      expect(find.textContaining('15.9900'), findsOneWidget);
    });

    testWidgets('coordinates are accurate to visible precision',
        (tester) async {
      // Step 5: Verify coordinates are accurate to visible precision
      mockLocationService.setPermissionStatus(LocationPermissionStatus.granted);
      mockLocationService.setCurrentPosition(const LocationPosition(
        latitude: 45.815012345,
        longitude: 15.981987654,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should display with reasonable precision (4 decimal places)
      expect(find.textContaining('45.8150'), findsOneWidget);
      expect(find.textContaining('15.9820'), findsOneWidget);
    });

    testWidgets('overlay can be toggled off in settings', (tester) async {
      // Step 6: Toggle overlay off in settings
      mockLocationService.setPermissionStatus(LocationPermissionStatus.granted);
      mockLocationService.setCurrentPosition(const LocationPosition(
        latitude: 45.8150,
        longitude: 15.9819,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify overlay is visible initially
      expect(find.byKey(const Key('gps_overlay')), findsOneWidget);

      // Find and tap the GPS overlay toggle button
      final toggleButton = find.byKey(const Key('gps_overlay_toggle'));
      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Step 7: Verify overlay hidden
      expect(find.byKey(const Key('gps_overlay')), findsNothing);
    });

    testWidgets('overlay visibility persists across sessions', (tester) async {
      // Set up SharedPreferences with overlay disabled
      SharedPreferences.setMockInitialValues({
        'gps_overlay_enabled': false,
      });

      mockLocationService.setPermissionStatus(LocationPermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Overlay should be hidden based on saved preference
      expect(find.byKey(const Key('gps_overlay')), findsNothing);
    });

    testWidgets('shows location unavailable when permission denied',
        (tester) async {
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // GPS overlay should show unavailable state
      expect(find.byKey(const Key('gps_overlay')), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);
    });
  });
}
