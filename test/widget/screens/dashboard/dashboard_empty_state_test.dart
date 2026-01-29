import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/widgets/layout/empty_state.dart';

void main() {
  group('Empty state displayed when no data exists', () {
    Widget buildTestWidget({
      DashboardStats? stats,
      List<RecentReport>? reports,
      Map<String, WidgetBuilder>? routes,
    }) {
      // Default to empty stats for new account scenario
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 0,
            pendingUploads: 0,
            totalProjects: 0,
            recentActivity: 0,
          );

      final testReports = reports ?? <RecentReport>[];

      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(testReports),
          ),
        ],
        child: MaterialApp(
          home: const DashboardScreen(),
          routes: routes ?? {},
        ),
      );
    }

    testWidgets(
        'Empty state illustration is displayed when no projects/reports exist',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify empty state widget is displayed
      expect(find.byType(EmptyState), findsOneWidget);

      // Verify illustration icon is displayed
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('Helpful message explaining how to get started is displayed',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify title message
      expect(find.text('No projects yet'), findsOneWidget);

      // Verify helpful description message
      expect(
        find.text('Create your first project to start capturing reports.'),
        findsOneWidget,
      );
    });

    testWidgets('Create First Project button is prominent', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify the 'Create First Project' button is displayed
      expect(find.text('Create First Project'), findsOneWidget);

      // Verify button is visible and prominent (PrimaryButton or similar)
      final buttonFinder = find.widgetWithText(
        GestureDetector,
        'Create First Project',
      );
      expect(buttonFinder, findsOneWidget);
    });

    testWidgets(
        'Tapping Create First Project button navigates to project creation',
        (tester) async {
      bool navigatedToProjectCreation = false;

      await tester.pumpWidget(
        buildTestWidget(
          routes: {
            '/projects/create': (context) {
              navigatedToProjectCreation = true;
              return const Scaffold(body: Text('Create Project Screen'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the 'Create First Project' button
      final button = find.text('Create First Project');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verify navigation to project creation screen
      expect(navigatedToProjectCreation, isTrue);
    });

    testWidgets('Empty state is NOT displayed when data exists',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          stats: const DashboardStats(
            reportsThisWeek: 5,
            pendingUploads: 2,
            totalProjects: 3,
            recentActivity: 10,
          ),
          reports: [
            RecentReport(
              id: '1',
              title: 'Test Report',
              projectName: 'Test Project',
              date: DateTime.now(),
              status: ReportStatus.complete,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state is NOT displayed
      expect(find.byType(EmptyState), findsNothing);
      expect(find.text('No projects yet'), findsNothing);
    });

    testWidgets(
        'Empty state shown when totalProjects is 0 even with other stats',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          stats: const DashboardStats(
            reportsThisWeek: 0,
            pendingUploads: 0,
            totalProjects: 0,
            recentActivity: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty state is displayed when no projects
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });
}

/// Test notifier that returns preset stats
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  _TestDashboardStatsNotifier(this._stats);

  final DashboardStats _stats;

  @override
  Future<DashboardStats> build() async {
    return _stats;
  }
}

/// Test notifier that returns preset reports
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  _TestRecentReportsNotifier(this._reports);

  final List<RecentReport> _reports;

  @override
  Future<List<RecentReport>> build() async {
    return _reports;
  }
}
