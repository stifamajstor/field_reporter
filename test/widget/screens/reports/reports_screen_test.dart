import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/reports_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';

void main() {
  group('User can view list of all reports', () {
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
          title: 'Site Inspection Report',
          status: ReportStatus.complete,
          entryCount: 5,
          createdAt: DateTime(2026, 1, 30, 14, 30),
          updatedAt: DateTime(2026, 1, 30, 15, 45),
        ),
        Report(
          id: 'report-2',
          projectId: 'proj-2',
          title: 'Progress Update',
          status: ReportStatus.draft,
          entryCount: 2,
          createdAt: DateTime(2026, 1, 29, 10, 0),
          updatedAt: DateTime(2026, 1, 29, 12, 30),
        ),
        Report(
          id: 'report-3',
          projectId: 'proj-1',
          title: 'Final Assessment',
          status: ReportStatus.processing,
          entryCount: 8,
          createdAt: DateTime(2026, 1, 28, 9, 15),
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
          home: const ReportsScreen(),
        ),
      );
    }

    testWidgets('displays list of reports', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify list is displayed
      expect(find.byType(ListView), findsOneWidget);

      // Verify all reports are shown
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Final Assessment'), findsOneWidget);
    });

    testWidgets('each report shows title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Final Assessment'), findsOneWidget);
    });

    testWidgets('each report shows project name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Report 1 and 3 are from proj-1, report 2 is from proj-2
      expect(find.text('Construction Site A'), findsNWidgets(2));
      expect(find.text('Office Building B'), findsOneWidget);
    });

    testWidgets('each report shows date', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify dates are shown (format may vary)
      expect(find.textContaining('Jan 30'), findsOneWidget);
      expect(find.textContaining('Jan 29'), findsOneWidget);
      expect(find.textContaining('Jan 28'), findsOneWidget);
    });

    testWidgets('each report shows status', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify status badges/indicators are shown
      expect(find.text('COMPLETE'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);
      expect(find.text('PROCESSING'), findsOneWidget);
    });

    testWidgets('entry count is shown for each report', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify entry counts
      expect(find.text('5 entries'), findsOneWidget);
      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('8 entries'), findsOneWidget);
    });

    testWidgets('reports sorted by most recent first', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find all report titles in order
      final titles = tester
          .widgetList<Text>(find.byType(Text))
          .where((text) =>
              text.data == 'Site Inspection Report' ||
              text.data == 'Progress Update' ||
              text.data == 'Final Assessment')
          .map((t) => t.data)
          .toList();

      // Verify order: Jan 30 (report-1), Jan 29 (report-2), Jan 28 (report-3)
      expect(titles.first, equals('Site Inspection Report'));
    });

    testWidgets('shows empty state when no reports', (tester) async {
      await tester.pumpWidget(createTestWidget(reports: []));
      await tester.pumpAndSettle();

      expect(find.text('No reports yet'), findsOneWidget);
    });

    testWidgets('screen has correct title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Reports'), findsOneWidget);
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
