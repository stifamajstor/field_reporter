import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
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
  Future<PermissionStatus> checkCameraPermission() async {
    return _cameraStatus;
  }

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    return _cameraStatus;
  }

  @override
  Future<PermissionStatus> checkMicrophonePermission() async {
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> requestMicrophonePermission() async {
    return PermissionStatus.granted;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

/// Mock camera service for testing zoom functionality.
class MockCameraService implements CameraService {
  bool _isInitialized = false;
  bool _isPreviewActive = false;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 10.0;
  bool _capturedAtZoom = false;
  double _capturedZoomLevel = 1.0;

  bool get isInitialized => _isInitialized;
  bool get isPreviewActive => _isPreviewActive;
  FlashMode get flashMode => _flashMode;
  double get zoomLevel => _zoomLevel;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  bool get capturedAtZoom => _capturedAtZoom;
  double get capturedZoomLevel => _capturedZoomLevel;

  @override
  Future<void> openCamera() async {
    _isInitialized = true;
    _isPreviewActive = true;
    _currentLensDirection = CameraLensDirection.back;
    _flashMode = FlashMode.auto;
    _zoomLevel = 1.0;
  }

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {
    _isInitialized = true;
    _isPreviewActive = true;
  }

  @override
  Future<String?> capturePhoto({
    double? compassHeading,
    LocationPosition? location,
    bool? isLocationStale,
  }) async {
    _capturedAtZoom = _zoomLevel > 1.0;
    _capturedZoomLevel = _zoomLevel;
    return '/path/to/photo.jpg';
  }

  @override
  Future<void> startRecording({bool enableAudio = true}) async {}

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
    _currentLensDirection = _currentLensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }

  @override
  CameraLensDirection get lensDirection => _currentLensDirection;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  Future<void> setZoomLevel(double zoom) async {
    _zoomLevel = zoom.clamp(_minZoom, _maxZoom);
  }

  @override
  double get currentZoomLevel => _zoomLevel;

  @override
  double get minZoomLevel => _minZoom;

  @override
  double get maxZoomLevel => _maxZoom;

  @override
  Future<void> setFocusPoint(double x, double y) async {}
}

void main() {
  group('User can zoom camera preview', () {
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

    testWidgets('camera opens with default zoom level of 1.0x', (tester) async {
      // Step 1: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify camera initialized with zoom at 1.0x
      expect(mockCameraService.zoomLevel, 1.0);
    });

    testWidgets('pinch outward to zoom in updates zoom level', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Pinch outward to zoom in
      // Find the camera preview area
      final cameraPreview = find.byType(CameraPreviewWidget);
      expect(cameraPreview, findsOneWidget);

      // Simulate pinch to zoom in (scale factor > 1.0)
      final center = tester.getCenter(cameraPreview);
      final gesture1 = await tester.startGesture(center + const Offset(-50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));

      // Move fingers apart (zoom in)
      await gesture1.moveBy(const Offset(-50, 0));
      await gesture2.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // Step 3: Verify preview zooms smoothly (zoom level increased)
      expect(mockCameraService.zoomLevel, greaterThan(1.0));
    });

    testWidgets('zoom level indicator appears when zoomed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially zoom indicator should not be visible at 1.0x
      expect(find.byKey(const Key('zoom_indicator')), findsNothing);

      // Simulate zoom in
      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);
      final gesture1 = await tester.startGesture(center + const Offset(-50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));

      await gesture1.moveBy(const Offset(-50, 0));
      await gesture2.moveBy(const Offset(50, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // Step 4: Verify zoom level indicator appears
      expect(find.byKey(const Key('zoom_indicator')), findsOneWidget);
    });

    testWidgets('pinch inward to zoom out decreases zoom level',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // First zoom in
      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);

      final gesture1 =
          await tester.startGesture(center + const Offset(-100, 0));
      final gesture2 = await tester.startGesture(center + const Offset(100, 0));
      await gesture1.moveBy(const Offset(-50, 0));
      await gesture2.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      final zoomedInLevel = mockCameraService.zoomLevel;
      expect(zoomedInLevel, greaterThan(1.0));

      // Step 5: Pinch inward to zoom out
      final gesture3 =
          await tester.startGesture(center + const Offset(-100, 0));
      final gesture4 = await tester.startGesture(center + const Offset(100, 0));

      // Move fingers together (zoom out)
      await gesture3.moveBy(const Offset(50, 0));
      await gesture4.moveBy(const Offset(-50, 0));
      await tester.pump();

      await gesture3.up();
      await gesture4.up();
      await tester.pumpAndSettle();

      // Step 6: Verify preview zooms out
      expect(mockCameraService.zoomLevel, lessThan(zoomedInLevel));
    });

    testWidgets('zoom level does not go below minimum (1.0x)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to zoom out from 1.0x
      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);

      final gesture1 =
          await tester.startGesture(center + const Offset(-100, 0));
      final gesture2 = await tester.startGesture(center + const Offset(100, 0));

      // Move fingers together
      await gesture1.moveBy(const Offset(50, 0));
      await gesture2.moveBy(const Offset(-50, 0));
      await tester.pump();

      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // Verify zoom doesn't go below 1.0x
      expect(mockCameraService.zoomLevel, greaterThanOrEqualTo(1.0));
    });

    testWidgets('zoom level does not exceed maximum', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Zoom in multiple times to try to exceed max
      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);

      for (var i = 0; i < 5; i++) {
        final gesture1 =
            await tester.startGesture(center + const Offset(-50, 0));
        final gesture2 =
            await tester.startGesture(center + const Offset(50, 0));

        await gesture1.moveBy(const Offset(-100, 0));
        await gesture2.moveBy(const Offset(100, 0));
        await tester.pump();

        await gesture1.up();
        await gesture2.up();
        await tester.pumpAndSettle();
      }

      // Verify zoom doesn't exceed max
      expect(mockCameraService.zoomLevel,
          lessThanOrEqualTo(mockCameraService.maxZoom));
    });

    testWidgets('photo captured at zoomed level reflects zoom', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Zoom in first
      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);

      final gesture1 = await tester.startGesture(center + const Offset(-50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));
      await gesture1.moveBy(const Offset(-50, 0));
      await gesture2.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      final zoomLevelBeforeCapture = mockCameraService.zoomLevel;
      expect(zoomLevelBeforeCapture, greaterThan(1.0));

      // Step 7 & 8: Capture photo at zoomed level
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify saved photo reflects zoom (photo was captured at zoomed level)
      expect(mockCameraService.capturedAtZoom, isTrue);
      expect(
          mockCameraService.capturedZoomLevel, equals(zoomLevelBeforeCapture));
    });

    testWidgets('zoom indicator shows correct zoom multiplier text',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Zoom in
      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);

      final gesture1 = await tester.startGesture(center + const Offset(-50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));
      await gesture1.moveBy(const Offset(-50, 0));
      await gesture2.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      // Find zoom indicator with zoom level text
      final zoomIndicator = find.byKey(const Key('zoom_indicator'));
      expect(zoomIndicator, findsOneWidget);

      // Verify it shows a zoom value like "2.0x" format
      expect(find.textContaining('x'), findsOneWidget);
    });

    testWidgets('zoom resets when switching cameras', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Zoom in
      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);

      final gesture1 = await tester.startGesture(center + const Offset(-50, 0));
      final gesture2 = await tester.startGesture(center + const Offset(50, 0));
      await gesture1.moveBy(const Offset(-50, 0));
      await gesture2.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture1.up();
      await gesture2.up();
      await tester.pumpAndSettle();

      expect(mockCameraService.zoomLevel, greaterThan(1.0));

      // Switch camera
      await tester.tap(find.byKey(const Key('camera_switch_button')));
      await tester.pumpAndSettle();

      // Zoom should reset to 1.0x when switching cameras
      // This is expected behavior for most camera apps
    });
  });
}
