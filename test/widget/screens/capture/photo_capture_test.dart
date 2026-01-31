import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/camera_capture_screen.dart';
import 'package:field_reporter/features/capture/presentation/photo_preview_screen.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for testing.
class MockPermissionService implements PermissionService {
  PermissionStatus _cameraStatus = PermissionStatus.granted;

  void setCameraStatus(PermissionStatus status) {
    _cameraStatus = status;
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async => _cameraStatus;

  @override
  Future<PermissionStatus> requestCameraPermission() async => _cameraStatus;

  @override
  Future<bool> openAppSettings() async => true;
}

/// Mock camera service for testing photo capture flow.
class MockCameraService implements CameraService {
  bool _isOpen = false;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  bool capturePhotoCalled = false;
  String? capturedPhotoPath;
  bool shouldShowShutterAnimation = true;

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> openCamera() async {
    _isOpen = true;
  }

  @override
  Future<void> openCameraForVideo() async {
    _isOpen = true;
  }

  @override
  Future<String?> capturePhoto() async {
    capturePhotoCalled = true;
    capturedPhotoPath = '/test/path/captured_photo.jpg';
    return capturedPhotoPath;
  }

  @override
  Future<void> startRecording() async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async => null;

  @override
  Future<void> closeCamera() async {
    _isOpen = false;
  }

  @override
  Future<void> switchCamera() async {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }
}

void main() {
  group('User can capture a photo', () {
    late MockPermissionService mockPermissionService;
    late MockCameraService mockCameraService;
    late List<MethodCall> hapticCalls;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockCameraService = MockCameraService();
      hapticCalls = [];

      // Mock haptic feedback
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(methodCall);
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          cameraServiceProvider.overrideWithValue(mockCameraService),
        ],
        child: MaterialApp(
          home: const CameraCaptureScreen(),
          routes: {
            '/photo_preview': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as PhotoPreviewArguments;
              return PhotoPreviewScreen(arguments: args);
            },
          },
        ),
      );
    }

    testWidgets('opens camera in photo mode', (tester) async {
      // Step 1: Open camera in photo mode
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Camera preview should be visible
      expect(find.byType(CameraPreviewWidget), findsOneWidget);
      // Capture button should be visible for photo mode
      expect(find.byKey(const Key('capture_button')), findsOneWidget);
    });

    testWidgets('tap capture button triggers photo capture', (tester) async {
      // Step 2: Frame the subject (preview visible)
      // Step 3: Tap capture button
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify capture button exists
      final captureButton = find.byKey(const Key('capture_button'));
      expect(captureButton, findsOneWidget);

      // Tap the capture button
      await tester.tap(captureButton);
      await tester.pump();

      // Verify capture was triggered
      expect(mockCameraService.capturePhotoCalled, isTrue);

      // Pump to complete timers
      await tester.pumpAndSettle();
    });

    testWidgets('shutter animation plays on capture', (tester) async {
      // Step 4: Verify shutter animation plays
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap capture button
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pump();

      // Shutter animation should be visible (flash overlay)
      expect(find.byKey(const Key('shutter_animation')), findsOneWidget);

      // Let animation complete
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('haptic feedback triggers on capture', (tester) async {
      // Step 5: Verify haptic feedback
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap capture button
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pump();

      // Verify haptic feedback was triggered
      expect(hapticCalls, isNotEmpty);

      // Pump to complete timers
      await tester.pumpAndSettle();
    });

    testWidgets('captured photo preview appears after capture', (tester) async {
      // Step 6: Verify captured photo preview appears
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap capture button
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      // Should navigate to photo preview screen
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
    });

    testWidgets('accept and retake options visible on preview', (tester) async {
      // Step 7: Verify accept/retake options visible
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap capture button
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      // Accept and retake buttons should be visible
      expect(find.byKey(const Key('accept_photo_button')), findsOneWidget);
      expect(find.byKey(const Key('retake_photo_button')), findsOneWidget);
    });

    testWidgets('full capture flow from preview to accept/retake',
        (tester) async {
      // Full acceptance criteria test
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Camera in photo mode
      expect(find.byType(CameraPreviewWidget), findsOneWidget);

      // Step 2: Preview visible (framing subject)
      expect(find.byKey(const Key('capture_button')), findsOneWidget);

      // Step 3: Tap capture
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pump();

      // Step 4: Shutter animation
      expect(find.byKey(const Key('shutter_animation')), findsOneWidget);

      // Step 5: Haptic feedback
      expect(hapticCalls, isNotEmpty);

      await tester.pumpAndSettle();

      // Step 6: Photo preview
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);

      // Step 7: Accept/retake visible
      expect(find.byKey(const Key('accept_photo_button')), findsOneWidget);
      expect(find.byKey(const Key('retake_photo_button')), findsOneWidget);
    });
  });
}
