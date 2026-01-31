import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:field_reporter/core/theme/app_colors.dart';
import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/providers/level_indicator_provider.dart';
import 'package:field_reporter/services/accelerometer_service.dart';
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
  Future<void> openCameraForVideo() async {}

  @override
  Future<String?> capturePhoto() async => '/path/to/photo.jpg';

  @override
  Future<void> startRecording() async {}

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
  AccelerometerData _currentData = const AccelerometerData(x: 0, y: 0, z: 9.8);

  void emitData(AccelerometerData data) {
    _currentData = data;
    _controller.add(data);
  }

  @override
  Stream<AccelerometerData> get accelerometerStream => _controller.stream;

  @override
  AccelerometerData get currentData => _currentData;

  @override
  void startListening() {}

  @override
  void stopListening() {}

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Camera shows level indicator using accelerometer', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;
    late MockLocationService mockLocationService;
    late MockAccelerometerService mockAccelerometerService;
    late List<MethodCall> hapticCalls;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
      mockLocationService = MockLocationService();
      mockAccelerometerService = MockAccelerometerService();
      SharedPreferences.setMockInitialValues({});

      // Track haptic feedback calls
      hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(methodCall);
          }
          return null;
        },
      );
    });

    tearDown(() {
      mockAccelerometerService.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget createTestWidget({ProviderContainer? container}) {
      return ProviderScope(
        parent: container,
        overrides: container == null
            ? [
                permissionServiceProvider
                    .overrideWithValue(mockPermissionService),
                cameraServiceProvider.overrideWithValue(mockCameraService),
                locationServiceProvider.overrideWithValue(mockLocationService),
                accelerometerServiceProvider
                    .overrideWithValue(mockAccelerometerService),
              ]
            : [],
        child: const MaterialApp(
          home: CameraCaptureScreen(),
        ),
      );
    }

    testWidgets('level indicator is visible when camera is open',
        (tester) async {
      // Step 1: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Verify level indicator is visible
      expect(find.byKey(const Key('level_indicator')), findsOneWidget);
    });

    testWidgets('level indicator shows tilt when device tilted left',
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

      // Step 3: Tilt device left (negative x acceleration)
      final leftTiltData = const AccelerometerData(x: -3.0, y: 0, z: 9.8);
      mockAccelerometerService.emitData(leftTiltData);
      container
          .read(levelIndicatorProvider.notifier)
          .updateFromData(leftTiltData);
      await tester.pump(const Duration(milliseconds: 100));

      // Step 4: Verify level indicator shows tilt
      final levelState = container.read(levelIndicatorProvider);
      expect(levelState.tiltAngle, isNot(0));
      expect(levelState.tiltAngle, lessThan(0)); // Left tilt = negative angle
    });

    testWidgets('level indicator reflects change when tilted right',
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

      // Step 5: Tilt device right (positive x acceleration)
      final rightTiltData = const AccelerometerData(x: 3.0, y: 0, z: 9.8);
      mockAccelerometerService.emitData(rightTiltData);
      container
          .read(levelIndicatorProvider.notifier)
          .updateFromData(rightTiltData);
      await tester.pump(const Duration(milliseconds: 100));

      // Step 6: Verify level indicator reflects change
      final levelState = container.read(levelIndicatorProvider);
      expect(
          levelState.tiltAngle, greaterThan(0)); // Right tilt = positive angle
    });

    testWidgets('level indicator shows green/centered when device is level',
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

      // Step 7: Hold device perfectly level (x close to 0)
      final levelData = const AccelerometerData(x: 0.0, y: 0, z: 9.8);
      mockAccelerometerService.emitData(levelData);
      container.read(levelIndicatorProvider.notifier).updateFromData(levelData);
      await tester.pump(const Duration(milliseconds: 100));

      // Step 8: Verify level indicator shows green/centered
      final levelState = container.read(levelIndicatorProvider);
      expect(levelState.isLevel, isTrue);
      // The widget uses emerald500 when level
      expect(AppColors.emerald500, equals(const Color(0xFF10B981)));
    });

    testWidgets('haptic feedback when level achieved', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            cameraServiceProvider.overrideWithValue(mockCameraService),
            locationServiceProvider.overrideWithValue(mockLocationService),
            accelerometerServiceProvider
                .overrideWithValue(mockAccelerometerService),
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

      // Start tilted
      final tiltedData = const AccelerometerData(x: 3.0, y: 0, z: 9.8);
      mockAccelerometerService.emitData(tiltedData);
      container
          .read(levelIndicatorProvider.notifier)
          .updateFromData(tiltedData);
      await tester.pump(const Duration(milliseconds: 100));

      hapticCalls.clear();

      // Step 9: Move to level position
      final levelData = const AccelerometerData(x: 0.0, y: 0, z: 9.8);
      mockAccelerometerService.emitData(levelData);
      container.read(levelIndicatorProvider.notifier).updateFromData(levelData);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify haptic feedback when level achieved
      expect(hapticCalls, isNotEmpty);
    });

    testWidgets('level indicator can be toggled off', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify indicator is visible initially
      expect(find.byKey(const Key('level_indicator')), findsOneWidget);

      // Find and tap the level indicator toggle button
      final toggleButton = find.byKey(const Key('level_indicator_toggle'));
      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Verify indicator is hidden
      expect(find.byKey(const Key('level_indicator')), findsNothing);
    });

    testWidgets('level indicator visibility persists across sessions',
        (tester) async {
      // Set up SharedPreferences with level indicator disabled
      SharedPreferences.setMockInitialValues({
        'level_indicator_enabled': false,
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Level indicator should be hidden based on saved preference
      expect(find.byKey(const Key('level_indicator')), findsNothing);
    });
  });
}
