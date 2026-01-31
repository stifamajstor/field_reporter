import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/presentation/photo_preview_screen.dart';
import 'package:field_reporter/features/capture/providers/compass_provider.dart';
import 'package:field_reporter/services/accelerometer_service.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/compass_service.dart';
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
  String? _capturedPhotoPath;
  double? _capturedCompassHeading;

  String? get capturedPhotoPath => _capturedPhotoPath;
  double? get capturedCompassHeading => _capturedCompassHeading;

  void setCapturedPhotoPath(String path) {
    _capturedPhotoPath = path;
  }

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
  Future<String?> capturePhoto({double? compassHeading}) async {
    _capturedCompassHeading = compassHeading;
    return _capturedPhotoPath ?? '/path/to/photo.jpg';
  }

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
  @override
  Future<LocationPermissionStatus> checkPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<LocationPermissionStatus> requestPermission() async =>
      LocationPermissionStatus.granted;

  @override
  Future<LocationPosition> getCurrentPosition() async =>
      const LocationPosition(latitude: 45.8150, longitude: 15.9819);

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async =>
      'Test Location';

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<AddressSuggestion>> searchAddress(String query) async => [];

  @override
  Future<LocationPosition> geocodeAddress(String address) async =>
      const LocationPosition(latitude: 45.8150, longitude: 15.9819);
}

/// Mock accelerometer service for testing.
class MockAccelerometerService implements AccelerometerService {
  final _controller = StreamController<AccelerometerData>.broadcast();

  @override
  Stream<AccelerometerData> get accelerometerStream => _controller.stream;

  @override
  AccelerometerData get currentData =>
      const AccelerometerData(x: 0, y: 0, z: 9.8);

  @override
  void startListening() {}

  @override
  void stopListening() {}

  void dispose() {
    _controller.close();
  }
}

/// Mock compass service for testing.
class MockCompassService implements CompassService {
  final _controller = StreamController<CompassData>.broadcast();
  CompassData _currentData = const CompassData(heading: 0, accuracy: 1);

  void setInitialHeading(double heading) {
    _currentData = CompassData(heading: heading, accuracy: 1);
  }

  void emitData(CompassData data) {
    _currentData = data;
    _controller.add(data);
  }

  @override
  Stream<CompassData> get compassStream => _controller.stream;

  @override
  CompassData get currentData => _currentData;

  @override
  void startListening() {}

  @override
  void stopListening() {}

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Camera captures compass direction metadata', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;
    late MockLocationService mockLocationService;
    late MockAccelerometerService mockAccelerometerService;
    late MockCompassService mockCompassService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
      mockLocationService = MockLocationService();
      mockAccelerometerService = MockAccelerometerService();
      mockCompassService = MockCompassService();
      SharedPreferences.setMockInitialValues({});

      // Mock haptic feedback
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          return null;
        },
      );
    });

    tearDown(() {
      mockAccelerometerService.dispose();
      mockCompassService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          cameraServiceProvider.overrideWithValue(mockCameraService),
          locationServiceProvider.overrideWithValue(mockLocationService),
          accelerometerServiceProvider
              .overrideWithValue(mockAccelerometerService),
          compassServiceProvider.overrideWithValue(mockCompassService),
        ],
        child: const MaterialApp(
          home: CameraCaptureScreen(),
        ),
      );
    }

    testWidgets(
        'compass direction is captured when photo is taken facing north',
        (tester) async {
      // Step 1: Open camera facing north (heading = 0)
      mockCompassService.emitData(const CompassData(heading: 0, accuracy: 1));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Capture photo
      final captureButton = find.byKey(const Key('capture_button'));
      expect(captureButton, findsOneWidget);
      await tester.tap(captureButton);
      await tester.pumpAndSettle();

      // Step 3: Verify compass direction is recorded (0° = North)
      expect(mockCameraService.capturedCompassHeading, isNotNull);
      expect(mockCameraService.capturedCompassHeading, equals(0.0));
    });

    testWidgets('compass direction is captured when photo is taken facing east',
        (tester) async {
      // Step 5: Rotate to face east (heading = 90)
      // Set initial heading before widget pumps
      mockCompassService.setInitialHeading(90);

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            cameraServiceProvider.overrideWithValue(mockCameraService),
            locationServiceProvider.overrideWithValue(mockLocationService),
            accelerometerServiceProvider
                .overrideWithValue(mockAccelerometerService),
            compassServiceProvider.overrideWithValue(mockCompassService),
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

      // Update compass state with east heading
      container
          .read(compassProvider.notifier)
          .updateFromData(const CompassData(heading: 90, accuracy: 1));
      await tester.pump();

      // Step 6: Capture another photo
      final captureButton = find.byKey(const Key('capture_button'));
      await tester.tap(captureButton);
      await tester.pumpAndSettle();

      // Step 7: Verify direction is different (90° = East)
      expect(mockCameraService.capturedCompassHeading, isNotNull);
      expect(mockCameraService.capturedCompassHeading, equals(90.0));
    });

    testWidgets('different compass directions result in different metadata',
        (tester) async {
      // Test that north and east produce different values
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            cameraServiceProvider.overrideWithValue(mockCameraService),
            locationServiceProvider.overrideWithValue(mockLocationService),
            accelerometerServiceProvider
                .overrideWithValue(mockAccelerometerService),
            compassServiceProvider.overrideWithValue(mockCompassService),
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

      // Set heading to North
      mockCompassService.emitData(const CompassData(heading: 0, accuracy: 1));
      container
          .read(compassProvider.notifier)
          .updateFromData(const CompassData(heading: 0, accuracy: 1));
      await tester.pump();

      final northHeading = container.read(compassProvider).heading;

      // Set heading to East
      mockCompassService.emitData(const CompassData(heading: 90, accuracy: 1));
      container
          .read(compassProvider.notifier)
          .updateFromData(const CompassData(heading: 90, accuracy: 1));
      await tester.pump();

      final eastHeading = container.read(compassProvider).heading;

      // Verify they are different
      expect(northHeading, isNot(equals(eastHeading)));
      expect(northHeading, equals(0.0));
      expect(eastHeading, equals(90.0));
    });

    testWidgets('compass direction is displayed in preview after capture',
        (tester) async {
      // Set compass to north
      mockCompassService.emitData(const CompassData(heading: 0, accuracy: 1));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Capture photo
      final captureButton = find.byKey(const Key('capture_button'));
      await tester.tap(captureButton);
      await tester.pumpAndSettle();

      // Check that we navigated to preview with compass direction
      // The preview screen should show compass direction metadata
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
      expect(find.textContaining('N'), findsWidgets); // North direction display
    });

    testWidgets('compass heading converts to cardinal direction correctly',
        (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            cameraServiceProvider.overrideWithValue(mockCameraService),
            locationServiceProvider.overrideWithValue(mockLocationService),
            accelerometerServiceProvider
                .overrideWithValue(mockAccelerometerService),
            compassServiceProvider.overrideWithValue(mockCompassService),
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

      // Test North (0°)
      container
          .read(compassProvider.notifier)
          .updateFromData(const CompassData(heading: 0, accuracy: 1));
      expect(container.read(compassProvider).cardinalDirection, equals('N'));

      // Test East (90°)
      container
          .read(compassProvider.notifier)
          .updateFromData(const CompassData(heading: 90, accuracy: 1));
      expect(container.read(compassProvider).cardinalDirection, equals('E'));

      // Test South (180°)
      container
          .read(compassProvider.notifier)
          .updateFromData(const CompassData(heading: 180, accuracy: 1));
      expect(container.read(compassProvider).cardinalDirection, equals('S'));

      // Test West (270°)
      container
          .read(compassProvider.notifier)
          .updateFromData(const CompassData(heading: 270, accuracy: 1));
      expect(container.read(compassProvider).cardinalDirection, equals('W'));
    });
  });
}
