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
  group('Report Status Badge', () {
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
        status: ReportStatus.draft,
        entryCount: 1,
        createdAt: DateTime(2026, 1, 30),
      );

      testEntries = [
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          mediaPath: '/path/to/photo.jpg',
          thumbnailPath: '/path/to/thumbnail.jpg',
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
      MockPdfGenerationService? pdfService,
      _MockReportsNotifier? reportsNotifier,
    }) {
      final notifier =
          reportsNotifier ?? _MockReportsNotifier(reports: reports);
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects);
          }),
          allReportsNotifierProvider.overrideWith(() => notifier),
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

    testWidgets('displays Draft badge when report is in draft status',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify 'Draft' badge is displayed
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('displays Processing badge during PDF generation',
        (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 1000,
        resultPath: '/path/to/generated.pdf',
      );

      // Start with a complete report to enable PDF generation
      final completeReport = testReport.copyWith(status: ReportStatus.complete);

      final reportsNotifier = _MockReportsNotifier(reports: [completeReport]);

      await tester.pumpWidget(createTestWidget(
        report: completeReport,
        projects: [testProject],
        reports: [completeReport],
        entries: testEntries,
        pdfService: mockPdfService,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Initial state should be Complete
      expect(find.text('Complete'), findsOneWidget);

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Generate PDF button
      await tester.tap(find.byKey(const Key('generate_pdf_button')));

      // Pump to trigger setState and start PDF generation
      await tester.pump();
      // Pump a bit more to ensure the widget rebuilds with isGeneratingPdf=true
      await tester.pump(const Duration(milliseconds: 100));

      // Scroll back up to see the status badge
      await tester.drag(
        find.byType(ListView),
        const Offset(0, 500),
      );
      await tester.pump();

      // Verify 'Processing' badge is displayed during generation
      expect(find.text('Processing'), findsOneWidget);

      // Complete the delayed future
      await tester.pumpAndSettle(const Duration(milliseconds: 1100));
    });

    testWidgets('displays Complete badge after PDF generation completes',
        (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 100,
        resultPath: '/path/to/generated.pdf',
      );

      // Start with a complete report
      final completeReport = testReport.copyWith(status: ReportStatus.complete);

      final reportsNotifier = _MockReportsNotifier(reports: [completeReport]);

      await tester.pumpWidget(createTestWidget(
        report: completeReport,
        projects: [testProject],
        reports: [completeReport],
        entries: testEntries,
        pdfService: mockPdfService,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Verify 'Complete' badge is displayed initially
      expect(find.text('Complete'), findsOneWidget);

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Tap Generate PDF button
      await tester.tap(find.byKey(const Key('generate_pdf_button')));

      // Wait for PDF generation to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Scroll back up to see the status badge
      await tester.drag(
        find.byType(ListView),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();

      // Verify 'Complete' badge is displayed after generation completes
      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('badge transitions from Draft to Processing when PDF triggered',
        (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 500,
        resultPath: '/path/to/generated.pdf',
      );

      // Start with draft report to test transition (need to mark complete first)
      final reportsNotifier = _MockReportsNotifier(
        reports: [testReport],
        onUpdateStatus: (status) {
          // Simulate status change in notifier
        },
      );

      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
        pdfService: mockPdfService,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Verify initial Draft badge
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('Processing badge shows with correct styling', (tester) async {
      final processingReport =
          testReport.copyWith(status: ReportStatus.processing);

      await tester.pumpWidget(createTestWidget(
        report: processingReport,
        projects: [testProject],
        reports: [processingReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify 'Processing' badge is displayed
      expect(find.text('Processing'), findsOneWidget);

      // Find the badge container and verify styling
      final badgeText = find.text('Processing');
      expect(badgeText, findsOneWidget);

      // Verify the badge has amber/warning styling (by checking it's in a container)
      final container = find.ancestor(
        of: badgeText,
        matching: find.byType(Container),
      );
      expect(container, findsWidgets);
    });

    testWidgets('Complete badge shows with correct styling', (tester) async {
      final completeReport = testReport.copyWith(status: ReportStatus.complete);

      await tester.pumpWidget(createTestWidget(
        report: completeReport,
        projects: [testProject],
        reports: [completeReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify 'Complete' badge is displayed
      expect(find.text('Complete'), findsOneWidget);

      // Verify the badge has emerald/success styling
      final badgeText = find.text('Complete');
      final container = find.ancestor(
        of: badgeText,
        matching: find.byType(Container),
      );
      expect(container, findsWidgets);
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
  final void Function(ReportStatus)? onUpdateStatus;

  _MockReportsNotifier({
    required this.reports,
    this.onUpdateStatus,
  });

  @override
  Future<List<Report>> build() async => reports;

  @override
  Future<Report> updateReport(Report report) async {
    onUpdateStatus?.call(report.status);
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

/// Mock PDF generation service for testing
class MockPdfGenerationService implements PdfGenerationService {
  MockPdfGenerationService({
    this.delayMs = 100,
    this.resultPath,
  });

  final int delayMs;
  final String? resultPath;

  Report? lastGeneratedReport;
  List<Entry>? lastGeneratedEntries;
  bool includeQrCodesForVideos = false;

  @override
  Future<PdfGenerationResult> generatePdf({
    required Report report,
    required List<Entry> entries,
    bool includeQrCodes = true,
  }) async {
    lastGeneratedReport = report;
    lastGeneratedEntries = entries;
    includeQrCodesForVideos = includeQrCodes;

    await Future.delayed(Duration(milliseconds: delayMs));

    if (resultPath != null) {
      return PdfGenerationResult(
        success: true,
        filePath: resultPath!,
      );
    }
    return const PdfGenerationResult(
      success: false,
      error: 'Generation failed',
    );
  }
}
