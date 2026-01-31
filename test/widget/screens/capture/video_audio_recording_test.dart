import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/presentation/video_preview_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/location_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for testing audio recording.
class MockPermissionService implements PermissionService {
  PermissionStatus _cameraStatus = PermissionStatus.granted;
  PermissionStatus _microphoneStatus = PermissionStatus.granted;
  bool microphonePermissionChecked = false;
  bool microphonePermissionRequested = false;

  void setCameraStatus(PermissionStatus status) {
    _cameraStatus = status;
  }

  void setMicrophoneStatus(PermissionStatus status) {
    _microphoneStatus = status;
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
    microphonePermissionChecked = true;
    return _microphoneStatus;
  }

  @override
  Future<PermissionStatus> requestMicrophonePermission() async {
    microphonePermissionRequested = true;
    return _microphoneStatus;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

/// Mock camera service for testing video recording with audio.
class MockCameraService implements CameraService {
  bool _isRecording = false;
  int _recordingDurationSeconds = 0;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  bool _enableAudio = true;
  bool startRecordingCalled = false;
  bool? recordingHasAudio;

  bool get isRecording => _isRecording;
  bool get enableAudio => _enableAudio;

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
  Future<void> openCameraForVideo({bool enableAudio = true}) async {
    _enableAudio = enableAudio;
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
  Future<void> startRecording({bool enableAudio = true}) async {
    startRecordingCalled = true;
    recordingHasAudio = enableAudio;
    _isRecording = true;
    _recordingDurationSeconds = 0;
  }

  @override
  Future<VideoRecordingResult?> stopRecording() async {
    _isRecording = false;
    return VideoRecordingResult(
      path: '/path/to/video.mp4',
      durationSeconds: _recordingDurationSeconds,
      hasAudio: recordingHasAudio ?? true,
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
  group('Video recording captures audio', () {
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

    testWidgets('checks microphone permission when switching to video mode',
        (tester) async {
      // Step 1: Ensure microphone permission granted
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Open camera in video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Verify microphone permission was checked
      expect(mockPermissionService.microphonePermissionChecked, isTrue);
    });

    testWidgets(
        'starts video recording with audio enabled when permission granted',
        (tester) async {
      // Step 1: Ensure microphone permission granted
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Open camera in video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Step 3: Start recording while speaking
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify recording started with audio enabled
      expect(mockCameraService.startRecordingCalled, isTrue);
      expect(mockCameraService.recordingHasAudio, isTrue);
    });

    testWidgets('video preview shows audio indicator when audio is captured',
        (tester) async {
      // Step 1: Ensure microphone permission granted
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Open camera in video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Step 3: Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Simulate recording time
      await tester.pump(const Duration(seconds: 2));
      mockCameraService.simulateRecordingTime(2);

      // Step 4: Stop recording
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Step 5: Play back video preview
      expect(find.byType(VideoPreviewScreen), findsOneWidget);
      expect(find.byKey(const Key('video_player')), findsOneWidget);

      // Step 6: Verify audio is captured and audible (audio indicator visible)
      expect(find.byKey(const Key('audio_indicator')), findsOneWidget);
    });

    testWidgets('requests microphone permission if not granted',
        (tester) async {
      // Microphone permission not granted
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Should request microphone permission
      expect(mockPermissionService.microphonePermissionRequested, isTrue);
    });

    testWidgets(
        'video recorded without audio when microphone permission denied',
        (tester) async {
      // Microphone permission permanently denied
      mockPermissionService
          .setMicrophoneStatus(PermissionStatus.permanentlyDenied);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Recording should still work but without audio
      expect(mockCameraService.startRecordingCalled, isTrue);
      expect(mockCameraService.recordingHasAudio, isFalse);
    });
  });
}
