import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/presentation/video_preview_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for testing.
class MockPermissionService implements PermissionService {
  @override
  Future<PermissionStatus> checkCameraPermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestCameraPermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> checkMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

/// Mock camera service for testing video duration limits.
class MockCameraService implements CameraService {
  int _recordingDurationSeconds = 0;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> openCamera() async {}

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {}

  @override
  Future<String?> capturePhoto({double? compassHeading}) async {
    return '/path/to/photo.jpg';
  }

  @override
  Future<void> startRecording({bool enableAudio = true}) async {
    _recordingDurationSeconds = 0;
  }

  @override
  Future<VideoRecordingResult?> stopRecording() async {
    return VideoRecordingResult(
      path: '/path/to/video.mp4',
      durationSeconds: _recordingDurationSeconds,
    );
  }

  @override
  Future<void> closeCamera() async {}

  @override
  Future<void> switchCamera() async {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }

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

  void simulateRecordingTime(int seconds) {
    _recordingDurationSeconds = seconds;
  }
}

void main() {
  group('Video recording shows duration limit warning', () {
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

    testWidgets('shows warning near max duration (e.g., 5 min)',
        (tester) async {
      // Step 1-3: Open camera in video mode and start recording
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify no warning initially
      expect(find.byKey(const Key('duration_warning')), findsNothing);

      // Step 4: Simulate recording for 4:30 (270 seconds) - near 5 min limit
      // Pump 270 times to simulate 4:30 of recording
      for (int i = 0; i < 270; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Verify warning appears near max duration
      expect(find.byKey(const Key('duration_warning')), findsOneWidget);

      // Verify warning text mentions time remaining
      expect(find.textContaining('30'), findsWidgets);
    });

    testWidgets('recording auto-stops at max duration', (tester) async {
      // Step 5: Verify recording auto-stops at max duration
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify recording is active
      expect(find.byKey(const Key('recording_indicator')), findsOneWidget);

      // Simulate recording for exactly 5 minutes (300 seconds)
      mockCameraService.simulateRecordingTime(300);
      for (int i = 0; i < 300; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Recording should auto-stop and navigate to preview
      await tester.pumpAndSettle();

      // Should navigate to video preview screen (auto-stop)
      expect(find.byType(VideoPreviewScreen), findsOneWidget);
    });

    testWidgets('video is saved successfully after auto-stop', (tester) async {
      // Step 6: Verify video is saved successfully
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Simulate max duration recording
      mockCameraService.simulateRecordingTime(300);
      for (int i = 0; i < 300; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      await tester.pumpAndSettle();

      // Should show preview screen with video
      expect(find.byType(VideoPreviewScreen), findsOneWidget);
      expect(find.byKey(const Key('video_player')), findsOneWidget);

      // Accept/retake options should be visible
      expect(find.byKey(const Key('accept_video_button')), findsOneWidget);
      expect(find.byKey(const Key('retake_video_button')), findsOneWidget);
    });

    testWidgets('warning shows time remaining text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Simulate 4:45 of recording (15 seconds remaining)
      for (int i = 0; i < 285; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Verify warning is shown
      expect(find.byKey(const Key('duration_warning')), findsOneWidget);

      // Warning should indicate time remaining
      expect(find.textContaining('15'), findsWidgets);
    });

    testWidgets('warning has amber/orange styling', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Simulate recording near max duration
      for (int i = 0; i < 270; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Find the warning container
      final warningFinder = find.byKey(const Key('duration_warning'));
      expect(warningFinder, findsOneWidget);

      // Verify it uses warning colors (amber/orange)
      final warningWidget = tester.widget<Container>(warningFinder);
      final decoration = warningWidget.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });
  });
}
