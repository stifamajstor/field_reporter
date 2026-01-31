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
  group('User can filter reports by date range', () {
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

      // Reports spread across different dates
      testReports = [
        Report(
          id: 'report-1',
          projectId: 'proj-1',
          title: 'January 25 Report',
          status: ReportStatus.complete,
          entryCount: 2,
          createdAt: DateTime(2026, 1, 25),
        ),
        Report(
          id: 'report-2',
          projectId: 'proj-1',
          title: 'January 26 Report',
          status: ReportStatus.complete,
          entryCount: 3,
          createdAt: DateTime(2026, 1, 26),
        ),
        Report(
          id: 'report-3',
          projectId: 'proj-1',
          title: 'January 27 Report',
          status: ReportStatus.complete,
          entryCount: 5,
          createdAt: DateTime(2026, 1, 27),
        ),
        Report(
          id: 'report-4',
          projectId: 'proj-1',
          title: 'January 28 Report',
          status: ReportStatus.complete,
          entryCount: 8,
          createdAt: DateTime(2026, 1, 28),
        ),
        Report(
          id: 'report-5',
          projectId: 'proj-1',
          title: 'January 29 Report',
          status: ReportStatus.complete,
          entryCount: 6,
          createdAt: DateTime(2026, 1, 29),
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

    testWidgets('Navigate to Reports screen', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Reports screen is shown
      expect(find.text('Reports'), findsOneWidget);
      expect(find.byKey(const Key('filter_button')), findsOneWidget);
    });

    testWidgets('Tap filter button shows date range option', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Scroll to see date range filter section
      await tester.drag(
        find.text('Filter by Status'),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Verify date range filter option is visible
      expect(find.text('Filter by Date Range'), findsOneWidget);
    });

    testWidgets('Select date range filter shows date pickers', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Scroll to see date range filter section
      await tester.drag(
        find.text('Filter by Status'),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Tap date range option
      await tester.tap(find.byKey(const Key('date_range_filter_option')));
      await tester.pumpAndSettle();

      // Verify date range picker dialog is shown
      expect(find.byKey(const Key('date_range_picker_dialog')), findsOneWidget);
    });

    testWidgets('Select start and end date then apply filter', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially all 5 reports visible
      expect(find.text('January 25 Report'), findsOneWidget);
      expect(find.text('January 26 Report'), findsOneWidget);
      expect(find.text('January 27 Report'), findsOneWidget);
      expect(find.text('January 28 Report'), findsOneWidget);
      expect(find.text('January 29 Report'), findsOneWidget);

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Scroll to see date range filter section
      await tester.drag(
        find.text('Filter by Status'),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Tap date range option
      await tester.tap(find.byKey(const Key('date_range_filter_option')));
      await tester.pumpAndSettle();

      // Select start date (Jan 26)
      await tester.tap(find.byKey(const Key('start_date_field')));
      await tester.pumpAndSettle();

      // Find and tap the 26th day in the date picker
      await tester.tap(find.text('26'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select end date (Jan 28)
      await tester.tap(find.byKey(const Key('end_date_field')));
      await tester.pumpAndSettle();

      // Find and tap the 28th day in the date picker
      await tester.tap(find.text('28'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Apply the filter
      await tester.tap(find.byKey(const Key('apply_date_filter_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Verify only reports within date range shown', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap filter button
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Scroll to see date range filter section
      await tester.drag(
        find.text('Filter by Status'),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Tap date range option
      await tester.tap(find.byKey(const Key('date_range_filter_option')));
      await tester.pumpAndSettle();

      // Select start date (Jan 26)
      await tester.tap(find.byKey(const Key('start_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('26'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select end date (Jan 28)
      await tester.tap(find.byKey(const Key('end_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Apply the filter
      await tester.tap(find.byKey(const Key('apply_date_filter_button')));
      await tester.pumpAndSettle();

      // Verify only reports within Jan 26-28 are shown
      expect(find.text('January 25 Report'), findsNothing);
      expect(find.text('January 26 Report'), findsOneWidget);
      expect(find.text('January 27 Report'), findsOneWidget);
      expect(find.text('January 28 Report'), findsOneWidget);
      expect(find.text('January 29 Report'), findsNothing);
    });

    testWidgets('Clear date range filter shows all reports', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Apply date range filter first
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Scroll to see date range filter section
      await tester.drag(
        find.text('Filter by Status'),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('date_range_filter_option')));
      await tester.pumpAndSettle();

      // Select dates
      await tester.tap(find.byKey(const Key('start_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('26'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('end_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('28'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('apply_date_filter_button')));
      await tester.pumpAndSettle();

      // Verify filter applied
      expect(find.text('January 25 Report'), findsNothing);

      // Now clear the date filter
      await tester.tap(find.byKey(const Key('filter_button')));
      await tester.pumpAndSettle();

      // Scroll to see clear option
      await tester.drag(
        find.text('Filter by Status'),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('clear_date_filter_option')));
      await tester.pumpAndSettle();

      // Verify all reports shown again
      expect(find.text('January 25 Report'), findsOneWidget);
      expect(find.text('January 26 Report'), findsOneWidget);
      expect(find.text('January 27 Report'), findsOneWidget);
      expect(find.text('January 28 Report'), findsOneWidget);
      expect(find.text('January 29 Report'), findsOneWidget);
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
