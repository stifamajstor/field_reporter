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

/// Mock camera service for testing that tracks capture calls.
class MockCameraService implements CameraService {
  LocationPosition? lastCapturedLocation;
  bool? lastCapturedIsLocationStale;
  bool capturePhotoCalled = false;

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
  Future<String?> capturePhoto({
    double? compassHeading,
    LocationPosition? location,
    bool? isLocationStale,
  }) async {
    capturePhotoCalled = true;
    lastCapturedLocation = location;
    lastCapturedIsLocationStale = isLocationStale;
    return '/path/to/photo.jpg';
  }

  @override
  Future<void> startRecording({bool enableAudio = true}) async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async => null;

  @override
  Future<void> closeCamera() async {}

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> setZoomLevel(double zoom) async {}

  @override
  double get currentZoomLevel => 1.0;

  @override
  double get minZoomLevel => 1.0;

  @override
  double get maxZoomLevel => 10.0;

  @override
  Future<void> setFocusPoint(double x, double y) async {}
}

/// Mock location service for testing.
class MockLocationService implements LocationService {
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.denied;
  LocationPosition? _currentPosition;
  bool throwOnGetPosition = false;

  void setPermissionStatus(LocationPermissionStatus status) {
    _permissionStatus = status;
  }

  void setCurrentPosition(LocationPosition? position) {
    _currentPosition = position;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async => _permissionStatus;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      _permissionStatus;

  @override
  Future<LocationPosition> getCurrentPosition() async {
    if (throwOnGetPosition || _currentPosition == null) {
      throw const LocationServiceException('Location permission denied');
    }
    return _currentPosition!;
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async =>
      'Test Location';

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<AddressSuggestion>> searchAddress(String query) async => [];

  @override
  Future<LocationPosition> geocodeAddress(String address) async {
    if (_currentPosition == null) {
      throw const LocationServiceException('Location permission denied');
    }
    return _currentPosition!;
  }

  @override
  Future<LocationPosition?> getLastKnownPosition() async => null;

  @override
  Future<DateTime?> getLastKnownPositionTimestamp() async => null;
}

void main() {
  group('Location permission denial shows fallback', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;
    late MockLocationService mockLocationService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
      mockLocationService = MockLocationService();
      SharedPreferences.setMockInitialValues({});
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
        'when location permission denied, GPS overlay shows "Location unavailable"',
        (tester) async {
      // Step 1: Deny location permission
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);
      mockLocationService.throwOnGetPosition = true;

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 3: Verify GPS overlay shows 'Location unavailable'
      expect(find.byKey(const Key('gps_overlay')), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);
    });

    testWidgets('capture still works when location permission is denied',
        (tester) async {
      // Step 1: Deny location permission
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);
      mockLocationService.throwOnGetPosition = true;

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 4: Verify capture still works
      final captureButton = find.byKey(const Key('capture_button'));
      expect(captureButton, findsOneWidget);

      await tester.tap(captureButton);
      await tester.pumpAndSettle();

      // Verify photo was captured (navigated to preview)
      expect(mockCameraService.capturePhotoCalled, isTrue);
    });

    testWidgets('metadata notes location unavailable when permission denied',
        (tester) async {
      // Step 1: Deny location permission
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);
      mockLocationService.throwOnGetPosition = true;

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Capture photo
      final captureButton = find.byKey(const Key('capture_button'));
      await tester.tap(captureButton);
      await tester.pumpAndSettle();

      // Step 5: Verify metadata notes location unavailable
      // When location is denied, the location should be null
      expect(mockCameraService.lastCapturedLocation, isNull);
    });

    testWidgets(
        'shows option to add location manually when location unavailable',
        (tester) async {
      // Step 1: Deny location permission
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);
      mockLocationService.throwOnGetPosition = true;

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 6: Verify option to add location manually later
      // The GPS overlay should show an "add location" option when unavailable
      expect(find.byKey(const Key('gps_overlay')), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);
      expect(find.byKey(const Key('add_location_button')), findsOneWidget);
    });

    testWidgets('add location button opens location picker', (tester) async {
      // Step 1: Deny location permission
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);
      mockLocationService.throwOnGetPosition = true;

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the add location button
      final addLocationButton = find.byKey(const Key('add_location_button'));
      expect(addLocationButton, findsOneWidget);

      await tester.tap(addLocationButton);
      await tester.pumpAndSettle();

      // Verify manual location dialog appears
      expect(find.byKey(const Key('manual_location_dialog')), findsOneWidget);
    });

    testWidgets('can set manual location when permission denied',
        (tester) async {
      // Step 1: Deny location permission
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);
      mockLocationService.throwOnGetPosition = true;

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

      // Tap the add location button
      final addLocationButton = find.byKey(const Key('add_location_button'));
      await tester.tap(addLocationButton);
      await tester.pumpAndSettle();

      // Enter coordinates manually
      final latField = find.byKey(const Key('manual_latitude_field'));
      final lonField = find.byKey(const Key('manual_longitude_field'));
      expect(latField, findsOneWidget);
      expect(lonField, findsOneWidget);

      await tester.enterText(latField, '45.8150');
      await tester.enterText(lonField, '15.9819');
      await tester.pumpAndSettle();

      // Confirm manual location
      final confirmButton = find.byKey(const Key('confirm_manual_location'));
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify the provider state is updated with manual location
      final gpsState = container.read(gpsOverlayProvider);
      expect(gpsState.currentPosition, isNotNull);
      expect(gpsState.currentPosition!.latitude, closeTo(45.8150, 0.001));
      expect(gpsState.currentPosition!.longitude, closeTo(15.9819, 0.001));
      expect(gpsState.isManualLocation, isTrue);

      // Verify GPS overlay now shows the manual coordinates (formatted to 4 decimal places)
      expect(find.textContaining('45.8150'), findsOneWidget);
      expect(find.textContaining('15.9819'), findsOneWidget);

      // Verify manual location indicator is shown
      expect(
          find.byKey(const Key('manual_location_indicator')), findsOneWidget);
    });

    testWidgets('manual location is used in photo capture', (tester) async {
      // Step 1: Deny location permission
      mockLocationService.setPermissionStatus(LocationPermissionStatus.denied);
      mockLocationService.throwOnGetPosition = true;

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

      // Set manual location via provider
      container.read(gpsOverlayProvider.notifier).setManualLocation(
            const LocationPosition(latitude: 45.8150, longitude: 15.9819),
          );
      await tester.pumpAndSettle();

      // Capture photo
      final captureButton = find.byKey(const Key('capture_button'));
      await tester.tap(captureButton);
      await tester.pumpAndSettle();

      // Verify manual location was used in capture
      expect(mockCameraService.lastCapturedLocation, isNotNull);
      expect(mockCameraService.lastCapturedLocation!.latitude,
          closeTo(45.8150, 0.001));
      expect(mockCameraService.lastCapturedLocation!.longitude,
          closeTo(15.9819, 0.001));
    });
  });
}
