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
  group('User can filter reports by status', () {
    late List<Report> testReports;
    late List<Project> testProjects;

    setUp(() {
      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Project A',
          status: ProjectStatus.active,
        ),
      ];

      testReports = [
        Report(
          id: 'report-1',
          projectId: 'proj-1',
          title: 'Draft Report 1',
          status: ReportStatus.draft,
          entryCount: 2,
          createdAt: DateTime(2026, 1, 30),
        ),
        Report(
          id: 'report-2',
          projectId: 'proj-1',
          title: 'Draft Report 2',
          status: ReportStatus.draft,
          entryCount: 3,
          createdAt: DateTime(2026, 1, 29),
        ),
        Report(
          id: 'report-3',
          projectId: 'proj-1',
          title: 'Processing Report',
          status: ReportStatus.processing,
          entryCount: 5,
          createdAt: DateTime(2026, 1, 28),
        ),
        Report(
          id: 'report-4',
          projectId: 'proj-1',
          title: 'Complete Report 1',
          status: ReportStatus.complete,
          entryCount: 8,
          createdAt: DateTime(2026, 1, 27),
        ),
        Report(
          id: 'report-5',
          projectId: 'proj-1',
          title: 'Complete Report 2',
          status: ReportStatus.complete,
          entryCount: 6,
          createdAt: DateTime(2026, 1, 26),
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

    testWidgets('filter button is visible on Reports screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('filter_button')), findsOneWidget);
    });

    testWidgets('tapping filter button shows filter options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Verify filter options: All, Draft, Processing, Complete
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('selecting Draft filter shows only draft reports',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially all reports are shown
      expect(find.text('Draft Report 1'), findsOneWidget);
      expect(find.text('Draft Report 2'), findsOneWidget);
      expect(find.text('Processing Report'), findsOneWidget);
      expect(find.text('Complete Report 1'), findsOneWidget);
      expect(find.text('Complete Report 2'), findsOneWidget);

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Select Draft
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();

      // Verify only draft reports shown
      expect(find.text('Draft Report 1'), findsOneWidget);
      expect(find.text('Draft Report 2'), findsOneWidget);
      expect(find.text('Processing Report'), findsNothing);
      expect(find.text('Complete Report 1'), findsNothing);
      expect(find.text('Complete Report 2'), findsNothing);
    });

    testWidgets('selecting Complete filter shows only complete reports',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Select Complete
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      // Verify only complete reports shown
      expect(find.text('Draft Report 1'), findsNothing);
      expect(find.text('Draft Report 2'), findsNothing);
      expect(find.text('Processing Report'), findsNothing);
      expect(find.text('Complete Report 1'), findsOneWidget);
      expect(find.text('Complete Report 2'), findsOneWidget);
    });

    testWidgets('selecting Processing filter shows only processing reports',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Select Processing
      await tester.tap(find.text('Processing'));
      await tester.pumpAndSettle();

      // Verify only processing reports shown
      expect(find.text('Draft Report 1'), findsNothing);
      expect(find.text('Draft Report 2'), findsNothing);
      expect(find.text('Processing Report'), findsOneWidget);
      expect(find.text('Complete Report 1'), findsNothing);
      expect(find.text('Complete Report 2'), findsNothing);
    });

    testWidgets('selecting All filter shows all reports', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // First apply a filter
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Draft'));
      await tester.pumpAndSettle();

      // Verify only drafts shown
      expect(find.text('Processing Report'), findsNothing);

      // Clear filter by selecting All
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Verify all reports shown
      expect(find.text('Draft Report 1'), findsOneWidget);
      expect(find.text('Draft Report 2'), findsOneWidget);
      expect(find.text('Processing Report'), findsOneWidget);
      expect(find.text('Complete Report 1'), findsOneWidget);
      expect(find.text('Complete Report 2'), findsOneWidget);
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
