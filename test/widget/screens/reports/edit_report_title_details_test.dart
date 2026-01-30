import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';

void main() {
  group('User can edit report title and details', () {
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
        title: 'Initial Report Title',
        status: ReportStatus.draft,
        entryCount: 0,
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

    testWidgets('navigate to Report Editor and verify title is displayed',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Navigate to Report Editor - we're already there
      expect(find.text('Report Editor'), findsOneWidget);

      // The title field should display the current title
      expect(find.text('Initial Report Title'), findsOneWidget);
    });

    testWidgets('tap on report title and verify it becomes editable',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2-3: Tap on report title and verify it becomes editable
      final titleField = find.byKey(const Key('report_title_field'));
      expect(titleField, findsOneWidget);

      // Tap on the title field
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      // Verify the field is editable by checking we can find the TextField
      // (if it were disabled, it would not accept input)
      final textField = tester.widget<TextField>(titleField);
      // TextField is enabled by default unless explicitly disabled
      expect(textField.enabled ?? true, isTrue);
    });

    testWidgets('enter new title and verify it updates', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 4: Enter new title
      final titleField = find.byKey(const Key('report_title_field'));
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      // Clear existing text and enter new title
      await tester.enterText(titleField, 'Updated Report Title');
      await tester.pumpAndSettle();

      // Step 5: Tap outside (unfocus) or press done
      await tester.tap(find.text('Report Editor'));
      await tester.pumpAndSettle();

      // Step 6: Verify title updates
      expect(find.text('Updated Report Title'), findsOneWidget);
    });

    testWidgets('tap on notes field and enter report notes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 7: Tap on notes/description field
      final notesField = find.byKey(const Key('report_notes_field'));
      expect(notesField, findsOneWidget);

      await tester.tap(notesField);
      await tester.pumpAndSettle();

      // Step 8: Enter report notes
      await tester.enterText(notesField, 'These are my report notes.');
      await tester.pumpAndSettle();

      // Verify notes are entered
      expect(find.text('These are my report notes.'), findsOneWidget);
    });

    testWidgets('changes are auto-saved when leaving field', (tester) async {
      Report? updatedReport;

      await tester.pumpWidget(createTestWidget(
        onReportUpdated: (report) {
          updatedReport = report;
        },
      ));
      await tester.pumpAndSettle();

      // Edit the title
      final titleField = find.byKey(const Key('report_title_field'));
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      await tester.enterText(titleField, 'Auto-Saved Title');
      await tester.pumpAndSettle();

      // Unfocus by tapping on the notes field (another focusable element)
      final notesField = find.byKey(const Key('report_notes_field'));
      await tester.tap(notesField);
      await tester.pumpAndSettle();

      // Step 9: Verify changes are auto-saved
      expect(updatedReport, isNotNull);
      expect(updatedReport!.title, 'Auto-Saved Title');
    });

    testWidgets('notes are auto-saved when leaving field', (tester) async {
      Report? updatedReport;

      await tester.pumpWidget(createTestWidget(
        onReportUpdated: (report) {
          updatedReport = report;
        },
      ));
      await tester.pumpAndSettle();

      // Edit the notes
      final notesField = find.byKey(const Key('report_notes_field'));
      await tester.tap(notesField);
      await tester.pumpAndSettle();

      await tester.enterText(notesField, 'Auto-saved notes content');
      await tester.pumpAndSettle();

      // Unfocus by tapping on the title field
      final titleField = find.byKey(const Key('report_title_field'));
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      // Verify notes are auto-saved
      expect(updatedReport, isNotNull);
      expect(updatedReport!.notes, 'Auto-saved notes content');
    });

    testWidgets('full flow: edit title, edit notes, verify auto-save',
        (tester) async {
      Report? finalReport;

      await tester.pumpWidget(createTestWidget(
        onReportUpdated: (report) {
          finalReport = report;
        },
      ));
      await tester.pumpAndSettle();

      // Step 1: Navigate to Report Editor
      expect(find.text('Report Editor'), findsOneWidget);

      // Step 2-3: Tap on report title, verify editable
      final titleField = find.byKey(const Key('report_title_field'));
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      // Step 4: Enter new title
      await tester.enterText(titleField, 'My New Report Title');
      await tester.pumpAndSettle();

      // Step 5-6: Move to notes field (unfocuses title, triggering save)
      final notesField = find.byKey(const Key('report_notes_field'));
      await tester.tap(notesField);
      await tester.pumpAndSettle();

      // Step 7-8: Enter report notes
      await tester.enterText(notesField, 'Field inspection completed.');
      await tester.pumpAndSettle();

      // Unfocus to trigger save by going back to title
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      // Step 9: Verify changes are auto-saved
      expect(finalReport, isNotNull);
      expect(finalReport!.title, 'My New Report Title');
      expect(finalReport!.notes, 'Field inspection completed.');
    });
  });
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;
  final void Function(Report)? onUpdate;

  _MockReportsNotifier({required this.reports, this.onUpdate});

  @override
  Future<List<Report>> build() async {
    return reports;
  }

  @override
  Future<Report> createReport(Report report) async {
    reports.add(report);
    state = AsyncData(reports);
    return report;
  }

  @override
  Future<Report> updateReport(Report report) async {
    final index = reports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      reports[index] = report;
    }
    state = AsyncData(reports);
    onUpdate?.call(report);
    return report;
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
