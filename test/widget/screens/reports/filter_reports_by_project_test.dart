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
  group('User can filter reports by project', () {
    late List<Report> testReports;
    late List<Project> testProjects;

    setUp(() {
      testProjects = [
        const Project(
          id: 'proj-1',
          name: 'Construction Site A',
          status: ProjectStatus.active,
        ),
        const Project(
          id: 'proj-2',
          name: 'Office Building B',
          status: ProjectStatus.active,
        ),
        const Project(
          id: 'proj-3',
          name: 'Warehouse C',
          status: ProjectStatus.completed,
        ),
      ];

      testReports = [
        Report(
          id: 'report-1',
          projectId: 'proj-1',
          title: 'Site Inspection Report',
          status: ReportStatus.complete,
          entryCount: 5,
          createdAt: DateTime(2026, 1, 30),
        ),
        Report(
          id: 'report-2',
          projectId: 'proj-1',
          title: 'Progress Update',
          status: ReportStatus.draft,
          entryCount: 3,
          createdAt: DateTime(2026, 1, 29),
        ),
        Report(
          id: 'report-3',
          projectId: 'proj-2',
          title: 'Office Assessment',
          status: ReportStatus.complete,
          entryCount: 8,
          createdAt: DateTime(2026, 1, 28),
        ),
        Report(
          id: 'report-4',
          projectId: 'proj-3',
          title: 'Warehouse Inventory',
          status: ReportStatus.draft,
          entryCount: 2,
          createdAt: DateTime(2026, 1, 27),
        ),
      ];
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: testReports);
          }),
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: testProjects);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const ReportsScreen(),
        ),
      );
    }

    testWidgets('tapping filter button shows project filter option',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Verify project filter section is visible
      expect(find.text('Filter by Project'), findsOneWidget);
    });

    testWidgets('project filter shows list of available projects',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Verify list of projects is displayed in filter menu using keys
      expect(find.byKey(const Key('project_filter_proj-1')), findsOneWidget);
      expect(find.byKey(const Key('project_filter_proj-2')), findsOneWidget);
      expect(find.byKey(const Key('project_filter_proj-3')), findsOneWidget);
    });

    testWidgets('selecting a project filters reports to only that project',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially all reports are shown
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Office Assessment'), findsOneWidget);
      expect(find.text('Warehouse Inventory'), findsOneWidget);

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Select Construction Site A project using key
      await tester.tap(find.byKey(const Key('project_filter_proj-1')));
      await tester.pumpAndSettle();

      // Verify only reports from Construction Site A are shown
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Office Assessment'), findsNothing);
      expect(find.text('Warehouse Inventory'), findsNothing);
    });

    testWidgets('selecting different project updates filter correctly',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button and select Office Building B
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('project_filter_proj-2')));
      await tester.pumpAndSettle();

      // Verify only reports from Office Building B are shown
      expect(find.text('Site Inspection Report'), findsNothing);
      expect(find.text('Progress Update'), findsNothing);
      expect(find.text('Office Assessment'), findsOneWidget);
      expect(find.text('Warehouse Inventory'), findsNothing);
    });

    testWidgets('clearing project filter shows all reports', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Apply project filter first
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('project_filter_proj-1')));
      await tester.pumpAndSettle();

      // Verify filter is applied
      expect(find.text('Office Assessment'), findsNothing);

      // Open filter and select 'All Projects'
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('all_projects_filter')));
      await tester.pumpAndSettle();

      // Verify all reports are shown
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Office Assessment'), findsOneWidget);
      expect(find.text('Warehouse Inventory'), findsOneWidget);
    });

    testWidgets('filter button indicates active project filter',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Apply project filter
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('project_filter_proj-1')));
      await tester.pumpAndSettle();

      // Verify filter button shows filled icon (active filter)
      final filterIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('filter_button')),
          matching: find.byType(Icon),
        ),
      );
      expect(filterIcon.icon, Icons.filter_alt);
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
