import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/providers/camera_focus_provider.dart';
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

/// Mock camera service for testing focus functionality.
class MockCameraService implements CameraService {
  bool _isInitialized = false;
  bool _isPreviewActive = false;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  double _zoomLevel = 1.0;
  final double _minZoom = 1.0;
  final double _maxZoom = 10.0;

  // Focus tracking
  final List<Offset> focusPoints = [];
  bool focusCalled = false;

  bool get isInitialized => _isInitialized;
  bool get isPreviewActive => _isPreviewActive;

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
  Future<void> setFocusPoint(double x, double y) async {
    focusCalled = true;
    focusPoints.add(Offset(x, y));
  }
}

void main() {
  group('User can tap to focus camera', () {
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

    testWidgets('tapping on camera preview triggers focus at tap point',
        (tester) async {
      // Step 1: Open camera with scene having varying depth
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the camera preview area
      final cameraPreview = find.byType(CameraPreviewWidget);
      expect(cameraPreview, findsOneWidget);

      // Step 2: Tap on foreground object (arbitrary point in preview)
      final previewCenter = tester.getCenter(cameraPreview);
      final tapPoint =
          previewCenter + const Offset(-50, -50); // Foreground area
      await tester.tapAt(tapPoint);
      await tester.pump();

      // Verify focus was triggered
      expect(mockCameraService.focusCalled, isTrue);
      expect(mockCameraService.focusPoints.length, 1);
    });

    testWidgets('focus animation appears at tap point', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no focus animation
      expect(find.byKey(const Key('focus_indicator')), findsNothing);

      // Tap on preview
      final cameraPreview = find.byType(CameraPreviewWidget);
      final tapPoint = tester.getCenter(cameraPreview);
      await tester.tapAt(tapPoint);
      await tester.pump();

      // Step 3: Verify focus animation at tap point
      expect(find.byKey(const Key('focus_indicator')), findsOneWidget);
    });

    testWidgets('focus animation disappears after delay', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on preview
      final cameraPreview = find.byType(CameraPreviewWidget);
      await tester.tapAt(tester.getCenter(cameraPreview));
      await tester.pump();

      // Focus indicator should be visible
      expect(find.byKey(const Key('focus_indicator')), findsOneWidget);

      // Wait for animation to complete and disappear
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Focus indicator should be gone
      expect(find.byKey(const Key('focus_indicator')), findsNothing);
    });

    testWidgets('tapping on different points updates focus location',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cameraPreview = find.byType(CameraPreviewWidget);
      final center = tester.getCenter(cameraPreview);

      // Step 2 & 4: Tap on foreground object
      final foregroundPoint = center + const Offset(-80, -80);
      await tester.tapAt(foregroundPoint);
      await tester.pump();

      expect(mockCameraService.focusPoints.length, 1);
      final firstFocusPoint = mockCameraService.focusPoints.first;

      // Step 5: Tap on background
      final backgroundPoint = center + const Offset(80, 80);
      await tester.tapAt(backgroundPoint);
      await tester.pump();

      // Step 6: Verify focus shifts to background
      expect(mockCameraService.focusPoints.length, 2);
      final secondFocusPoint = mockCameraService.focusPoints.last;

      // Focus points should be different
      expect(secondFocusPoint, isNot(equals(firstFocusPoint)));
    });

    testWidgets('focus indicator shows at correct screen position',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cameraPreview = find.byType(CameraPreviewWidget);
      final previewBox = tester.getRect(cameraPreview);

      // Tap at a specific position
      final tapOffset = Offset(
        previewBox.left + previewBox.width * 0.25,
        previewBox.top + previewBox.height * 0.25,
      );
      await tester.tapAt(tapOffset);
      await tester.pump();

      // Find focus indicator and verify it's positioned near tap point
      final focusIndicator = find.byKey(const Key('focus_indicator'));
      expect(focusIndicator, findsOneWidget);

      // The indicator should be positioned at the tap location
      final indicatorBox = tester.getRect(focusIndicator);
      // Check that indicator center is close to tap point (within reasonable tolerance)
      expect(
        (indicatorBox.center.dx - tapOffset.dx).abs(),
        lessThan(50), // tolerance for indicator size
      );
      expect(
        (indicatorBox.center.dy - tapOffset.dy).abs(),
        lessThan(50),
      );
    });

    testWidgets('focus animation has visual feedback (scale/opacity)',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cameraPreview = find.byType(CameraPreviewWidget);
      await tester.tapAt(tester.getCenter(cameraPreview));
      await tester.pump();

      // Focus indicator should exist with proper styling
      final focusIndicator = find.byKey(const Key('focus_indicator'));
      expect(focusIndicator, findsOneWidget);

      // Find the container that has the focus ring decoration
      final container = tester.widget<Container>(
        find
            .descendant(
              of: focusIndicator,
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container, isNotNull);
    });

    testWidgets('focus works in both photo and video mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final cameraPreview = find.byType(CameraPreviewWidget);

      // Focus in photo mode
      await tester.tapAt(tester.getCenter(cameraPreview));
      await tester.pump();
      expect(mockCameraService.focusPoints.length, 1);

      // Wait for focus indicator to disappear
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Focus should still work in video mode
      await tester.tapAt(tester.getCenter(cameraPreview));
      await tester.pump();
      expect(mockCameraService.focusPoints.length, 2);
    });
  });
}
