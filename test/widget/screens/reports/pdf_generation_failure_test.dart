import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/services/pdf_generation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PDF generation failure allows retry', () {
    late Report testReport;
    late List<Entry> testEntries;
    late Project testProject;

    setUp(() {
      testProject = const Project(
        id: 'proj-1',
        name: 'Test Project',
      );

      testReport = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.complete,
        entryCount: 3,
        createdAt: DateTime(2026, 1, 30),
      );

      testEntries = [
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          mediaPath: '/path/to/photo.jpg',
          sortOrder: 0,
          capturedAt: DateTime(2026, 1, 30, 10, 0),
          createdAt: DateTime(2026, 1, 30, 10, 0),
        ),
      ];
    });

    Widget createTestWidget({
      required Report report,
      required List<Project> projects,
      required List<Report> reports,
      required List<Entry> entries,
      PdfGenerationService? pdfService,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects);
          }),
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: reports);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier(entries: entries);
          }),
          if (pdfService != null)
            pdfGenerationServiceProvider.overrideWithValue(pdfService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ReportEditorScreen(
            report: report,
          ),
        ),
      );
    }

    testWidgets('shows error message with reason when PDF generation fails',
        (tester) async {
      final mockPdfService = _MockPdfGenerationServiceWithFailure(
        shouldFail: true,
        errorMessage: 'Insufficient storage space',
      );

      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
        pdfService: mockPdfService,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Generate PDF button
      await tester.tap(find.byKey(const Key('generate_pdf_button')));
      await tester.pumpAndSettle();

      // Verify error message is displayed with reason
      expect(find.byKey(const Key('pdf_error_message')), findsOneWidget);
      expect(find.text('Insufficient storage space'), findsOneWidget);
    });

    testWidgets('shows Retry button after PDF generation failure',
        (tester) async {
      final mockPdfService = _MockPdfGenerationServiceWithFailure(
        shouldFail: true,
        errorMessage: 'Network error',
      );

      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
        pdfService: mockPdfService,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Generate PDF button
      await tester.tap(find.byKey(const Key('generate_pdf_button')));
      await tester.pumpAndSettle();

      // Verify Retry button is available
      expect(find.byKey(const Key('pdf_retry_button')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry triggers new PDF generation attempt', (tester) async {
      final retryState = _RetryState();
      final mockPdfService = _MockPdfGenerationServiceWithRetry(
        retryState: retryState,
      );

      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
        pdfService: mockPdfService,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Generate PDF button - will fail first time
      await tester.tap(find.byKey(const Key('generate_pdf_button')));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.byKey(const Key('pdf_error_message')), findsOneWidget);

      // Tap Retry button
      await tester.tap(find.byKey(const Key('pdf_retry_button')));
      await tester.pumpAndSettle();

      // Verify eventual success
      expect(find.text('PDF generated successfully'), findsOneWidget);
      expect(find.byKey(const Key('pdf_error_message')), findsNothing);
    });

    testWidgets('retry shows clear failure message if still failing',
        (tester) async {
      final mockPdfService = _MockPdfGenerationServiceWithFailure(
        shouldFail: true,
        errorMessage: 'Persistent failure',
      );

      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
        pdfService: mockPdfService,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Generate PDF button - will fail
      await tester.tap(find.byKey(const Key('generate_pdf_button')));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.byKey(const Key('pdf_error_message')), findsOneWidget);

      // Tap Retry button
      await tester.tap(find.byKey(const Key('pdf_retry_button')));
      await tester.pumpAndSettle();

      // Verify error is still shown with clear message
      expect(find.byKey(const Key('pdf_error_message')), findsOneWidget);
      expect(find.text('Persistent failure'), findsOneWidget);
    });

    testWidgets('error can be dismissed to show generate button again',
        (tester) async {
      final mockPdfService = _MockPdfGenerationServiceWithFailure(
        shouldFail: true,
        errorMessage: 'Temporary error',
      );

      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
        pdfService: mockPdfService,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Generate PDF button - will fail
      await tester.tap(find.byKey(const Key('generate_pdf_button')));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.byKey(const Key('pdf_error_message')), findsOneWidget);

      // Tap Dismiss button
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Scroll to find the button again
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Verify generate button is visible again
      expect(find.byKey(const Key('generate_pdf_button')), findsOneWidget);
      expect(find.byKey(const Key('pdf_error_message')), findsNothing);
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async => projects;
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;

  _MockReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build() async => reports;

  @override
  Future<Report> updateReport(Report report) async {
    return report;
  }
}

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  final List<Entry> entries;

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async => entries;
}

/// Mock PDF generation service that always fails
class _MockPdfGenerationServiceWithFailure implements PdfGenerationService {
  _MockPdfGenerationServiceWithFailure({
    required this.shouldFail,
    this.errorMessage = 'Generation failed',
  });

  final bool shouldFail;
  final String errorMessage;

  @override
  Future<PdfGenerationResult> generatePdf({
    required Report report,
    required List<Entry> entries,
    bool includeQrCodes = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) {
      return PdfGenerationResult(
        success: false,
        error: errorMessage,
      );
    }
    return const PdfGenerationResult(
      success: true,
      filePath: '/path/to/generated.pdf',
    );
  }
}

/// Shared state for retry counter
class _RetryState {
  int attempts = 0;
}

/// Mock PDF generation service that fails first, then succeeds
class _MockPdfGenerationServiceWithRetry implements PdfGenerationService {
  _MockPdfGenerationServiceWithRetry({
    required this.retryState,
  });

  final _RetryState retryState;

  @override
  Future<PdfGenerationResult> generatePdf({
    required Report report,
    required List<Entry> entries,
    bool includeQrCodes = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    retryState.attempts++;

    if (retryState.attempts == 1) {
      return const PdfGenerationResult(
        success: false,
        error: 'First attempt failed',
      );
    }

    return const PdfGenerationResult(
      success: true,
      filePath: '/path/to/generated.pdf',
    );
  }
}
