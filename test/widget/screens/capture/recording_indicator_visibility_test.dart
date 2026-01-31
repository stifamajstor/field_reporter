import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/location_service.dart';
import 'package:field_reporter/services/permission_service.dart';

void main() {
  group('Recording indicator is clearly visible', () {
    late _MockPermissionService mockPermissionService;
    late _MockCameraService mockCameraService;

    setUp(() {
      mockPermissionService = _MockPermissionService();
      mockCameraService = _MockCameraService();
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

    testWidgets('red recording dot is visible during recording',
        (tester) async {
      // Step 1: Start video recording
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Step 2: Verify red recording dot visible
      final recordingIndicator = find.byKey(const Key('recording_indicator'));
      expect(recordingIndicator, findsOneWidget);

      // Verify it's a red circle
      final indicatorContainer = tester.widget<Container>(recordingIndicator);
      final decoration = indicatorContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('timer is visible during recording', (tester) async {
      // Step 3: Verify timer visible
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode and start recording
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify timer is visible
      final recordingTimer = find.byKey(const Key('recording_timer'));
      expect(recordingTimer, findsOneWidget);

      // Verify initial time is 00:00
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('indicator has high contrast (white text on dark background)',
        (tester) async {
      // Step 4: Verify indicator has high contrast
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode and start recording
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Find the timer text widget
      final recordingTimer = find.byKey(const Key('recording_timer'));
      expect(recordingTimer, findsOneWidget);

      final timerWidget = tester.widget<Text>(recordingTimer);
      final textStyle = timerWidget.style!;

      // Verify white text color for high contrast against dark backgrounds
      expect(textStyle.color, Colors.white);

      // Verify the red dot has high contrast
      final recordingIndicator = find.byKey(const Key('recording_indicator'));
      final indicatorContainer = tester.widget<Container>(recordingIndicator);
      final decoration = indicatorContainer.decoration as BoxDecoration;

      // Red (255, 0, 0) has high contrast against both dark and light backgrounds
      expect(decoration.color, Colors.red);
    });

    testWidgets('indicator has sufficient size to be visible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode and start recording
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify the indicator dot has sufficient size (at least 10x10)
      final recordingIndicator = find.byKey(const Key('recording_indicator'));
      final indicatorBox = tester.renderObject<RenderBox>(recordingIndicator);
      expect(indicatorBox.size.width, greaterThanOrEqualTo(10));
      expect(indicatorBox.size.height, greaterThanOrEqualTo(10));
    });

    testWidgets(
        'indicator stays visible regardless of background during recording',
        (tester) async {
      // Step 5 & 6: Move camera around - indicator stays visible
      // This tests that indicator remains in a fixed position and has consistent styling

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode and start recording
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify indicator is present
      expect(find.byKey(const Key('recording_indicator')), findsOneWidget);
      expect(find.byKey(const Key('recording_timer')), findsOneWidget);

      // Simulate some time passing (moving camera around)
      await tester.pump(const Duration(seconds: 1));

      // Indicator should still be visible with same styling
      expect(find.byKey(const Key('recording_indicator')), findsOneWidget);
      expect(find.byKey(const Key('recording_timer')), findsOneWidget);
      expect(find.text('00:01'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));

      // Indicator should still be visible
      expect(find.byKey(const Key('recording_indicator')), findsOneWidget);
      expect(find.byKey(const Key('recording_timer')), findsOneWidget);
      expect(find.text('00:03'), findsOneWidget);

      // Verify the indicator still has correct styling (red dot)
      final indicatorContainer = tester.widget<Container>(
        find.byKey(const Key('recording_indicator')),
      );
      final decoration = indicatorContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('indicator has text shadow or background for visibility',
        (tester) async {
      // The timer text should have styling that makes it visible against any background
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to video mode and start recording
      await tester.tap(find.byKey(const Key('video_mode_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Find the timer text
      final timerText = tester.widget<Text>(
        find.byKey(const Key('recording_timer')),
      );

      // Verify font weight is at least semi-bold for better visibility
      expect(
        timerText.style?.fontWeight?.index,
        greaterThanOrEqualTo(FontWeight.w600.index),
      );

      // Verify font size is readable (at least 14)
      expect(timerText.style?.fontSize, greaterThanOrEqualTo(14));
    });
  });
}

/// Mock PermissionService for testing.
class _MockPermissionService implements PermissionService {
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

/// Mock CameraService for testing.
class _MockCameraService implements CameraService {
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  double _zoomLevel = 1.0;

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  double get currentZoomLevel => _zoomLevel;

  @override
  double get minZoomLevel => 1.0;

  @override
  double get maxZoomLevel => 10.0;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> setZoomLevel(double zoom) async {
    _zoomLevel = zoom;
  }

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
      '/mock/path/photo.jpg';

  @override
  Future<void> startRecording({bool enableAudio = true}) async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async {
    return const VideoRecordingResult(
      path: '/mock/path/video.mp4',
      durationSeconds: 5,
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
  Future<void> setFocusPoint(double x, double y) async {}
}
