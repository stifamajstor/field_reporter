import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported barcode formats.
enum BarcodeFormat {
  /// QR Code
  qrCode,

  /// EAN-13 barcode
  ean13,

  /// EAN-8 barcode
  ean8,

  /// Code 128 barcode
  code128,

  /// Code 39 barcode
  code39,

  /// UPC-A barcode
  upcA,

  /// UPC-E barcode
  upcE,

  /// Data Matrix
  dataMatrix,

  /// PDF417
  pdf417,

  /// Aztec
  aztec,

  /// Unknown format
  unknown,
}

/// Result of a barcode/QR code scan.
@immutable
class ScanResult {
  const ScanResult({
    required this.data,
    required this.format,
  });

  /// The decoded data from the scan.
  final String data;

  /// The format of the scanned barcode/QR code.
  final BarcodeFormat format;

  /// Returns a human-readable format name.
  String get formatDisplayName => switch (format) {
        BarcodeFormat.qrCode => 'QR Code',
        BarcodeFormat.ean13 => 'EAN-13',
        BarcodeFormat.ean8 => 'EAN-8',
        BarcodeFormat.code128 => 'Code 128',
        BarcodeFormat.code39 => 'Code 39',
        BarcodeFormat.upcA => 'UPC-A',
        BarcodeFormat.upcE => 'UPC-E',
        BarcodeFormat.dataMatrix => 'Data Matrix',
        BarcodeFormat.pdf417 => 'PDF417',
        BarcodeFormat.aztec => 'Aztec',
        BarcodeFormat.unknown => 'Unknown',
      };
}

/// Service for barcode and QR code scanning operations.
abstract class BarcodeScannerService {
  /// Opens the scanner and scans for a barcode/QR code.
  /// Returns the scan result, or null if scanning was cancelled.
  Future<ScanResult?> scan();

  /// Releases any resources held by the scanner.
  Future<void> dispose();
}

/// Default implementation of BarcodeScannerService.
/// In production, this would use the mobile_scanner package.
class DefaultBarcodeScannerService implements BarcodeScannerService {
  @override
  Future<ScanResult?> scan() async {
    // Implementation will use mobile_scanner package
    return null;
  }

  @override
  Future<void> dispose() async {
    // Implementation will dispose scanner controller
  }
}

/// Provider for the barcode scanner service.
final barcodeScannerServiceProvider = Provider<BarcodeScannerService>((ref) {
  return DefaultBarcodeScannerService();
});
