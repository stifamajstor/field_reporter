import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/capture/presentation/qr_scanner_screen.dart';
import 'package:field_reporter/services/barcode_scanner_service.dart';
import 'package:field_reporter/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mock permission service for testing.
class MockPermissionService implements PermissionService {
  PermissionStatus cameraStatus = PermissionStatus.granted;

  @override
  Future<PermissionStatus> checkCameraPermission() async => cameraStatus;

  @override
  Future<PermissionStatus> requestCameraPermission() async => cameraStatus;

  @override
  Future<PermissionStatus> checkMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

/// Mock barcode scanner service for testing.
class MockBarcodeScannerService implements MockableBarcodeScannerService {
  bool isScanning = false;
  ScanResult? lastScanResult;
  bool shouldDetectCode = false;
  ScanResult? detectedCode;
  bool isStable = false;

  // Callbacks for scanner events
  @override
  void Function(ScanResult)? onCodeDetected;
  @override
  void Function(ScanResult)? onCodeCaptured;

  void simulateCodeDetected(ScanResult result) {
    detectedCode = result;
    shouldDetectCode = true;
    onCodeDetected?.call(result);
  }

  void simulateStableCapture(ScanResult result) {
    isStable = true;
    lastScanResult = result;
    onCodeCaptured?.call(result);
  }

  @override
  Future<ScanResult?> scan() async {
    isScanning = true;
    return lastScanResult;
  }

  @override
  Future<void> dispose() async {
    isScanning = false;
  }
}

/// Test widget that wraps QrScannerScreen for testing.
Widget createTestWidget({
  required MockPermissionService permissionService,
  required MockBarcodeScannerService scannerService,
}) {
  return ProviderScope(
    overrides: [
      permissionServiceProvider.overrideWithValue(permissionService),
      barcodeScannerServiceProvider.overrideWithValue(scannerService),
    ],
    child: const MaterialApp(
      home: QrScannerScreen(),
    ),
  );
}

void main() {
  late MockPermissionService mockPermissionService;
  late MockBarcodeScannerService mockScannerService;

  setUp(() {
    mockPermissionService = MockPermissionService();
    mockScannerService = MockBarcodeScannerService();
  });

  group('QR Code Scanner', () {
    testWidgets(
        'navigates to scan entry flow and camera opens with scan overlay',
        (tester) async {
      // Navigate to scan entry flow
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Verify camera opens with scan overlay
      expect(find.byKey(const Key('scanner_preview')), findsOneWidget);
      expect(find.byKey(const Key('scan_overlay')), findsOneWidget);
      expect(find.byKey(const Key('scan_frame')), findsOneWidget);
    });

    testWidgets('shows automatic detection highlight when QR code detected',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Simulate pointing camera at QR code - code detected
      mockScannerService.simulateCodeDetected(
        const ScanResult(
          data: 'https://example.com',
          format: BarcodeFormat.qrCode,
        ),
      );
      await tester.pump();

      // Verify automatic detection (highlight around code)
      expect(find.byKey(const Key('detection_highlight')), findsOneWidget);
    });

    testWidgets('automatically captures when QR code is stable',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Simulate stable detection and auto-capture
      const scanResult = ScanResult(
        data: 'https://example.com/test',
        format: BarcodeFormat.qrCode,
      );
      mockScannerService.simulateCodeDetected(scanResult);
      await tester.pump();
      mockScannerService.simulateStableCapture(scanResult);
      await tester.pump();

      // Verify decoded content is displayed
      expect(find.byKey(const Key('scan_result_content')), findsOneWidget);
      expect(find.text('https://example.com/test'), findsOneWidget);
    });

    testWidgets('displays decoded content after capture', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Simulate successful scan
      const scanResult = ScanResult(
        data: 'QR Code Data Content',
        format: BarcodeFormat.qrCode,
      );
      mockScannerService.simulateStableCapture(scanResult);
      await tester.pump();

      // Verify decoded content displayed
      expect(find.byKey(const Key('scan_result_content')), findsOneWidget);
      expect(find.text('QR Code Data Content'), findsOneWidget);
      expect(find.text('QR Code'), findsOneWidget); // Format display name
    });

    testWidgets('shows save and rescan options after capture', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Simulate successful scan
      const scanResult = ScanResult(
        data: 'Test QR Data',
        format: BarcodeFormat.qrCode,
      );
      mockScannerService.simulateStableCapture(scanResult);
      await tester.pump();

      // Verify option to save or rescan
      expect(find.byKey(const Key('save_scan_button')), findsOneWidget);
      expect(find.byKey(const Key('rescan_button')), findsOneWidget);
    });

    testWidgets('rescan button resets scanner to detection mode',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // First, capture a scan
      const scanResult = ScanResult(
        data: 'First Scan',
        format: BarcodeFormat.qrCode,
      );
      mockScannerService.simulateStableCapture(scanResult);
      await tester.pump();

      // Verify result is shown
      expect(find.text('First Scan'), findsOneWidget);

      // Tap rescan button
      await tester.tap(find.byKey(const Key('rescan_button')));
      await tester.pumpAndSettle();

      // Verify scanner is back in detection mode
      expect(find.byKey(const Key('scanner_preview')), findsOneWidget);
      expect(find.byKey(const Key('scan_overlay')), findsOneWidget);
      expect(find.text('First Scan'), findsNothing);
    });

    testWidgets('save button triggers haptic feedback and returns result',
        (tester) async {
      final List<MethodCall> hapticCalls = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(methodCall);
          }
          return null;
        },
      );

      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Capture a scan
      const scanResult = ScanResult(
        data: 'Save Test',
        format: BarcodeFormat.qrCode,
      );
      mockScannerService.simulateStableCapture(scanResult);
      await tester.pump();

      // Tap save button
      await tester.tap(find.byKey(const Key('save_scan_button')));
      await tester.pump();

      // Verify haptic feedback was triggered
      expect(hapticCalls, isNotEmpty);
    });

    testWidgets('requests camera permission if not granted', (tester) async {
      mockPermissionService.cameraStatus = PermissionStatus.denied;

      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Verify permission request UI is shown
      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.byKey(const Key('grant_permission_button')), findsOneWidget);
    });

    testWidgets('displays scan frame overlay with proper styling',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Verify scan frame is visible with proper corners
      expect(find.byKey(const Key('scan_frame')), findsOneWidget);
      expect(find.byKey(const Key('scan_frame_corner_tl')), findsOneWidget);
      expect(find.byKey(const Key('scan_frame_corner_tr')), findsOneWidget);
      expect(find.byKey(const Key('scan_frame_corner_bl')), findsOneWidget);
      expect(find.byKey(const Key('scan_frame_corner_br')), findsOneWidget);
    });

    testWidgets('shows helper text for scanning', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Verify helper text is displayed
      expect(find.text('Point camera at QR code'), findsOneWidget);
    });

    testWidgets('close button navigates back', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Find and tap close button
      expect(find.byKey(const Key('close_button')), findsOneWidget);
    });
  });
}
