import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard Screen Reader Accessibility', () {
    Widget buildTestWidget({
      DashboardStats? stats,
      List<RecentReport>? recentReports,
    }) {
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 5,
            pendingUploads: 2,
            totalProjects: 10,
            recentActivity: 3,
          );

      final testReports = recentReports ??
          [
            RecentReport(
              id: 'report-1',
              title: 'Site Inspection Report',
              projectName: 'Project Alpha',
              date: DateTime.now(),
              status: ReportStatus.complete,
            ),
            RecentReport(
              id: 'report-2',
              title: 'Progress Update',
              projectName: 'Project Beta',
              date: DateTime.now().subtract(const Duration(days: 1)),
              status: ReportStatus.draft,
            ),
          ];

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
        ),
      );
    }

    testWidgets('stat cards have semantic labels with labels and values',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify stat cards have proper semantics using RegExp to match label and value
      // 'Reports This Week' stat card with value 5
      expect(
        find.bySemanticsLabel(RegExp(r'Reports This Week.*5')),
        findsOneWidget,
        reason: 'Stat card should be read with label and value',
      );

      // 'Pending Uploads' stat card with value 2
      expect(
        find.bySemanticsLabel(RegExp(r'Pending Uploads.*2')),
        findsOneWidget,
        reason: 'Stat card should be read with label and value',
      );

      // 'Total Projects' stat card with value 10
      expect(
        find.bySemanticsLabel(RegExp(r'Total Projects.*10')),
        findsOneWidget,
        reason: 'Stat card should be read with label and value',
      );

      // 'Recent Activity' stat card with value 3
      expect(
        find.bySemanticsLabel(RegExp(r'Recent Activity.*3')),
        findsOneWidget,
        reason: 'Stat card should be read with label and value',
      );
    });

    testWidgets('recent reports list items are navigable', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify recent reports have proper semantics
      // Each report card should be accessible with title and project name
      expect(
        find.bySemanticsLabel(RegExp(r'Site Inspection Report.*Project Alpha')),
        findsOneWidget,
        reason: 'Report card should be read with title and project',
      );
    });

    testWidgets('FAB is announced as Quick capture button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find FAB with semantic label
      expect(
        find.bySemanticsLabel('Quick capture'),
        findsOneWidget,
        reason: 'FAB should be announced as Quick capture button',
      );

      // Verify the FAB semantics includes button trait
      final fabFinder = find.bySemanticsLabel('Quick capture');
      final semanticsNode = tester.getSemantics(fabFinder);
      expect(
        semanticsNode.hasFlag(SemanticsFlag.isButton),
        isTrue,
        reason: 'FAB should be marked as a button for screen readers',
      );
    });

    testWidgets('navigation elements are properly labeled', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify menu button has proper label
      expect(
        find.bySemanticsLabel('Open navigation menu'),
        findsOneWidget,
        reason: 'Menu button should have accessible label',
      );

      // Verify notification button has proper label
      expect(
        find.bySemanticsLabel('Notifications'),
        findsOneWidget,
        reason: 'Notification button should have accessible label',
      );
    });

    testWidgets('capture menu options are announced when expanded',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open capture menu by tapping the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify capture options have proper labels
      expect(
        find.bySemanticsLabel('Photo'),
        findsOneWidget,
        reason: 'Photo option should be accessible',
      );
      expect(
        find.bySemanticsLabel('Video'),
        findsOneWidget,
        reason: 'Video option should be accessible',
      );
      expect(
        find.bySemanticsLabel('Audio'),
        findsOneWidget,
        reason: 'Audio option should be accessible',
      );
      expect(
        find.bySemanticsLabel('Note'),
        findsOneWidget,
        reason: 'Note option should be accessible',
      );
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

/// Test notifier that returns preset recent reports
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  _TestRecentReportsNotifier(this._reports);

  final List<RecentReport> _reports;

  @override
  Future<List<RecentReport>> build() async {
    return _reports;
  }
}
