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
  group('Generate PDF from Report', () {
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
        aiSummary: 'Test summary for the report.',
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
          aiDescription: 'A photo of the construction site.',
        ),
        Entry(
          id: 'entry-2',
          reportId: 'report-1',
          type: EntryType.video,
          mediaPath: '/path/to/video.mp4',
          thumbnailPath: '/path/to/video_thumb.jpg',
          durationSeconds: 30,
          sortOrder: 1,
          capturedAt: DateTime(2026, 1, 30, 10, 5),
          createdAt: DateTime(2026, 1, 30, 10, 5),
          aiDescription: 'A video walkthrough of the site.',
        ),
        Entry(
          id: 'entry-3',
          reportId: 'report-1',
          type: EntryType.note,
          content: 'Important observation noted during inspection.',
          sortOrder: 2,
          capturedAt: DateTime(2026, 1, 30, 10, 10),
          createdAt: DateTime(2026, 1, 30, 10, 10),
        ),
      ];
    });

    Widget createTestWidget({
      required Report report,
      required List<Project> projects,
      required List<Report> reports,
      required List<Entry> entries,
      MockPdfGenerationService? pdfService,
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

    testWidgets('shows Generate PDF button for completed report',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Verify Generate PDF button is visible
      expect(find.byKey(const Key('generate_pdf_button')), findsOneWidget);
    });

    testWidgets('shows processing indicator when generating PDF',
        (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 500,
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
      await tester.pump();

      // Verify processing indicator appears
      expect(find.byKey(const Key('pdf_processing_indicator')), findsOneWidget);

      // Complete the delayed future so test cleanup doesn't fail
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('shows success message after PDF generation', (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 100,
        resultPath: '/path/to/generated.pdf',
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

      // Verify success message is shown
      expect(find.text('PDF generated successfully'), findsOneWidget);
    });

    testWidgets('shows PDF preview option after generation', (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 100,
        resultPath: '/path/to/generated.pdf',
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

      // Verify PDF preview/download options appear
      expect(find.byKey(const Key('pdf_preview_button')), findsOneWidget);
      expect(find.byKey(const Key('pdf_share_button')), findsOneWidget);
    });

    testWidgets('PDF service receives all entries', (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 100,
        resultPath: '/path/to/generated.pdf',
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

      // Verify PDF service was called with all entries
      expect(mockPdfService.lastGeneratedReport?.id, equals('report-1'));
      expect(mockPdfService.lastGeneratedEntries?.length, equals(3));
    });

    testWidgets('PDF service includes QR codes for video entries',
        (tester) async {
      final mockPdfService = MockPdfGenerationService(
        delayMs: 100,
        resultPath: '/path/to/generated.pdf',
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

      // Verify video entries are passed with QR code flag
      final videoEntries = mockPdfService.lastGeneratedEntries
          ?.where((e) => e.type == EntryType.video)
          .toList();
      expect(videoEntries?.length, equals(1));
      expect(mockPdfService.includeQrCodesForVideos, isTrue);
    });

    testWidgets('Generate PDF button is disabled for draft report',
        (tester) async {
      final draftReport = testReport.copyWith(status: ReportStatus.draft);

      await tester.pumpWidget(createTestWidget(
        report: draftReport,
        projects: [testProject],
        reports: [draftReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the PDF generation section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Verify Generate PDF button is present but disabled for draft reports
      final button = find.byKey(const Key('generate_pdf_button'));
      expect(button, findsOneWidget);

      final widget = tester.widget<ElevatedButton>(button);
      expect(widget.onPressed, isNull);
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
