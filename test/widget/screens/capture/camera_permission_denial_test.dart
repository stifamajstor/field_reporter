import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/location_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for testing permission denial.
class MockPermissionService implements PermissionService {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool openAppSettingsCalled = false;

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
  Future<bool> openAppSettings() async {
    openAppSettingsCalled = true;
    return true;
  }
}

/// Mock camera service for testing.
class MockCameraService implements CameraService {
  @override
  CameraLensDirection get lensDirection => CameraLensDirection.back;

  @override
  FlashMode get currentFlashMode => FlashMode.auto;

  @override
  double get currentZoomLevel => 1.0;

  @override
  double get minZoomLevel => 1.0;

  @override
  double get maxZoomLevel => 10.0;

  @override
  Future<void> setFlashMode(FlashMode mode) async {}

  @override
  Future<void> setZoomLevel(double zoom) async {}

  @override
  Future<void> openCamera() async {}

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {}

  @override
  Future<String?> capturePhoto({
    double? compassHeading,
    LocationPosition? location,
    bool? isLocationStale,
  }) async =>
      null;

  @override
  Future<void> startRecording({bool enableAudio = true}) async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async => null;

  @override
  Future<void> closeCamera() async {}

  @override
  Future<void> switchCamera() async {}

  @override
  Future<void> setFocusPoint(double x, double y) async {}
}

void main() {
  group('Camera gracefully handles permission denial', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          cameraServiceProvider.overrideWithValue(mockCameraService),
        ],
        child: const MaterialApp(
          home: CameraCaptureScreen(),
        ),
      );
    }

    testWidgets('shows error message when camera permission is denied',
        (tester) async {
      // Step 1: Deny camera permission
      mockPermissionService.setCameraStatus(PermissionStatus.denied);

      // Step 2: Attempt to open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 3: Verify error message explaining permission needed
      expect(
        find.text('Camera Permission Required'),
        findsOneWidget,
      );
      expect(
        find.textContaining('allow camera access'),
        findsOneWidget,
      );
    });

    testWidgets('shows button to open device settings when permission denied',
        (tester) async {
      // Step 1: Deny camera permission (permanently denied to show settings button)
      mockPermissionService.setCameraStatus(PermissionStatus.permanentlyDenied);

      // Step 2: Attempt to open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 4: Verify button to open device settings
      expect(
        find.byKey(const Key('open_settings_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping settings button opens app settings', (tester) async {
      // Step 1: Permission permanently denied
      mockPermissionService.setCameraStatus(PermissionStatus.permanentlyDenied);

      // Step 2: Attempt to open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 5: Tap button
      final settingsButton = find.byKey(const Key('open_settings_button'));
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Step 6: Verify navigation to app settings
      expect(mockPermissionService.openAppSettingsCalled, isTrue);
    });

    testWidgets('full permission denial flow', (tester) async {
      // Step 1: Deny camera permission
      mockPermissionService.setCameraStatus(PermissionStatus.permanentlyDenied);

      // Step 2: Attempt to open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 3: Verify error message explaining permission needed
      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.textContaining('allow camera access'), findsOneWidget);

      // Step 4: Verify button to open device settings
      final settingsButton = find.byKey(const Key('open_settings_button'));
      expect(settingsButton, findsOneWidget);

      // Step 5: Tap button
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Step 6: Verify navigation to app settings
      expect(mockPermissionService.openAppSettingsCalled, isTrue);
    });
  });
}
