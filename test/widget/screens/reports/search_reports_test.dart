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
  group('User can search reports by keyword', () {
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
      ];

      testReports = [
        Report(
          id: 'report-1',
          projectId: 'proj-1',
          title: 'Site Inspection Report',
          notes: 'Foundation inspection completed',
          status: ReportStatus.complete,
          entryCount: 5,
          createdAt: DateTime(2026, 1, 30, 14, 30),
        ),
        Report(
          id: 'report-2',
          projectId: 'proj-2',
          title: 'Progress Update',
          notes: 'Electrical work in progress',
          status: ReportStatus.draft,
          entryCount: 2,
          createdAt: DateTime(2026, 1, 29, 10, 0),
        ),
        Report(
          id: 'report-3',
          projectId: 'proj-1',
          title: 'Safety Assessment',
          notes: 'All safety measures verified',
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

    testWidgets('search icon is visible in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('search_button')), findsOneWidget);
    });

    testWidgets('tapping search icon shows search field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      // Verify search field appears
      expect(find.byKey(const Key('search_field')), findsOneWidget);
    });

    testWidgets('results filter as typing', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially all reports are shown
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Safety Assessment'), findsOneWidget);

      // Tap search icon
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byKey(const Key('search_field')), 'Safety');
      await tester.pumpAndSettle();

      // Verify only matching report is shown
      expect(find.text('Safety Assessment'), findsOneWidget);
      expect(find.text('Site Inspection Report'), findsNothing);
      expect(find.text('Progress Update'), findsNothing);
    });

    testWidgets('search matches report titles', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      // Search for 'Inspection' which is in title
      await tester.enterText(
          find.byKey(const Key('search_field')), 'Inspection');
      await tester.pumpAndSettle();

      // Verify report with 'Inspection' in title is shown
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsNothing);
      expect(find.text('Safety Assessment'), findsNothing);
    });

    testWidgets('search matches entry content (notes)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      // Search for 'Electrical' which is in notes of report-2
      await tester.enterText(
          find.byKey(const Key('search_field')), 'Electrical');
      await tester.pumpAndSettle();

      // Verify report with matching notes is shown
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Site Inspection Report'), findsNothing);
      expect(find.text('Safety Assessment'), findsNothing);
    });

    testWidgets('clearing search shows all reports again', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byKey(const Key('search_field')), 'Safety');
      await tester.pumpAndSettle();

      // Verify filtered
      expect(find.text('Safety Assessment'), findsOneWidget);
      expect(find.text('Site Inspection Report'), findsNothing);

      // Clear search by tapping clear button
      await tester.tap(find.byKey(const Key('clear_search_button')));
      await tester.pumpAndSettle();

      // Verify all reports shown again
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);
      expect(find.text('Safety Assessment'), findsOneWidget);
    });

    testWidgets('search is case insensitive', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      // Search with lowercase
      await tester.enterText(find.byKey(const Key('search_field')), 'safety');
      await tester.pumpAndSettle();

      // Verify still matches
      expect(find.text('Safety Assessment'), findsOneWidget);
    });

    testWidgets('empty search shows no results message', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      // Search for something that doesn't exist
      await tester.enterText(
          find.byKey(const Key('search_field')), 'NonexistentTerm');
      await tester.pumpAndSettle();

      // Verify no reports shown
      expect(find.text('Site Inspection Report'), findsNothing);
      expect(find.text('Progress Update'), findsNothing);
      expect(find.text('Safety Assessment'), findsNothing);
      expect(find.text('No reports found'), findsOneWidget);
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
