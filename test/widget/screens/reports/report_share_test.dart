import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/services/pdf_generation_service.dart';
import 'package:field_reporter/services/share_service.dart';

void main() {
  group('User can share report via native share sheet', () {
    late Report testReport;
    late Project testProject;
    late List<Entry> testEntries;
    late MockShareService mockShareService;
    late MockPdfGenerationService mockPdfService;

    setUp(() {
      testProject = Project(
        id: 'proj-1',
        name: 'Construction Site A',
        status: ProjectStatus.active,
      );

      testReport = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Site Inspection Report',
        status: ReportStatus.complete,
        entryCount: 2,
        createdAt: DateTime(2026, 1, 30, 14, 30),
        updatedAt: DateTime(2026, 1, 30, 15, 45),
      );

      testEntries = [
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          content: 'Photo entry',
          sortOrder: 0,
          capturedAt: DateTime(2026, 1, 30, 14, 35),
          createdAt: DateTime(2026, 1, 30, 14, 35),
        ),
        Entry(
          id: 'entry-2',
          reportId: 'report-1',
          type: EntryType.note,
          content: 'Note entry',
          sortOrder: 1,
          capturedAt: DateTime(2026, 1, 30, 14, 40),
          createdAt: DateTime(2026, 1, 30, 14, 40),
        ),
      ];

      mockShareService = MockShareService();
      mockPdfService = MockPdfGenerationService(
        result: const PdfGenerationResult(
          success: true,
          filePath: '/tmp/test_report.pdf',
        ),
      );
    });

    Widget createTestWidget({
      Report? report,
      List<Entry>? entries,
      ShareService? shareService,
      PdfGenerationService? pdfService,
    }) {
      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: [report ?? testReport]);
          }),
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: [testProject]);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier(entries: entries ?? testEntries);
          }),
          shareServiceProvider.overrideWithValue(
            shareService ?? mockShareService,
          ),
          pdfGenerationServiceProvider.overrideWithValue(
            pdfService ?? mockPdfService,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(
            report: report ?? testReport,
          ),
        ),
      );
    }

    testWidgets('Open Report with generated PDF - shows Share button',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to make the PDF section visible
      final generateButton = find.byKey(const Key('generate_pdf_button'));
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();

      // First generate PDF
      expect(generateButton, findsOneWidget);
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Verify Share button appears after PDF is generated
      final shareButton = find.byKey(const Key('pdf_share_button'));
      expect(shareButton, findsOneWidget);
    });

    testWidgets('Tap Share button - triggers native share sheet',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to and generate PDF first
      final generateButton = find.byKey(const Key('generate_pdf_button'));
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Tap Share button
      final shareButton = find.byKey(const Key('pdf_share_button'));
      await tester.ensureVisible(shareButton);
      await tester.pumpAndSettle();
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Verify share service was called
      expect(mockShareService.shareFileCalled, isTrue);
    });

    testWidgets('Verify PDF is the shared content', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to and generate PDF first
      final generateButton = find.byKey(const Key('generate_pdf_button'));
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Tap Share button
      final shareButton = find.byKey(const Key('pdf_share_button'));
      await tester.ensureVisible(shareButton);
      await tester.pumpAndSettle();
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Verify the PDF file path was shared
      expect(mockShareService.lastSharedFilePath, '/tmp/test_report.pdf');
      expect(mockShareService.lastSharedMimeType, 'application/pdf');
    });

    testWidgets('Share completes successfully', (tester) async {
      final successShareService = MockShareService(shareResult: true);

      await tester.pumpWidget(createTestWidget(
        shareService: successShareService,
      ));
      await tester.pumpAndSettle();

      // Scroll to and generate PDF first
      final generateButton = find.byKey(const Key('generate_pdf_button'));
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Tap Share button
      final shareButton = find.byKey(const Key('pdf_share_button'));
      await tester.ensureVisible(shareButton);
      await tester.pumpAndSettle();
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Verify share was called and completed
      expect(successShareService.shareFileCalled, isTrue);
      expect(successShareService.lastSharedFilePath, '/tmp/test_report.pdf');
    });

    testWidgets('Share button disabled when no PDF generated', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Share button should not be visible before PDF generation
      final shareButton = find.byKey(const Key('pdf_share_button'));
      expect(shareButton, findsNothing);
    });

    testWidgets('Share includes report title in subject', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to and generate PDF first
      final generateButton = find.byKey(const Key('generate_pdf_button'));
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Tap Share button
      final shareButton = find.byKey(const Key('pdf_share_button'));
      await tester.ensureVisible(shareButton);
      await tester.pumpAndSettle();
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      // Verify subject includes report title
      expect(
        mockShareService.lastSharedSubject,
        contains('Site Inspection Report'),
      );
    });
  });
}

/// Mock ShareService for testing
class MockShareService implements ShareService {
  MockShareService({this.shareResult = true});

  final bool shareResult;
  bool shareFileCalled = false;
  String? lastSharedFilePath;
  String? lastSharedMimeType;
  String? lastSharedSubject;

  @override
  Future<bool> shareFile({
    required String filePath,
    String? mimeType,
    String? subject,
    String? text,
  }) async {
    shareFileCalled = true;
    lastSharedFilePath = filePath;
    lastSharedMimeType = mimeType;
    lastSharedSubject = subject;
    return shareResult;
  }
}

/// Mock PdfGenerationService for testing
class MockPdfGenerationService implements PdfGenerationService {
  MockPdfGenerationService({required this.result});

  final PdfGenerationResult result;

  @override
  Future<PdfGenerationResult> generatePdf({
    required Report report,
    required List<Entry> entries,
    bool includeQrCodes = true,
  }) async {
    return result;
  }
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;

  _MockReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build() async {
    return reports;
  }
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async {
    return projects;
  }
}

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  final List<Entry> entries;

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }
}
