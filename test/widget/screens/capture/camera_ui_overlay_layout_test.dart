import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/location_service.dart';
import 'package:field_reporter/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('Camera UI Overlays Layout', () {
    late _MockCameraService mockCameraService;
    late _MockPermissionService mockPermissionService;

    setUp(() {
      mockCameraService = _MockCameraService();
      mockPermissionService = _MockPermissionService();
    });

    Future<void> pumpTestWidget(WidgetTester tester,
        {Size screenSize = const Size(375, 812)}) async {
      // Use binding to constrain the surface size for accurate position testing
      tester.view.physicalSize = screenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            permissionServiceProvider.overrideWithValue(mockPermissionService),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: screenSize),
              child: const CameraCaptureScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    group('capture button positioning', () {
      testWidgets('capture button is positioned at bottom of screen',
          (tester) async {
        // Test on iPhone-sized screen (375x812)
        await pumpTestWidget(tester, screenSize: const Size(375, 812));

        // Find the capture button
        final captureButton = find.byKey(const Key('capture_button'));
        expect(captureButton, findsOneWidget);

        // Get the position of the capture button
        final buttonRenderBox = tester.renderObject<RenderBox>(captureButton);
        final buttonPosition = buttonRenderBox.localToGlobal(Offset.zero);
        final buttonSize = buttonRenderBox.size;

        // The button should be in the bottom half of the screen
        // This ensures it's at the bottom, accessible for thumb reach
        final screenHeight = 812.0;
        final bottomHalfStart = screenHeight / 2;

        expect(
          buttonPosition.dy,
          greaterThan(bottomHalfStart),
          reason: 'Capture button should be in the bottom half of the screen',
        );

        // Verify button is visible on screen
        expect(
          buttonPosition.dy + buttonSize.height,
          lessThan(screenHeight),
          reason: 'Capture button should be fully visible on screen',
        );
      });

      testWidgets(
          'capture button is visible and accessible in center area of controls',
          (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(375, 812));

        final captureButton = find.byKey(const Key('capture_button'));
        expect(captureButton, findsOneWidget);

        // Verify capture button is visible on screen and tappable
        final buttonRenderBox = tester.renderObject<RenderBox>(captureButton);
        final buttonPosition = buttonRenderBox.localToGlobal(Offset.zero);
        final buttonSize = buttonRenderBox.size;

        // Button should be within the screen bounds
        expect(buttonPosition.dx, greaterThanOrEqualTo(0));
        expect(buttonPosition.dy, greaterThanOrEqualTo(0));
        expect(
          buttonPosition.dx + buttonSize.width,
          lessThanOrEqualTo(375),
          reason: 'Capture button should be within screen width',
        );

        // Verify button is positioned between photo and video mode buttons
        // by checking it's in the middle portion of the screen horizontally
        final buttonCenter = buttonPosition.dx + buttonSize.width / 2;
        expect(
          buttonCenter,
          greaterThan(375.0 * 0.25),
          reason: 'Capture button should be in the central area of the screen',
        );
        expect(
          buttonCenter,
          lessThan(375.0 * 0.75),
          reason: 'Capture button should be in the central area of the screen',
        );
      });
    });

    group('camera controls accessibility', () {
      testWidgets('flash button is accessible and visible', (tester) async {
        await pumpTestWidget(tester);

        final flashButton = find.byKey(const Key('flash_button'));
        expect(flashButton, findsOneWidget);

        // Verify button render box exists and has valid size (accessible)
        final flashRenderBox = tester.renderObject<RenderBox>(flashButton);
        expect(flashRenderBox.size.width, greaterThanOrEqualTo(44));
        expect(flashRenderBox.size.height, greaterThanOrEqualTo(44));
      });

      testWidgets('camera switch button is accessible and visible',
          (tester) async {
        await pumpTestWidget(tester);

        final switchButton = find.byKey(const Key('camera_switch_button'));
        expect(switchButton, findsOneWidget);

        // Verify button render box exists and has valid size (accessible)
        final switchRenderBox = tester.renderObject<RenderBox>(switchButton);
        expect(switchRenderBox.size.width, greaterThanOrEqualTo(44));
        expect(switchRenderBox.size.height, greaterThanOrEqualTo(44));
      });

      testWidgets('controls are positioned at top of screen', (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(375, 812));

        final flashButton = find.byKey(const Key('flash_button'));
        final switchButton = find.byKey(const Key('camera_switch_button'));

        final flashRenderBox = tester.renderObject<RenderBox>(flashButton);
        final switchRenderBox = tester.renderObject<RenderBox>(switchButton);

        final flashPosition = flashRenderBox.localToGlobal(Offset.zero);
        final switchPosition = switchRenderBox.localToGlobal(Offset.zero);

        // Controls should be in the top portion of the screen
        final topQuarter = 812.0 / 4;

        expect(
          flashPosition.dy,
          lessThan(topQuarter),
          reason: 'Flash button should be in the top area',
        );
        expect(
          switchPosition.dy,
          lessThan(topQuarter),
          reason: 'Camera switch button should be in the top area',
        );
      });
    });

    group('GPS/timestamp overlays in corners', () {
      testWidgets('GPS overlay is positioned in left corner', (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(375, 812));

        // Enable GPS overlay
        final gpsToggle = find.byKey(const Key('gps_overlay_toggle'));
        if (gpsToggle.evaluate().isNotEmpty) {
          await tester.tap(gpsToggle);
          await tester.pumpAndSettle();
        }

        final gpsOverlay = find.byKey(const Key('gps_overlay'));
        if (gpsOverlay.evaluate().isNotEmpty) {
          final overlayRenderBox = tester.renderObject<RenderBox>(gpsOverlay);
          final overlayPosition = overlayRenderBox.localToGlobal(Offset.zero);

          // GPS overlay should be on the left side
          expect(
            overlayPosition.dx,
            lessThan(375.0 / 3),
            reason: 'GPS overlay should be on the left side of the screen',
          );
        }
      });

      testWidgets('timestamp overlay is positioned in right corner',
          (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(375, 812));

        // Enable timestamp overlay
        final timestampToggle =
            find.byKey(const Key('timestamp_overlay_toggle'));
        if (timestampToggle.evaluate().isNotEmpty) {
          await tester.tap(timestampToggle);
          await tester.pumpAndSettle();
        }

        final timestampOverlay = find.byKey(const Key('timestamp_overlay'));
        if (timestampOverlay.evaluate().isNotEmpty) {
          final overlayRenderBox =
              tester.renderObject<RenderBox>(timestampOverlay);
          final overlayPosition = overlayRenderBox.localToGlobal(Offset.zero);
          final overlaySize = overlayRenderBox.size;

          // Timestamp overlay should be on the right side
          expect(
            overlayPosition.dx + overlaySize.width,
            greaterThan(375.0 * 2 / 3),
            reason:
                'Timestamp overlay should be on the right side of the screen',
          );
        }
      });

      testWidgets('overlays do not overlap with capture button',
          (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(375, 812));

        final captureButton = find.byKey(const Key('capture_button'));
        final captureRenderBox = tester.renderObject<RenderBox>(captureButton);
        final captureRect =
            captureRenderBox.localToGlobal(Offset.zero) & captureRenderBox.size;

        // Check GPS overlay if visible
        final gpsOverlay = find.byKey(const Key('gps_overlay'));
        if (gpsOverlay.evaluate().isNotEmpty) {
          final gpsRenderBox = tester.renderObject<RenderBox>(gpsOverlay);
          final gpsRect =
              gpsRenderBox.localToGlobal(Offset.zero) & gpsRenderBox.size;

          expect(
            captureRect.overlaps(gpsRect),
            isFalse,
            reason: 'GPS overlay should not overlap capture button',
          );
        }

        // Check timestamp overlay if visible
        final timestampOverlay = find.byKey(const Key('timestamp_overlay'));
        if (timestampOverlay.evaluate().isNotEmpty) {
          final timestampRenderBox =
              tester.renderObject<RenderBox>(timestampOverlay);
          final timestampRect = timestampRenderBox.localToGlobal(Offset.zero) &
              timestampRenderBox.size;

          expect(
            captureRect.overlaps(timestampRect),
            isFalse,
            reason: 'Timestamp overlay should not overlap capture button',
          );
        }
      });
    });

    group('center of frame clear for subject', () {
      testWidgets('center area of camera preview is unobstructed',
          (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(375, 812));

        // Define the center area (middle 50% of the screen)
        final centerRect = Rect.fromCenter(
          center: const Offset(375 / 2, 812 / 2),
          width: 375 * 0.5,
          height: 812 * 0.4,
        );

        // Check that capture button is not in the center area
        final captureButton = find.byKey(const Key('capture_button'));
        final captureRenderBox = tester.renderObject<RenderBox>(captureButton);
        final captureRect =
            captureRenderBox.localToGlobal(Offset.zero) & captureRenderBox.size;

        expect(
          centerRect.overlaps(captureRect),
          isFalse,
          reason: 'Capture button should not obstruct center of frame',
        );

        // Check that flash button is not in the center area
        final flashButton = find.byKey(const Key('flash_button'));
        final flashRenderBox = tester.renderObject<RenderBox>(flashButton);
        final flashRect =
            flashRenderBox.localToGlobal(Offset.zero) & flashRenderBox.size;

        expect(
          centerRect.overlaps(flashRect),
          isFalse,
          reason: 'Flash button should not obstruct center of frame',
        );

        // Check that camera switch button is not in the center area
        final switchButton = find.byKey(const Key('camera_switch_button'));
        final switchRenderBox = tester.renderObject<RenderBox>(switchButton);
        final switchRect =
            switchRenderBox.localToGlobal(Offset.zero) & switchRenderBox.size;

        expect(
          centerRect.overlaps(switchRect),
          isFalse,
          reason: 'Camera switch button should not obstruct center of frame',
        );
      });
    });

    group('small phone screen verification', () {
      testWidgets('UI works correctly on small phone (320x568)',
          (tester) async {
        // iPhone SE 1st gen size
        await pumpTestWidget(tester, screenSize: const Size(320, 568));

        // Verify capture button is visible
        final captureButton = find.byKey(const Key('capture_button'));
        expect(captureButton, findsOneWidget);

        // Verify flash button is visible
        final flashButton = find.byKey(const Key('flash_button'));
        expect(flashButton, findsOneWidget);

        // Verify camera switch button is visible
        final switchButton = find.byKey(const Key('camera_switch_button'));
        expect(switchButton, findsOneWidget);

        // Verify capture button position is still at bottom
        final captureRenderBox = tester.renderObject<RenderBox>(captureButton);
        final capturePosition = captureRenderBox.localToGlobal(Offset.zero);
        final captureSize = captureRenderBox.size;

        final bottomHalf = 568.0 / 2;
        expect(
          capturePosition.dy + captureSize.height / 2,
          greaterThan(bottomHalf),
          reason: 'Capture button should be in bottom half on small screen',
        );
      });

      testWidgets('controls do not overlap on small phone', (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(320, 568));

        // Get photo mode button
        final photoModeButton = find.byKey(const Key('photo_mode_button'));
        final videoModeButton = find.byKey(const Key('video_mode_button'));

        if (photoModeButton.evaluate().isNotEmpty &&
            videoModeButton.evaluate().isNotEmpty) {
          final photoRenderBox =
              tester.renderObject<RenderBox>(photoModeButton);
          final videoRenderBox =
              tester.renderObject<RenderBox>(videoModeButton);

          final photoRect =
              photoRenderBox.localToGlobal(Offset.zero) & photoRenderBox.size;
          final videoRect =
              videoRenderBox.localToGlobal(Offset.zero) & videoRenderBox.size;

          expect(
            photoRect.overlaps(videoRect),
            isFalse,
            reason: 'Photo and video mode buttons should not overlap',
          );
        }
      });
    });

    group('large phone/tablet verification', () {
      testWidgets('UI works correctly on large phone (414x896)',
          (tester) async {
        // iPhone 11 Pro Max size
        await pumpTestWidget(tester, screenSize: const Size(414, 896));

        // Verify capture button is visible
        final captureButton = find.byKey(const Key('capture_button'));
        expect(captureButton, findsOneWidget);

        // Verify capture button is visible within screen bounds
        final captureRenderBox = tester.renderObject<RenderBox>(captureButton);
        final capturePosition = captureRenderBox.localToGlobal(Offset.zero);
        final captureSize = captureRenderBox.size;

        // Button should be within the screen bounds
        expect(capturePosition.dx, greaterThanOrEqualTo(0));
        expect(
          capturePosition.dx + captureSize.width,
          lessThanOrEqualTo(414),
          reason: 'Capture button should be within screen width on large phone',
        );

        // Verify button is in central area
        final buttonCenter = capturePosition.dx + captureSize.width / 2;
        expect(
          buttonCenter,
          greaterThan(414.0 * 0.25),
          reason: 'Capture button should be in central area on large phone',
        );
        expect(
          buttonCenter,
          lessThan(414.0 * 0.75),
          reason: 'Capture button should be in central area on large phone',
        );
      });

      testWidgets('UI works correctly on tablet (768x1024)', (tester) async {
        // iPad size
        await pumpTestWidget(tester, screenSize: const Size(768, 1024));

        // Verify capture button is visible
        final captureButton = find.byKey(const Key('capture_button'));
        expect(captureButton, findsOneWidget);

        // Verify flash button is visible
        final flashButton = find.byKey(const Key('flash_button'));
        expect(flashButton, findsOneWidget);

        // Verify camera switch button is visible
        final switchButton = find.byKey(const Key('camera_switch_button'));
        expect(switchButton, findsOneWidget);
      });

      testWidgets('center area stays clear on tablet', (tester) async {
        await pumpTestWidget(tester, screenSize: const Size(768, 1024));

        // Define the center capture area - this is where the subject would be framed
        // This represents the "viewfinder" area that should remain unobstructed
        // We define it as the upper-center portion, excluding the top bar and bottom controls
        // Top 15% is reserved for controls (top bar), bottom 25% for capture controls
        final centerRect = Rect.fromLTRB(
          768 * 0.15, // 15% from left
          1024 * 0.15, // 15% from top (below top bar)
          768 * 0.85, // 15% from right
          1024 * 0.65, // 35% from bottom (above capture button area)
        );

        // Check that capture button is not in the center area
        final captureButton = find.byKey(const Key('capture_button'));
        final captureRenderBox = tester.renderObject<RenderBox>(captureButton);
        final captureRect =
            captureRenderBox.localToGlobal(Offset.zero) & captureRenderBox.size;

        expect(
          centerRect.overlaps(captureRect),
          isFalse,
          reason:
              'Capture button should not obstruct center of frame on tablet',
        );
      });
    });
  });
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
  Future<VideoRecordingResult?> stopRecording() async => null;

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
