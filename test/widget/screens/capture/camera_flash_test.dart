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

/// Mock camera service for testing flash mode.
class MockCameraService implements CameraService {
  bool _isInitialized = false;
  bool _isPreviewActive = false;
  CameraLensDirection _currentLensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  bool _flashFiredOnCapture = false;

  bool get isInitialized => _isInitialized;
  bool get isPreviewActive => _isPreviewActive;
  FlashMode get flashMode => _flashMode;
  bool get flashFiredOnCapture => _flashFiredOnCapture;

  @override
  Future<void> openCamera() async {
    _isInitialized = true;
    _isPreviewActive = true;
    _currentLensDirection = CameraLensDirection.back;
    _flashMode = FlashMode.auto;
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
    // Simulate flash firing when flash is on
    if (_flashMode == FlashMode.on) {
      _flashFiredOnCapture = true;
    }
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
  Future<void> setZoomLevel(double zoom) async {}

  @override
  double get currentZoomLevel => 1.0;

  @override
  double get minZoomLevel => 1.0;

  @override
  double get maxZoomLevel => 10.0;

  @override
  Future<void> setFocusPoint(double x, double y) async {}
}

void main() {
  group('User can toggle flash mode', () {
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

    testWidgets('flash mode indicator is visible when camera opens',
        (tester) async {
      // Step 1: Open camera
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Verify flash mode indicator visible
      expect(find.byKey(const Key('flash_button')), findsOneWidget);
    });

    testWidgets('flash button shows auto icon by default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Default mode should be auto
      expect(mockCameraService.flashMode, FlashMode.auto);

      // Flash button should show auto icon
      final flashButton = find.byKey(const Key('flash_button'));
      expect(flashButton, findsOneWidget);

      final autoIcon = find.descendant(
        of: flashButton,
        matching: find.byIcon(Icons.flash_auto),
      );
      expect(autoIcon, findsOneWidget);
    });

    testWidgets(
        'tapping flash button cycles through modes: auto -> on -> off -> auto',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially auto
      expect(mockCameraService.flashMode, FlashMode.auto);

      // Step 3: Tap flash button
      await tester.tap(find.byKey(const Key('flash_button')));
      await tester.pumpAndSettle();

      // Step 4: Verify mode changes to on
      expect(mockCameraService.flashMode, FlashMode.on);

      // Step 5: Verify icon updates - should show flash_on
      expect(
        find.descendant(
          of: find.byKey(const Key('flash_button')),
          matching: find.byIcon(Icons.flash_on),
        ),
        findsOneWidget,
      );

      // Tap again -> off
      await tester.tap(find.byKey(const Key('flash_button')));
      await tester.pumpAndSettle();
      expect(mockCameraService.flashMode, FlashMode.off);

      // Verify icon updates - should show flash_off
      expect(
        find.descendant(
          of: find.byKey(const Key('flash_button')),
          matching: find.byIcon(Icons.flash_off),
        ),
        findsOneWidget,
      );

      // Tap again -> back to auto
      await tester.tap(find.byKey(const Key('flash_button')));
      await tester.pumpAndSettle();
      expect(mockCameraService.flashMode, FlashMode.auto);

      // Verify icon updates - should show flash_auto
      expect(
        find.descendant(
          of: find.byKey(const Key('flash_button')),
          matching: find.byIcon(Icons.flash_auto),
        ),
        findsOneWidget,
      );
    });

    testWidgets('flash fires during capture when flash mode is on',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Set flash to on
      await tester.tap(find.byKey(const Key('flash_button')));
      await tester.pumpAndSettle();
      expect(mockCameraService.flashMode, FlashMode.on);

      // Step 6: Capture photo with flash on
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Step 7: Verify flash fires during capture
      expect(mockCameraService.flashFiredOnCapture, isTrue);
    });

    testWidgets('flash button has correct accessibility semantics',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            cameraServiceProvider.overrideWithValue(mockCameraService),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Semantics(
                child: const CameraCaptureScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Semantics widget wrapping the flash button
      final semanticsWidget = find.ancestor(
        of: find.byKey(const Key('flash_button')),
        matching: find.byType(Semantics),
      );
      expect(semanticsWidget, findsWidgets);
    });
  });
}
