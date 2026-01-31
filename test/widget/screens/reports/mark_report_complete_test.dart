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
  group('User can mark report as complete', () {
    late Report testReport;
    late List<Project> testProjects;

    setUp(() {
      testProjects = [
        const Project(
          id: 'proj-1',
          name: 'Construction Site A',
          status: ProjectStatus.active,
        ),
      ];

      testReport = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 3,
        createdAt: DateTime(2026, 1, 30, 14, 30),
      );
    });

    Widget createTestWidget({
      Report? report,
      List<Project>? projects,
      void Function(Report)? onReportUpdated,
    }) {
      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(
              reports: [report ?? testReport],
              onUpdate: onReportUpdated,
            );
          }),
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects ?? testProjects);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier();
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(
            report: report ?? testReport,
            projectId: 'proj-1',
          ),
        ),
      );
    }

    testWidgets('opens report in draft status', (tester) async {
      // Step 1: Open Report in draft status
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify report is in draft status
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Report Editor'), findsOneWidget);
    });

    testWidgets('shows Mark Complete button for draft reports', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to find the Mark Complete section
      await tester.scrollUntilVisible(
        find.text('Mark Complete'),
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Step 2: Verify 'Mark Complete' button is visible
      expect(find.text('Mark Complete'), findsOneWidget);
    });

    testWidgets('tapping Mark Complete shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to find the Mark Complete section
      await tester.scrollUntilVisible(
        find.text('Mark Complete'),
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Step 2: Tap 'Mark Complete' button
      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();

      // Step 3: Verify confirmation dialog appears
      expect(find.text('Mark Report Complete?'), findsOneWidget);
      expect(
        find.textContaining('Once marked complete'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Mark Complete'), findsNWidgets(2)); // Button and dialog
    });

    testWidgets('confirming dialog changes status to Complete', (tester) async {
      Report? updatedReport;

      await tester.pumpWidget(createTestWidget(
        onReportUpdated: (report) {
          updatedReport = report;
        },
      ));
      await tester.pumpAndSettle();

      // Scroll down to find the Mark Complete section
      await tester.scrollUntilVisible(
        find.text('Mark Complete'),
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Step 2: Tap 'Mark Complete' button
      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();

      // Step 4: Confirm marking complete
      // Find the dialog's Mark Complete button (the second one)
      final dialogButtons = find.text('Mark Complete');
      await tester.tap(dialogButtons.last);
      await tester.pumpAndSettle();

      // Step 5: Verify status changes to 'Complete'
      // Scroll back up to see the status badge
      await tester.scrollUntilVisible(
        find.text('Complete'),
        -500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Draft'), findsNothing);
      expect(updatedReport?.status, ReportStatus.complete);
    });

    testWidgets('complete report becomes read-only', (tester) async {
      // Create a complete report
      final completeReport = testReport.copyWith(status: ReportStatus.complete);

      await tester.pumpWidget(createTestWidget(report: completeReport));
      await tester.pumpAndSettle();

      // Step 6: Verify report becomes read-only
      // Title field should be disabled
      final titleField = find.byKey(const Key('report_title_field'));
      if (titleField.evaluate().isNotEmpty) {
        final textField = tester.widget<TextField>(titleField);
        expect(textField.enabled, isFalse);
      }

      // Notes field should be disabled
      final notesField = find.byKey(const Key('report_notes_field'));
      if (notesField.evaluate().isNotEmpty) {
        final notesTextField = tester.widget<TextField>(notesField);
        expect(notesTextField.enabled, isFalse);
      }

      // Mark Complete button should not be visible
      expect(find.text('Mark Complete'), findsNothing);

      // Add entry button should not be visible
      expect(find.text('Add Entry'), findsNothing);
    });

    testWidgets('complete report shows visual indicator', (tester) async {
      // Create a complete report
      final completeReport = testReport.copyWith(status: ReportStatus.complete);

      await tester.pumpWidget(createTestWidget(report: completeReport));
      await tester.pumpAndSettle();

      // Step 7: Verify visual indicator of complete status
      // Should show Complete status badge with emerald/green styling
      expect(find.text('Complete'), findsOneWidget);

      // Find the status badge container with emerald background
      final completeBadge = find.ancestor(
        of: find.text('Complete'),
        matching: find.byType(Container),
      );
      expect(completeBadge, findsWidgets);
    });

    testWidgets('cancel dialog keeps report in draft status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to find the Mark Complete section
      await tester.scrollUntilVisible(
        find.text('Mark Complete'),
        500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap 'Mark Complete' button
      await tester.tap(find.text('Mark Complete'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Scroll back up to see the status badge
      await tester.scrollUntilVisible(
        find.text('Draft'),
        -500.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Verify status is still Draft
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Complete'), findsNothing);
    });
  });
}

class _MockReportsNotifier extends AllReportsNotifier {
  _MockReportsNotifier({
    required this.reports,
    this.onUpdate,
  });

  final List<Report> reports;
  final void Function(Report)? onUpdate;

  @override
  Future<List<Report>> build() async {
    return reports;
  }

  @override
  Future<Report> updateReport(Report report) async {
    onUpdate?.call(report);
    final index = reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      reports[index] = report;
    }
    state = AsyncData(List.from(reports));
    return report;
  }

  @override
  Future<Report> generateSummary(String reportId) async {
    return reports.firstWhere((r) => r.id == reportId);
  }
}

class _MockProjectsNotifier extends ProjectsNotifier {
  _MockProjectsNotifier({required this.projects});

  final List<Project> projects;

  @override
  Future<List<Project>> build() async {
    return projects;
  }
}

class _MockEntriesNotifier extends EntriesNotifier {
  @override
  Future<List<Entry>> build() async {
    return [];
  }
}
