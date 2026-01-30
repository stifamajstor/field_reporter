import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/reports_screen.dart';
import 'package:field_reporter/features/reports/presentation/project_selection_screen.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';

void main() {
  group('User can create a new report', () {
    late List<Report> testReports;
    late List<Project> testProjects;

    setUp(() {
      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Construction Site A',
          status: ProjectStatus.active,
        ),
        Project(
          id: 'proj-2',
          name: 'Office Building B',
          status: ProjectStatus.active,
        ),
      ];

      testReports = [
        Report(
          id: 'report-1',
          projectId: 'proj-1',
          title: 'Existing Report',
          status: ReportStatus.draft,
          entryCount: 0,
          createdAt: DateTime(2026, 1, 30, 14, 30),
        ),
      ];
    });

    Widget createTestWidget({
      List<Report>? reports,
      List<Project>? projects,
    }) {
      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: reports ?? testReports);
          }),
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects ?? testProjects);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routes: {
            '/': (context) => const ReportsScreen(),
            '/reports/select-project': (context) =>
                const ProjectSelectionScreen(),
            '/reports/editor': (context) {
              final args = ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
              return ReportEditorScreen(
                projectId: args?['projectId'] as String?,
                report: args?['report'] as Report?,
              );
            },
          },
        ),
      );
    }

    testWidgets('navigates to Reports screen and taps New Report button',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Navigate to Reports screen - we're already there
      expect(find.text('Reports'), findsOneWidget);

      // Step 2: Tap 'New Report' button (FAB with + icon)
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Step 3: Verify project selection screen appears
      expect(find.text('Select Project'), findsOneWidget);
    });

    testWidgets('project selection screen shows available projects',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap FAB to go to project selection
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify projects are displayed
      expect(find.text('Construction Site A'), findsOneWidget);
      expect(find.text('Office Building B'), findsOneWidget);
    });

    testWidgets('selecting a project opens Report Editor screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to project selection
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 4: Select a project
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 5: Verify Report Editor screen opens
      expect(find.text('Report Editor'), findsOneWidget);
    });

    testWidgets('new report has auto-generated title with date',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to project selection
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Select a project
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 6: Verify report has auto-generated title with date
      final today = DateFormat('MMM d, yyyy').format(DateTime.now());
      expect(find.textContaining('Report'), findsWidgets);
      expect(find.textContaining(today), findsWidgets);
    });

    testWidgets('new report status is Draft', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to project selection
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Select a project
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 7: Verify report status is 'Draft'
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('full flow: tap New Report -> select project -> editor opens',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1-2: Navigate to Reports screen and tap 'New Report' button
      expect(find.text('Reports'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 3: Verify project selection screen appears
      expect(find.text('Select Project'), findsOneWidget);
      expect(find.text('Construction Site A'), findsOneWidget);
      expect(find.text('Office Building B'), findsOneWidget);

      // Step 4: Select a project
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 5: Verify Report Editor screen opens
      expect(find.text('Report Editor'), findsOneWidget);

      // Step 6: Verify report has auto-generated title with date
      final today = DateFormat('MMM d, yyyy').format(DateTime.now());
      // The title field should contain the date
      final titleText = find.textContaining(today);
      expect(titleText, findsWidgets);

      // Step 7: Verify report status is 'Draft'
      expect(find.text('Draft'), findsOneWidget);
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
  Future<Report> createReport(Report report) async {
    reports.add(report);
    state = AsyncData(reports);
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
