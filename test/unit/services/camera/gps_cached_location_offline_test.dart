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

/// Mock camera service for testing.
class MockCameraService implements CameraService {
  LocationPosition? _capturedLocation;
  bool? _capturedLocationIsStale;

  LocationPosition? get capturedLocation => _capturedLocation;
  bool? get capturedLocationIsStale => _capturedLocationIsStale;

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
    _capturedLocation = location;
    _capturedLocationIsStale = isLocationStale;
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

/// Mock location service that simulates offline/airplane mode.
class MockOfflineLocationService implements LocationService {
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.granted;
  bool _isOffline = false;
  LocationPosition? _cachedPosition;
  DateTime? _cachedPositionTimestamp;
  LocationPosition? _currentPosition;

  void setPermissionStatus(LocationPermissionStatus status) {
    _permissionStatus = status;
  }

  void setOffline(bool offline) {
    _isOffline = offline;
  }

  void setCachedPosition(LocationPosition? position, {DateTime? timestamp}) {
    _cachedPosition = position;
    _cachedPositionTimestamp = timestamp;
  }

  void setCurrentPosition(LocationPosition position) {
    _currentPosition = position;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async => _permissionStatus;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      _permissionStatus;

  @override
  Future<LocationPosition> getCurrentPosition() async {
    if (_isOffline) {
      throw const LocationServiceException('No GPS signal - airplane mode');
    }
    return _currentPosition ??
        const LocationPosition(latitude: 45.8150, longitude: 15.9819);
  }

  @override
  Future<LocationPosition?> getLastKnownPosition() async {
    return _cachedPosition;
  }

  @override
  Future<DateTime?> getLastKnownPositionTimestamp() async {
    return _cachedPositionTimestamp;
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async =>
      'Test Location';

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<AddressSuggestion>> searchAddress(String query) async => [];

  @override
  Future<LocationPosition> geocodeAddress(String address) async =>
      const LocationPosition(latitude: 0, longitude: 0);
}

void main() {
  group('GPS capture works with cached location when no signal', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;
    late MockOfflineLocationService mockLocationService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
      mockLocationService = MockOfflineLocationService();
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

    testWidgets('displays last known location when in airplane mode',
        (tester) async {
      // Step 1: Enable airplane mode (simulated by offline flag)
      mockLocationService.setOffline(true);

      // Set up cached location from previous GPS fix
      final cachedPosition = const LocationPosition(
        latitude: 45.8150,
        longitude: 15.9819,
      );
      mockLocationService.setCachedPosition(
        cachedPosition,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 3: Verify last known location displayed (if available)
      expect(find.byKey(const Key('gps_overlay')), findsOneWidget);
      expect(find.textContaining('45.8150'), findsOneWidget);
      expect(find.textContaining('15.9819'), findsOneWidget);
    });

    testWidgets('shows stale location indicator when using cached location',
        (tester) async {
      // Step 1: Enable airplane mode
      mockLocationService.setOffline(true);

      // Set up stale cached location (>1 minute old)
      final cachedPosition = const LocationPosition(
        latitude: 45.8150,
        longitude: 15.9819,
      );
      mockLocationService.setCachedPosition(
        cachedPosition,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      // Step 2: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 4: Verify indicator that location may be stale
      expect(find.byKey(const Key('stale_location_indicator')), findsOneWidget);
    });

    testWidgets('captures photo with cached location attached to metadata',
        (tester) async {
      // Step 1: Enable airplane mode
      mockLocationService.setOffline(true);

      // Set up cached location
      final cachedPosition = const LocationPosition(
        latitude: 45.8150,
        longitude: 15.9819,
      );
      mockLocationService.setCachedPosition(
        cachedPosition,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 5: Capture photo
      final captureButton = find.byKey(const Key('capture_button'));
      expect(captureButton, findsOneWidget);

      await tester.tap(captureButton);
      await tester.pumpAndSettle();

      // Step 6: Verify cached location attached to metadata
      expect(mockCameraService.capturedLocation, isNotNull);
      expect(mockCameraService.capturedLocation!.latitude, equals(45.8150));
      expect(mockCameraService.capturedLocation!.longitude, equals(15.9819));
      expect(mockCameraService.capturedLocationIsStale, isTrue);
    });

    testWidgets('shows no location when offline with no cached data',
        (tester) async {
      // Enable airplane mode with no cached position
      mockLocationService.setOffline(true);
      mockLocationService.setCachedPosition(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show location unavailable
      expect(find.byKey(const Key('gps_overlay')), findsOneWidget);
      expect(find.text('Location unavailable'), findsOneWidget);
    });

    testWidgets('stale indicator not shown when location is fresh',
        (tester) async {
      // Online mode with fresh location
      mockLocationService.setOffline(false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fresh location should not show stale indicator
      expect(find.byKey(const Key('stale_location_indicator')), findsNothing);
    });
  });
}
