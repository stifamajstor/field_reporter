import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';

void main() {
  group('User can view all reports within a project', () {
    late List<Project> testProjects;
    late List<Report> testReports;

    setUp(() {
      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Construction Site Alpha',
          description: 'Main construction project',
          address: '123 Main St, New York',
          status: ProjectStatus.active,
          reportCount: 3,
          lastActivityAt: DateTime(2026, 1, 30, 10, 30),
        ),
      ];

      testReports = [
        Report(
          id: 'report-1',
          projectId: 'proj-1',
          title: 'Initial Site Inspection',
          status: ReportStatus.complete,
          entryCount: 5,
          createdAt: DateTime(2026, 1, 28, 9, 0),
        ),
        Report(
          id: 'report-2',
          projectId: 'proj-1',
          title: 'Foundation Progress',
          status: ReportStatus.draft,
          entryCount: 3,
          createdAt: DateTime(2026, 1, 29, 14, 30),
        ),
        Report(
          id: 'report-3',
          projectId: 'proj-1',
          title: 'Safety Compliance Check',
          status: ReportStatus.processing,
          entryCount: 8,
          createdAt: DateTime(2026, 1, 30, 11, 15),
        ),
      ];
    });

    Widget createProjectDetailScreen({
      required String projectId,
      List<Project>? projects,
      List<Report>? reports,
      VoidCallback? onReportTap,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects ?? testProjects);
          }),
          projectReportsNotifierProvider(projectId).overrideWith(() {
            return _MockProjectReportsNotifier(reports: reports ?? testReports);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ProjectDetailScreen(projectId: projectId),
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/reports/') ?? false) {
              onReportTap?.call();
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Report Detail Screen')),
                ),
              );
            }
            return null;
          },
        ),
      );
    }

    testWidgets('displays Reports section when navigating to Project Detail',
        (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify Reports section header is visible
      expect(find.text('Reports'), findsOneWidget);
    });

    testWidgets('lists all reports for this project', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Scroll to ensure all reports are visible
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Verify all reports are listed
      expect(find.text('Initial Site Inspection'), findsOneWidget);
      expect(find.text('Foundation Progress'), findsOneWidget);
      expect(find.text('Safety Compliance Check'), findsOneWidget);
    });

    testWidgets('each report shows title', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify report titles are displayed
      expect(find.text('Initial Site Inspection'), findsOneWidget);
      expect(find.text('Foundation Progress'), findsOneWidget);
      expect(find.text('Safety Compliance Check'), findsOneWidget);
    });

    testWidgets('each report shows date', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify dates are displayed (formatted)
      expect(find.textContaining('Jan 28'), findsOneWidget);
      expect(find.textContaining('Jan 29'), findsOneWidget);
      expect(find.textContaining('Jan 30'), findsOneWidget);
    });

    testWidgets('each report shows status', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Scroll to ensure all reports are visible
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Verify status badges are displayed
      expect(find.text('COMPLETE'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('PROCESSING'), findsOneWidget);
    });

    testWidgets('report count matches displayed list', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify count text matches the actual list
      expect(find.text('3 reports'), findsOneWidget);

      // Count report items in the list using the project_report_item key
      expect(find.byKey(const Key('project_report_item_0')), findsOneWidget);
      expect(find.byKey(const Key('project_report_item_1')), findsOneWidget);
      expect(find.byKey(const Key('project_report_item_2')), findsOneWidget);
    });

    testWidgets('tapping on a report navigates to Report Detail',
        (tester) async {
      var navigatedToReport = false;

      await tester.pumpWidget(createProjectDetailScreen(
        projectId: 'proj-1',
        onReportTap: () => navigatedToReport = true,
      ));
      await tester.pumpAndSettle();

      // Tap on a report
      await tester.tap(find.text('Initial Site Inspection'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(navigatedToReport, isTrue);
      expect(find.text('Report Detail Screen'), findsOneWidget);
    });

    testWidgets('shows empty state when project has no reports',
        (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(
        projectId: 'proj-1',
        projects: [
          Project(
            id: 'proj-1',
            name: 'Empty Project',
            status: ProjectStatus.active,
            reportCount: 0,
          ),
        ],
        reports: [],
      ));
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('No reports yet'), findsOneWidget);
    });
  });
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

/// Mock ProjectReportsNotifier for testing
class _MockProjectReportsNotifier extends ProjectReportsNotifier {
  final List<Report> reports;

  _MockProjectReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build(String projectId) async {
    return reports;
  }
}
