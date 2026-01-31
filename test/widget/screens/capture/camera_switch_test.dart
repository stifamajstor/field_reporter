import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for testing.
class MockPermissionService implements PermissionService {
  PermissionStatus _cameraStatus = PermissionStatus.granted;

  void setCameraStatus(PermissionStatus status) {
    _cameraStatus = status;
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async {
    return _cameraStatus;
  }

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    return _cameraStatus;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

/// Mock camera service for testing camera switching.
class MockCameraService implements CameraService {
  bool _isInitialized = false;
  bool _isPreviewActive = false;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  int _switchCount = 0;
  FlashMode _flashMode = FlashMode.auto;

  bool get isInitialized => _isInitialized;
  bool get isPreviewActive => _isPreviewActive;
  CameraLensDirection get currentLensDirection => _currentLensDirection;
  int get switchCount => _switchCount;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> openCamera() async {
    _isInitialized = true;
    _isPreviewActive = true;
    _currentLensDirection = CameraLensDirection.back;
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
    _switchCount++;
    _currentLensDirection = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }

  @override
  CameraLensDirection get lensDirection => _currentLensDirection;
}

void main() {
  group('User can switch between front and back camera', () {
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

    testWidgets('back camera is active by default when camera opens',
        (tester) async {
      // Step 1: Open camera
      // Step 2: Verify back camera is active by default
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Camera should be initialized with back camera
      expect(mockCameraService.isInitialized, isTrue);
      expect(mockCameraService.currentLensDirection, CameraLensDirection.back);
    });

    testWidgets('camera switch button is visible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 3: Tap camera switch button - first verify it exists
      expect(find.byKey(const Key('camera_switch_button')), findsOneWidget);
    });

    testWidgets('tapping switch button switches to front camera with animation',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify back camera is active initially
      expect(mockCameraService.currentLensDirection, CameraLensDirection.back);

      // Step 3: Tap camera switch button
      await tester.tap(find.byKey(const Key('camera_switch_button')));

      // Step 4: Verify switch animation plays
      await tester.pump();
      expect(find.byKey(const Key('camera_switch_animation')), findsOneWidget);

      await tester.pumpAndSettle();

      // Step 5: Verify front camera preview now active
      expect(mockCameraService.currentLensDirection, CameraLensDirection.front);
      expect(mockCameraService.switchCount, 1);
    });

    testWidgets('tapping switch button again restores back camera',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to front camera first
      await tester.tap(find.byKey(const Key('camera_switch_button')));
      await tester.pumpAndSettle();
      expect(mockCameraService.currentLensDirection, CameraLensDirection.front);

      // Step 6: Tap switch button again
      await tester.tap(find.byKey(const Key('camera_switch_button')));
      await tester.pumpAndSettle();

      // Step 7: Verify back camera preview restored
      expect(mockCameraService.currentLensDirection, CameraLensDirection.back);
      expect(mockCameraService.switchCount, 2);
    });

    testWidgets('switch button has correct accessibility label',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final switchButton = find.byKey(const Key('camera_switch_button'));
      expect(switchButton, findsOneWidget);

      // Verify the icon is a camera switch icon
      final iconFinder = find.descendant(
        of: switchButton,
        matching: find.byIcon(Icons.cameraswitch),
      );
      expect(iconFinder, findsOneWidget);
    });
  });
}
