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
  bool _flashlightOn = false;

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

  @override
  bool get isFlashlightOn => _flashlightOn;

  @override
  Future<void> toggleFlashlight() async {
    _flashlightOn = !_flashlightOn;
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

  group('Barcode Scanner Format Detection', () {
    testWidgets('scanner opens successfully', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Verify scanner is open
      expect(find.byKey(const Key('scanner_preview')), findsOneWidget);
      expect(find.byKey(const Key('scan_overlay')), findsOneWidget);
    });

    testWidgets('detects and decodes EAN-13 barcode (common product)',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Simulate EAN-13 barcode scan (13-digit product barcode)
      const ean13Result = ScanResult(
        data: '5901234123457',
        format: BarcodeFormat.ean13,
      );
      mockScannerService.simulateStableCapture(ean13Result);
      await tester.pump();

      // Verify successful decode
      expect(find.byKey(const Key('scan_result_content')), findsOneWidget);
      expect(find.text('5901234123457'), findsOneWidget);
      expect(find.text('EAN-13'), findsOneWidget);
    });

    testWidgets('detects and decodes UPC-A barcode', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Simulate UPC-A barcode scan (12-digit US product barcode)
      const upcAResult = ScanResult(
        data: '012345678905',
        format: BarcodeFormat.upcA,
      );
      mockScannerService.simulateStableCapture(upcAResult);
      await tester.pump();

      // Verify successful decode
      expect(find.byKey(const Key('scan_result_content')), findsOneWidget);
      expect(find.text('012345678905'), findsOneWidget);
      expect(find.text('UPC-A'), findsOneWidget);
    });

    testWidgets('detects and decodes Code 128 barcode', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Simulate Code 128 barcode scan (alphanumeric barcode)
      const code128Result = ScanResult(
        data: 'ABC-12345-XYZ',
        format: BarcodeFormat.code128,
      );
      mockScannerService.simulateStableCapture(code128Result);
      await tester.pump();

      // Verify successful decode
      expect(find.byKey(const Key('scan_result_content')), findsOneWidget);
      expect(find.text('ABC-12345-XYZ'), findsOneWidget);
      expect(find.text('Code 128'), findsOneWidget);
    });

    testWidgets('all formats display decoded number correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(
        permissionService: mockPermissionService,
        scannerService: mockScannerService,
      ));
      await tester.pumpAndSettle();

      // Test EAN-13
      const ean13Result = ScanResult(
        data: '4006381333931',
        format: BarcodeFormat.ean13,
      );
      mockScannerService.simulateStableCapture(ean13Result);
      await tester.pump();

      expect(find.text('4006381333931'), findsOneWidget);
      expect(find.text('EAN-13'), findsOneWidget);

      // Reset scanner and test UPC-A
      await tester.tap(find.byKey(const Key('rescan_button')));
      await tester.pumpAndSettle();

      const upcAResult = ScanResult(
        data: '036000291452',
        format: BarcodeFormat.upcA,
      );
      mockScannerService.simulateStableCapture(upcAResult);
      await tester.pump();

      expect(find.text('036000291452'), findsOneWidget);
      expect(find.text('UPC-A'), findsOneWidget);

      // Reset scanner and test Code 128
      await tester.tap(find.byKey(const Key('rescan_button')));
      await tester.pumpAndSettle();

      const code128Result = ScanResult(
        data: 'SHIP-2024-001',
        format: BarcodeFormat.code128,
      );
      mockScannerService.simulateStableCapture(code128Result);
      await tester.pump();

      expect(find.text('SHIP-2024-001'), findsOneWidget);
      expect(find.text('Code 128'), findsOneWidget);
    });

    testWidgets('format display names are correct for all tested formats',
        (tester) async {
      // Verify format display names in ScanResult
      expect(
        const ScanResult(data: '', format: BarcodeFormat.ean13)
            .formatDisplayName,
        'EAN-13',
      );
      expect(
        const ScanResult(data: '', format: BarcodeFormat.upcA)
            .formatDisplayName,
        'UPC-A',
      );
      expect(
        const ScanResult(data: '', format: BarcodeFormat.code128)
            .formatDisplayName,
        'Code 128',
      );
    });
  });
}
