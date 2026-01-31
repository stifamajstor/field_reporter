import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for testing.
class MockPermissionService implements PermissionService {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  bool _permissionRequested = false;

  void setCameraStatus(PermissionStatus status) {
    _cameraStatus = status;
  }

  bool get wasPermissionRequested => _permissionRequested;

  @override
  Future<PermissionStatus> checkCameraPermission() async {
    return _cameraStatus;
  }

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    _permissionRequested = true;
    return _cameraStatus;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

/// Mock camera service for testing.
class MockCameraService implements CameraService {
  bool _isInitialized = false;
  bool _isPreviewActive = false;
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  bool get isInitialized => _isInitialized;
  bool get isPreviewActive => _isPreviewActive;

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  Future<void> openCamera() async {
    _isInitialized = true;
    _isPreviewActive = true;
  }

  @override
  Future<void> openCameraForVideo() async {
    _isInitialized = true;
    _isPreviewActive = true;
  }

  @override
  Future<String?> capturePhoto() async {
    return '/path/to/photo.jpg';
  }

  @override
  Future<void> startRecording() async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async {
    return null;
  }

  @override
  Future<void> closeCamera() async {
    _isInitialized = false;
    _isPreviewActive = false;
  }

  @override
  Future<void> switchCamera() async {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }
}

void main() {
  group('Camera opens and displays live preview', () {
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

    testWidgets('shows permission prompt when camera permission not granted',
        (tester) async {
      // Step 1: Navigate to capture photo flow (screen opens)
      // Step 2: Verify camera permission prompt if not granted
      mockPermissionService.setCameraStatus(PermissionStatus.denied);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show permission request UI
      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);
    });

    testWidgets('requests permission when grant button is tapped',
        (tester) async {
      // Step 3: Grant camera permission
      mockPermissionService.setCameraStatus(PermissionStatus.denied);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap grant permission button
      await tester.tap(find.text('Grant Permission'));

      // Now set permission to granted for subsequent checks
      mockPermissionService.setCameraStatus(PermissionStatus.granted);
      await tester.pumpAndSettle();

      expect(mockPermissionService.wasPermissionRequested, isTrue);
    });

    testWidgets('displays camera preview when permission is granted',
        (tester) async {
      // Step 4: Verify camera preview is displayed
      mockPermissionService.setCameraStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show camera preview widget
      expect(find.byType(CameraPreviewWidget), findsOneWidget);
      expect(mockCameraService.isPreviewActive, isTrue);
    });

    testWidgets('preview fills the capture area', (tester) async {
      // Step 5: Verify preview fills capture area
      mockPermissionService.setCameraStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the camera preview widget
      final previewFinder = find.byType(CameraPreviewWidget);
      expect(previewFinder, findsOneWidget);

      // Get the preview widget's size
      final previewElement = tester.element(previewFinder);
      final previewBox = previewElement.renderObject as RenderBox;
      final previewSize = previewBox.size;

      // Get screen size
      final screenSize =
          tester.view.physicalSize / tester.view.devicePixelRatio;

      // Preview should fill most of the screen width
      // Accounting for safe areas and controls
      expect(previewSize.width, greaterThanOrEqualTo(screenSize.width * 0.9));
    });

    testWidgets('camera initializes without errors (smooth preview)',
        (tester) async {
      // Step 6: Verify preview is smooth (no lag)
      // In widget tests we verify the camera initializes properly
      // Real performance testing would be done in integration tests
      mockPermissionService.setCameraStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Camera should be initialized
      expect(mockCameraService.isInitialized, isTrue);
      expect(mockCameraService.isPreviewActive, isTrue);

      // No error widgets should be shown
      expect(find.text('Camera Error'), findsNothing);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testWidgets('shows capture button when preview is active', (tester) async {
      mockPermissionService.setCameraStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show capture button
      expect(find.byKey(const Key('capture_button')), findsOneWidget);
    });
  });
}
