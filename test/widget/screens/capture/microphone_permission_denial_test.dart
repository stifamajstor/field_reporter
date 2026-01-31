import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/presentation/voice_memo_screen.dart';
import 'package:field_reporter/services/audio_recorder_service.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/location_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for testing microphone permission denial.
class MockPermissionService implements PermissionService {
  PermissionStatus _microphoneStatus = PermissionStatus.denied;
  PermissionStatus _cameraStatus = PermissionStatus.granted;
  bool openAppSettingsCalled = false;

  void setMicrophoneStatus(PermissionStatus status) {
    _microphoneStatus = status;
  }

  void setCameraStatus(PermissionStatus status) {
    _cameraStatus = status;
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async => _cameraStatus;

  @override
  Future<PermissionStatus> requestCameraPermission() async => _cameraStatus;

  @override
  Future<PermissionStatus> checkMicrophonePermission() async =>
      _microphoneStatus;

  @override
  Future<PermissionStatus> requestMicrophonePermission() async =>
      _microphoneStatus;

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

/// Mock audio recorder service for testing.
class MockAudioRecorderService implements AudioRecorderService {
  @override
  Future<void> startRecording() async {}

  @override
  Future<AudioRecordingResult?> stopRecording() async => null;

  @override
  Future<void> startPlayback(String path) async {}

  @override
  Future<void> pausePlayback() async {}

  @override
  Future<void> resumePlayback() async {}

  @override
  Future<void> stopPlayback() async {}

  @override
  void setAmplitudeListener(void Function(List<double>)? listener) {}

  @override
  void setPositionListener(void Function(Duration)? listener) {}

  @override
  void setCompletionListener(void Function()? listener) {}

  @override
  void setPlaybackWaveformListener(void Function(List<double>)? listener) {}

  @override
  List<double> get recordedWaveform => [];

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Future<void> dispose() async {}
}

void main() {
  group('Microphone permission denial shows clear message', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;
    late MockAudioRecorderService mockAudioRecorderService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
      mockAudioRecorderService = MockAudioRecorderService();
    });

    Widget createVoiceMemoTestWidget() {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          audioRecorderServiceProvider
              .overrideWithValue(mockAudioRecorderService),
        ],
        child: const MaterialApp(
          home: VoiceMemoScreen(),
        ),
      );
    }

    Widget createCameraTestWidget() {
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

    testWidgets(
        'voice memo screen shows error message when microphone permission is denied',
        (tester) async {
      // Step 1: Deny microphone permission
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      // Step 2: Attempt to record voice memo
      await tester.pumpWidget(createVoiceMemoTestWidget());
      await tester.pumpAndSettle();

      // Step 3: Verify error message explaining permission needed
      expect(
        find.text('Microphone Permission Required'),
        findsOneWidget,
      );
      expect(
        find.textContaining('allow microphone access'),
        findsOneWidget,
      );
    });

    testWidgets(
        'voice memo screen shows open settings button when permanently denied',
        (tester) async {
      // Step 1: Deny microphone permission permanently
      mockPermissionService
          .setMicrophoneStatus(PermissionStatus.permanentlyDenied);

      // Step 2: Attempt to record voice memo
      await tester.pumpWidget(createVoiceMemoTestWidget());
      await tester.pumpAndSettle();

      // Tap grant permission to trigger permanently denied flow
      final grantButton = find.text('Grant Permission');
      expect(grantButton, findsOneWidget);
      await tester.tap(grantButton);
      await tester.pumpAndSettle();

      // Verify it opens app settings for permanently denied
      expect(mockPermissionService.openAppSettingsCalled, isTrue);
    });

    testWidgets(
        'video recording shows warning that video will have no audio when mic denied',
        (tester) async {
      // Camera permission granted, microphone denied
      mockPermissionService.setCameraStatus(PermissionStatus.granted);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      // Step 4: Attempt to record video
      await tester.pumpWidget(createCameraTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode (this triggers microphone permission check)
      final videoModeButton = find.byKey(const Key('video_mode_button'));
      expect(videoModeButton, findsOneWidget);
      await tester.tap(videoModeButton);
      await tester.pumpAndSettle();

      // Step 5: Verify warning that video will have no audio
      expect(
        find.byKey(const Key('no_audio_warning')),
        findsOneWidget,
      );
      expect(
        find.textContaining('no audio'),
        findsOneWidget,
      );
    });

    testWidgets(
        'video mode shows option to proceed without audio or fix permissions',
        (tester) async {
      // Camera permission granted, microphone denied
      mockPermissionService.setCameraStatus(PermissionStatus.granted);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      await tester.pumpWidget(createCameraTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      final videoModeButton = find.byKey(const Key('video_mode_button'));
      await tester.tap(videoModeButton);
      await tester.pumpAndSettle();

      // Step 6: Verify option to proceed without audio or fix permissions
      expect(
        find.byKey(const Key('proceed_without_audio_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fix_permissions_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping fix permissions opens app settings', (tester) async {
      // Camera permission granted, microphone denied
      mockPermissionService.setCameraStatus(PermissionStatus.granted);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      await tester.pumpWidget(createCameraTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      final videoModeButton = find.byKey(const Key('video_mode_button'));
      await tester.tap(videoModeButton);
      await tester.pumpAndSettle();

      // Tap fix permissions button
      final fixPermissionsButton =
          find.byKey(const Key('fix_permissions_button'));
      expect(fixPermissionsButton, findsOneWidget);
      await tester.tap(fixPermissionsButton);
      await tester.pumpAndSettle();

      // Verify it opens app settings
      expect(mockPermissionService.openAppSettingsCalled, isTrue);
    });

    testWidgets('tapping proceed without audio allows recording',
        (tester) async {
      // Camera permission granted, microphone denied
      mockPermissionService.setCameraStatus(PermissionStatus.granted);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      await tester.pumpWidget(createCameraTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      final videoModeButton = find.byKey(const Key('video_mode_button'));
      await tester.tap(videoModeButton);
      await tester.pumpAndSettle();

      // Tap proceed without audio
      final proceedButton =
          find.byKey(const Key('proceed_without_audio_button'));
      expect(proceedButton, findsOneWidget);
      await tester.tap(proceedButton);
      await tester.pumpAndSettle();

      // Verify warning is dismissed and record button is shown
      expect(find.byKey(const Key('no_audio_warning')), findsNothing);
      expect(find.byKey(const Key('record_button')), findsOneWidget);
    });
  });
}
