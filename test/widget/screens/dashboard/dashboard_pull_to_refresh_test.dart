import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';

void main() {
  group('Pull-to-refresh updates dashboard data', () {
    late _TestDashboardStatsNotifier statsNotifier;
    late _TestRecentReportsNotifier reportsNotifier;
    late _TestPendingUploadsNotifier uploadsNotifier;

    Widget buildTestWidget() {
      statsNotifier = _TestDashboardStatsNotifier();
      reportsNotifier = _TestRecentReportsNotifier();
      uploadsNotifier = _TestPendingUploadsNotifier();

      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(() => statsNotifier),
          recentReportsNotifierProvider.overrideWith(() => reportsNotifier),
          pendingUploadsNotifierProvider.overrideWith(() => uploadsNotifier),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Dashboard has RefreshIndicator for pull-to-refresh',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify RefreshIndicator is present
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('Pull down shows refresh indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find scrollable content
      final scrollable = find.byType(Scrollable).first;

      // Pull down to trigger refresh
      await tester.fling(scrollable, const Offset(0, 300), 1000);
      await tester.pump();

      // Refresh indicator should be visible during refresh
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    });

    testWidgets('Pull-to-refresh calls refresh on stats provider',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initial stats
      expect(find.text('12'), findsOneWidget); // reportsThisWeek

      // Update stats for refresh
      statsNotifier.setNextStats(
        const DashboardStats(
          reportsThisWeek: 15,
          pendingUploads: 5,
          totalProjects: 10,
          recentActivity: 30,
        ),
      );

      // Pull down to refresh
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify stats were refreshed
      expect(statsNotifier.refreshCalled, isTrue);
      expect(find.text('15'), findsOneWidget); // Updated reportsThisWeek
    });

    testWidgets('Pull-to-refresh calls refresh on reports provider',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initial report
      expect(find.text('Site Inspection Report'), findsOneWidget);

      // Update reports for refresh
      reportsNotifier.setNextReports([
        RecentReport(
          id: '10',
          title: 'New Updated Report',
          projectName: 'New Project',
          date: DateTime(2026, 1, 30),
          status: ReportStatus.complete,
        ),
      ]);

      // Pull down to refresh
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify reports were refreshed
      expect(reportsNotifier.refreshCalled, isTrue);
      expect(find.text('New Updated Report'), findsOneWidget);
    });

    testWidgets('Statistics update after refresh if data changed',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Note current statistics values
      expect(find.text('12'), findsOneWidget); // reportsThisWeek
      expect(find.text('3'), findsOneWidget); // pendingUploads
      expect(find.text('8'), findsOneWidget); // totalProjects

      // Update stats for refresh
      statsNotifier.setNextStats(
        const DashboardStats(
          reportsThisWeek: 20,
          pendingUploads: 0,
          totalProjects: 12,
          recentActivity: 50,
        ),
      );

      // Pull down to refresh
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify statistics updated
      expect(find.text('20'), findsOneWidget); // Updated reportsThisWeek
      expect(find.text('0'), findsOneWidget); // Updated pendingUploads
      expect(find.text('12'), findsOneWidget); // Updated totalProjects
    });

    testWidgets('Recent reports list updates after refresh', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Note initial reports
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update'), findsOneWidget);

      // Update reports for refresh
      reportsNotifier.setNextReports([
        RecentReport(
          id: '100',
          title: 'Brand New Report',
          projectName: 'Updated Project',
          date: DateTime(2026, 1, 30),
          status: ReportStatus.draft,
        ),
        RecentReport(
          id: '101',
          title: 'Another Fresh Report',
          projectName: 'Fresh Project',
          date: DateTime(2026, 1, 29),
          status: ReportStatus.complete,
        ),
      ]);

      // Pull down to refresh
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Verify recent reports list updated
      expect(find.text('Site Inspection Report'), findsNothing);
      expect(find.text('Brand New Report'), findsOneWidget);
      expect(find.text('Another Fresh Report'), findsOneWidget);
    });
  });
}

/// Test notifier that tracks refresh calls and allows setting next stats
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  bool refreshCalled = false;
  DashboardStats _nextStats = const DashboardStats(
    reportsThisWeek: 12,
    pendingUploads: 3,
    totalProjects: 8,
    recentActivity: 24,
  );

  void setNextStats(DashboardStats stats) {
    _nextStats = stats;
  }

  @override
  Future<DashboardStats> build() async {
    return _nextStats;
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Test notifier that tracks refresh calls and allows setting next reports
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  bool refreshCalled = false;
  List<RecentReport> _nextReports = [
    RecentReport(
      id: '1',
      title: 'Site Inspection Report',
      projectName: 'Construction Site A',
      date: DateTime(2026, 1, 29),
      status: ReportStatus.complete,
    ),
    RecentReport(
      id: '2',
      title: 'Progress Update',
      projectName: 'Building B',
      date: DateTime(2026, 1, 28),
      status: ReportStatus.draft,
    ),
    RecentReport(
      id: '3',
      title: 'Safety Audit',
      projectName: 'Warehouse C',
      date: DateTime(2026, 1, 27),
      status: ReportStatus.processing,
    ),
  ];

  void setNextReports(List<RecentReport> reports) {
    _nextReports = reports;
  }

  @override
  Future<List<RecentReport>> build() async {
    return _nextReports;
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Test notifier for pending uploads
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  @override
  Future<List<PendingUpload>> build() async {
    return [];
  }
}
