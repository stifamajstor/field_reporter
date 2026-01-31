import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/barcode_scanner_service.dart';
import '../../../services/permission_service.dart';

/// Result returned when user saves a QR scan.
@immutable
class QrScannerResult {
  const QrScannerResult({
    required this.data,
    required this.format,
  });

  final String data;
  final BarcodeFormat format;
}

/// Scanner state for the QR scanner.
enum ScannerState {
  /// Scanning for QR codes.
  scanning,

  /// QR code detected, waiting for stability.
  detected,

  /// QR code captured and result displayed.
  captured,
}

/// Screen for scanning QR codes.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  ScannerState _scannerState = ScannerState.scanning;
  ScanResult? _detectedCode;
  ScanResult? _capturedResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndInitialize();
      _setupScannerCallbacks();
    });
  }

  void _setupScannerCallbacks() {
    final scannerService = ref.read(barcodeScannerServiceProvider);
    if (scannerService is MockableBarcodeScannerService) {
      scannerService.onCodeDetected = _handleCodeDetected;
      scannerService.onCodeCaptured = _handleCodeCaptured;
    }
  }

  void _handleCodeDetected(ScanResult result) {
    if (!mounted) return;
    setState(() {
      _scannerState = ScannerState.detected;
      _detectedCode = result;
    });
  }

  void _handleCodeCaptured(ScanResult result) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _scannerState = ScannerState.captured;
      _capturedResult = result;
    });
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.checkCameraPermission();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.requestCameraPermission();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isPermanentlyDenied) {
      await permissionService.openAppSettings();
    }
  }

  void _handleRescan() {
    setState(() {
      _scannerState = ScannerState.scanning;
      _detectedCode = null;
      _capturedResult = null;
    });
  }

  void _handleSave() {
    HapticFeedback.lightImpact();
    if (_capturedResult != null) {
      Navigator.of(context).pop(QrScannerResult(
        data: _capturedResult!.data,
        format: _capturedResult!.format,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    return _buildScanner();
  }

  Widget _buildPermissionRequest() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: AppColors.slate400,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Permission Required',
                style: AppTypography.headline2.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To scan QR codes, please allow camera access.',
                style: AppTypography.body1.copyWith(
                  color: AppColors.slate400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('grant_permission_button'),
                  onPressed: _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Grant Permission',
                    style: AppTypography.button,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.button.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Scanner preview placeholder
          Container(
            key: const Key('scanner_preview'),
            color: Colors.black,
          ),

          // Scan overlay
          _buildScanOverlay(),

          // Detection highlight
          if (_scannerState == ScannerState.detected && _detectedCode != null)
            Center(
              child: Container(
                key: const Key('detection_highlight'),
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.orange500,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          // Result display
          if (_scannerState == ScannerState.captured && _capturedResult != null)
            _buildResultDisplay(),

          // Top bar with close button
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      key: const Key('close_button'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Helper text at bottom (only when scanning)
          if (_scannerState == ScannerState.scanning)
            Positioned(
              left: 0,
              right: 0,
              bottom: 120,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Point camera at QR code',
                    style: AppTypography.body2.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      key: const Key('scan_overlay'),
      child: Stack(
        children: [
          // Semi-transparent background
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          // Clear center area with scan frame
          Center(
            child: Container(
              key: const Key('scan_frame'),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.transparent,
                  width: 0,
                ),
              ),
              child: Stack(
                children: [
                  // Clear the center
                  Container(
                    color: Colors.black.withOpacity(0.0),
                  ),
                  // Corner markers
                  // Top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCorner(
                      key: const Key('scan_frame_corner_tl'),
                      topBorder: true,
                      leftBorder: true,
                    ),
                  ),
                  // Top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCorner(
                      key: const Key('scan_frame_corner_tr'),
                      topBorder: true,
                      rightBorder: true,
                    ),
                  ),
                  // Bottom-left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCorner(
                      key: const Key('scan_frame_corner_bl'),
                      bottomBorder: true,
                      leftBorder: true,
                    ),
                  ),
                  // Bottom-right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCorner(
                      key: const Key('scan_frame_corner_br'),
                      bottomBorder: true,
                      rightBorder: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    required Key key,
    bool topBorder = false,
    bool bottomBorder = false,
    bool leftBorder = false,
    bool rightBorder = false,
  }) {
    return Container(
      key: key,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: topBorder
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          bottom: bottomBorder
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          left: leftBorder
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right: rightBorder
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange500.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _capturedResult!.formatDisplayName,
                  style: AppTypography.overline.copyWith(
                    color: AppColors.orange500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Decoded content
              Container(
                key: const Key('scan_result_content'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _capturedResult!.data,
                  style: AppTypography.monoLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('rescan_button'),
                      onPressed: _handleRescan,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.slate400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Rescan',
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('save_scan_button'),
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extended interface for mockable barcode scanner service.
abstract class MockableBarcodeScannerService implements BarcodeScannerService {
  void Function(ScanResult)? onCodeDetected;
  void Function(ScanResult)? onCodeCaptured;
}
