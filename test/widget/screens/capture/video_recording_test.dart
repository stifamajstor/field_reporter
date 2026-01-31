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

/// Mock camera service for testing video recording.
class MockCameraService implements CameraService {
  bool _isRecording = false;
  int _recordingDurationSeconds = 0;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;

  bool get isRecording => _isRecording;

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
  Future<void> openCameraForVideo() async {}

  @override
  Future<String?> capturePhoto({double? compassHeading}) async {
    return '/path/to/photo.jpg';
  }

  @override
  Future<void> startRecording() async {
    _isRecording = true;
    _recordingDurationSeconds = 0;
  }

  @override
  Future<VideoRecordingResult?> stopRecording() async {
    _isRecording = false;
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

  void simulateRecordingTime(int seconds) {
    _recordingDurationSeconds = seconds;
  }
}

void main() {
  group('User can record video', () {
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

    testWidgets('can switch to video mode and UI changes', (tester) async {
      // Step 1: Open camera and switch to video mode
      // Step 2: Verify video mode UI (record button changes)
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should be in photo mode by default
      expect(find.byKey(const Key('capture_button')), findsOneWidget);
      expect(find.byKey(const Key('video_mode_button')), findsOneWidget);

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Verify video mode - record button should be red/different
      expect(find.byKey(const Key('record_button')), findsOneWidget);
      // Capture button should be hidden in video mode
      expect(find.byKey(const Key('capture_button')), findsNothing);
    });

    testWidgets('tapping record starts recording with indicator and timer',
        (tester) async {
      // Step 3: Tap record button
      // Step 4: Verify recording indicator appears
      // Step 5: Verify timer counting up
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Tap record button to start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify recording indicator appears
      expect(find.byKey(const Key('recording_indicator')), findsOneWidget);

      // Verify timer is visible and starts at 00:00
      expect(find.byKey(const Key('recording_timer')), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);

      // Wait and verify timer updates
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:01'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:02'), findsOneWidget);
    });

    testWidgets('tapping stop ends recording and shows preview',
        (tester) async {
      // Step 6: Wait a few seconds
      // Step 7: Tap stop button
      // Step 8: Verify video preview plays automatically
      // Step 9: Verify accept/retake options visible
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Simulate some recording time
      await tester.pump(const Duration(seconds: 3));

      // The record button becomes stop button while recording
      expect(find.byKey(const Key('stop_button')), findsOneWidget);

      // Stop recording
      mockCameraService.simulateRecordingTime(3);
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Should navigate to video preview screen
      expect(find.byType(VideoPreviewScreen), findsOneWidget);

      // Verify video preview is playing (autoPlay)
      expect(find.byKey(const Key('video_player')), findsOneWidget);

      // Verify accept/retake options are visible
      expect(find.byKey(const Key('accept_video_button')), findsOneWidget);
      expect(find.byKey(const Key('retake_video_button')), findsOneWidget);
    });

    testWidgets('recording indicator is red dot', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode and start recording
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Find the recording indicator
      final indicatorFinder = find.byKey(const Key('recording_indicator'));
      expect(indicatorFinder, findsOneWidget);

      // Verify it's a red indicator (circle with red color)
      final indicator = tester.widget<Container>(indicatorFinder);
      final decoration = indicator.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
      expect(decoration.shape, BoxShape.circle);
    });
  });
}
