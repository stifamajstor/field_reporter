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

void main() {
  group('User can generate AI summary for entire report', () {
    late Report reportWithMultipleEntries;
    late List<Entry> entries;
    late Project project;

    setUp(() {
      final now = DateTime(2026, 1, 31, 14, 30);

      project = Project(
        id: 'proj-1',
        name: 'Test Project',
        description: 'A test project',
        status: ProjectStatus.active,
      );

      reportWithMultipleEntries = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 3,
        createdAt: now,
      );

      entries = [
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          mediaPath: '/test/photo1.jpg',
          aiDescription: 'A construction site with workers.',
          sortOrder: 0,
          capturedAt: now,
          createdAt: now,
        ),
        Entry(
          id: 'entry-2',
          reportId: 'report-1',
          type: EntryType.note,
          content: 'Foundation work completed successfully.',
          sortOrder: 1,
          capturedAt: now,
          createdAt: now,
        ),
        Entry(
          id: 'entry-3',
          reportId: 'report-1',
          type: EntryType.audio,
          mediaPath: '/test/audio.m4a',
          content: 'Site inspection notes recorded.',
          durationSeconds: 60,
          sortOrder: 2,
          capturedAt: now,
          createdAt: now,
        ),
      ];
    });

    Widget createTestWidget({
      required Report report,
      required List<Entry> entries,
      AllReportsNotifier? reportsNotifier,
      EntriesNotifier? entriesNotifier,
      ProjectsNotifier? projectsNotifier,
    }) {
      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return reportsNotifier ?? _MockReportsNotifier(reports: [report]);
          }),
          entriesNotifierProvider.overrideWith(() {
            return entriesNotifier ?? _MockEntriesNotifier(entries: entries);
          }),
          projectsNotifierProvider.overrideWith(() {
            return projectsNotifier ??
                _MockProjectsNotifier(projects: [project]);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(report: report),
        ),
      );
    }

    testWidgets('Generate Summary button is visible for report with entries',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: reportWithMultipleEntries,
          entries: entries,
        ),
      );
      await tester.pumpAndSettle();

      // Verify 'Generate Summary' button is visible
      expect(find.byKey(const Key('generate_summary_button')), findsOneWidget);
      expect(find.text('Generate Summary'), findsOneWidget);
    });

    testWidgets('Tapping Generate Summary button shows processing indicator',
        (tester) async {
      final mockReportsNotifier = _MockReportsNotifierWithSlowSummary(
        reports: [reportWithMultipleEntries],
      );

      await tester.pumpWidget(
        createTestWidget(
          report: reportWithMultipleEntries,
          entries: entries,
          reportsNotifier: mockReportsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Tap 'Generate Summary' button
      await tester.tap(find.byKey(const Key('generate_summary_button')));
      await tester.pump();

      // Verify processing indicator appears
      expect(find.byKey(const Key('summary_processing_indicator')),
          findsOneWidget);

      // Let the summary generation complete
      await tester.pumpAndSettle();
    });

    testWidgets(
        'AI-generated summary appears at top of report after completion',
        (tester) async {
      final mockReportsNotifier = _MockReportsNotifierWithSummary(
        reports: [reportWithMultipleEntries],
        summaryResult:
            'This report documents a construction site inspection. Photos show workers on site, foundation work was completed successfully, and voice notes capture detailed inspection observations.',
      );

      await tester.pumpWidget(
        createTestWidget(
          report: reportWithMultipleEntries,
          entries: entries,
          reportsNotifier: mockReportsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Tap 'Generate Summary' button
      await tester.tap(find.byKey(const Key('generate_summary_button')));
      await tester.pump();

      // Wait for summary to complete
      await tester.pumpAndSettle();

      // Scroll back to top to see the summary
      await tester.drag(
        find.byType(ListView),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();

      // Verify AI-generated summary appears at top of report
      expect(find.byKey(const Key('ai_summary_section')), findsOneWidget);
      expect(find.textContaining('This report documents a construction site'),
          findsOneWidget);
    });

    testWidgets('Summary covers all entries', (tester) async {
      final mockReportsNotifier = _MockReportsNotifierWithSummary(
        reports: [reportWithMultipleEntries],
        summaryResult:
            'Report contains 3 entries: a photo showing construction workers, a text note about foundation completion, and an audio recording with inspection details.',
      );

      await tester.pumpWidget(
        createTestWidget(
          report: reportWithMultipleEntries,
          entries: entries,
          reportsNotifier: mockReportsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Tap 'Generate Summary' button
      await tester.tap(find.byKey(const Key('generate_summary_button')));
      await tester.pumpAndSettle();

      // Scroll back to top
      await tester.drag(
        find.byType(ListView),
        const Offset(0, 500),
      );
      await tester.pumpAndSettle();

      // Verify summary mentions all entry types
      expect(find.textContaining('3 entries'), findsOneWidget);
      expect(find.textContaining('photo'), findsWidgets);
      expect(find.textContaining('text note'), findsOneWidget);
      expect(find.textContaining('audio'), findsWidgets);
    });

    testWidgets('Summary is editable', (tester) async {
      // Start with a report that already has an AI summary
      final reportWithSummary = reportWithMultipleEntries.copyWith(
        aiSummary:
            'This report documents a construction site inspection with multiple entries.',
      );

      final mockReportsNotifier = _MockReportsNotifier(
        reports: [reportWithSummary],
      );

      await tester.pumpWidget(
        createTestWidget(
          report: reportWithSummary,
          entries: entries,
          reportsNotifier: mockReportsNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Verify AI summary section is shown
      expect(find.byKey(const Key('ai_summary_section')), findsOneWidget);

      // Tap on AI summary to edit
      await tester.tap(find.byKey(const Key('ai_summary_section')));
      await tester.pumpAndSettle();

      // Verify edit mode is active (text field appears)
      expect(find.byKey(const Key('ai_summary_text_field')), findsOneWidget);

      // Enter edited text
      await tester.enterText(
        find.byKey(const Key('ai_summary_text_field')),
        'Updated summary with additional context.',
      );
      await tester.pumpAndSettle();

      // Scroll to make the save button visible if needed
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();

      // Save the edit
      await tester.tap(find.byKey(const Key('ai_summary_save_button')));
      await tester.pumpAndSettle();

      // Verify edited text is displayed
      expect(find.text('Updated summary with additional context.'),
          findsOneWidget);
    });

    testWidgets(
        'Report with existing AI summary shows summary section and no Generate button',
        (tester) async {
      final reportWithSummary = reportWithMultipleEntries.copyWith(
        aiSummary: 'Existing AI summary of the report.',
      );

      await tester.pumpWidget(
        createTestWidget(
          report: reportWithSummary,
          entries: entries,
        ),
      );
      await tester.pumpAndSettle();

      // Verify AI summary section is shown
      expect(find.byKey(const Key('ai_summary_section')), findsOneWidget);
      expect(find.text('Existing AI summary of the report.'), findsOneWidget);

      // Verify 'Generate Summary' button is NOT shown (already generated)
      expect(find.byKey(const Key('generate_summary_button')), findsNothing);
    });
  });
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;

  _MockReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build() async {
    return reports;
  }

  @override
  Future<Report> updateReport(Report report) async {
    final currentReports = state.valueOrNull ?? [];
    final updatedReports = currentReports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
  }
}

/// Mock ReportsNotifier with summary support
class _MockReportsNotifierWithSummary extends AllReportsNotifier {
  final List<Report> reports;
  final String? summaryResult;

  _MockReportsNotifierWithSummary({
    required this.reports,
    this.summaryResult,
  });

  @override
  Future<List<Report>> build() async {
    return reports;
  }

  @override
  Future<Report> updateReport(Report report) async {
    final currentReports = state.valueOrNull ?? [];
    final updatedReports = currentReports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
  }

  @override
  Future<Report> generateSummary(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final currentReports = state.valueOrNull ?? [];
    final report = currentReports.firstWhere((r) => r.id == reportId);
    final summarizedReport = report.copyWith(aiSummary: summaryResult);
    await updateReport(summarizedReport);
    return summarizedReport;
  }
}

/// Mock ReportsNotifier with slow summary for testing processing indicator
class _MockReportsNotifierWithSlowSummary extends AllReportsNotifier {
  final List<Report> reports;

  _MockReportsNotifierWithSlowSummary({required this.reports});

  @override
  Future<List<Report>> build() async {
    return reports;
  }

  @override
  Future<Report> updateReport(Report report) async {
    final currentReports = state.valueOrNull ?? [];
    final updatedReports = currentReports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
  }

  @override
  Future<Report> generateSummary(String reportId) async {
    // Simulate slow AI processing
    await Future.delayed(const Duration(milliseconds: 500));
    final currentReports = state.valueOrNull ?? [];
    final report = currentReports.firstWhere((r) => r.id == reportId);
    final summarizedReport =
        report.copyWith(aiSummary: 'AI-generated summary of the report.');
    await updateReport(summarizedReport);
    return summarizedReport;
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

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async {
    return projects;
  }
}
