import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/entries/domain/entry.dart';
import '../features/reports/domain/report.dart';

part 'pdf_generation_service.g.dart';

/// Result of a PDF generation operation.
@immutable
class PdfGenerationResult {
  const PdfGenerationResult({
    required this.success,
    this.filePath,
    this.error,
  });

  /// Whether PDF generation was successful.
  final bool success;

  /// Path to the generated PDF file (if successful).
  final String? filePath;

  /// Error message (if failed).
  final String? error;
}

/// Service for generating PDF reports.
abstract class PdfGenerationService {
  /// Generates a PDF from a report and its entries.
  Future<PdfGenerationResult> generatePdf({
    required Report report,
    required List<Entry> entries,
    bool includeQrCodes = true,
  });
}

/// Default implementation of PDF generation service.
class DefaultPdfGenerationService implements PdfGenerationService {
  @override
  Future<PdfGenerationResult> generatePdf({
    required Report report,
    required List<Entry> entries,
    bool includeQrCodes = true,
  }) async {
    // TODO: Implement actual PDF generation
    throw UnimplementedError('PDF generation not yet implemented');
  }
}

/// Provider for the PDF generation service.
@riverpod
PdfGenerationService pdfGenerationService(Ref ref) {
  return DefaultPdfGenerationService();
}
