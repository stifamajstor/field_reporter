import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/services/connectivity_service.dart';
import 'package:field_reporter/widgets/cards/stat_card.dart';
import 'package:field_reporter/widgets/cards/report_card.dart';

void main() {
  group('Dashboard displays cached data when offline', () {
    /// Cached statistics to display when offline.
    const cachedStats = DashboardStats(
      reportsThisWeek: 7,
      pendingUploads: 2,
      totalProjects: 5,
      recentActivity: 15,
    );

    /// Cached recent reports to display when offline.
    final cachedReports = [
      RecentReport(
        id: '1',
        title: 'Cached Site Report',
        projectName: 'Offline Project A',
        date: DateTime(2026, 1, 29),
        status: ReportStatus.complete,
      ),
      RecentReport(
        id: '2',
        title: 'Cached Progress Update',
        projectName: 'Offline Project B',
        date: DateTime(2026, 1, 28),
        status: ReportStatus.draft,
      ),
      RecentReport(
        id: '3',
        title: 'Cached Safety Audit',
        projectName: 'Offline Project C',
        date: DateTime(2026, 1, 27),
        status: ReportStatus.processing,
      ),
    ];

    Widget buildTestWidget({
      required bool isOnline,
      DashboardStats? stats,
      List<RecentReport>? reports,
    }) {
      final testStats = stats ?? cachedStats;
      final testReports = reports ?? cachedReports;

      final connectivityService = ConnectivityService()..setOnline(isOnline);

      return ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivityService),
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(testReports),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Online: statistics and reports are displayed', (tester) async {
      // Step 1: Login and navigate to Dashboard while online
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Step 2: Note displayed statistics
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Pending Uploads'), findsAtLeastNWidgets(1));
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Note displayed reports
      expect(find.text('Recent Reports'), findsOneWidget);
      expect(find.text('Cached Site Report'), findsOneWidget);
    });

    testWidgets('Offline: cached statistics are displayed', (tester) async {
      // Step 3-5: Enable airplane mode, force close and reopen app, navigate to Dashboard
      // Simulated by starting the app in offline mode with cached data
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Step 6: Verify cached statistics are displayed
      expect(find.byType(StatCard), findsNWidgets(4));
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Offline: cached recent reports are displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Step 7: Verify cached recent reports are displayed
      expect(find.text('Recent Reports'), findsOneWidget);
      expect(find.byType(ReportCard), findsNWidgets(3));
      expect(find.text('Cached Site Report'), findsOneWidget);
      expect(find.text('Offline Project A'), findsOneWidget);
      expect(find.text('Cached Progress Update'), findsOneWidget);
      expect(find.text('Cached Safety Audit'), findsOneWidget);
    });

    testWidgets('Offline: offline indicator is shown', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Step 8: Verify offline indicator is shown
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('Offline indicator shows cloud_off icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify offline indicator has appropriate icon
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('Offline indicator is not shown when online', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Offline indicator should NOT be shown when online
      expect(find.byKey(const Key('offline_indicator')), findsNothing);
    });

    testWidgets('All stat cards remain interactive when offline',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify stat cards are still tappable
      final statCard = find.byType(StatCard).first;
      final gestureDetector = find.descendant(
        of: statCard,
        matching: find.byType(GestureDetector),
      );

      expect(
        gestureDetector.evaluate().isNotEmpty,
        isTrue,
        reason: 'Stat cards should remain tappable when offline',
      );
    });

    testWidgets('Report cards remain interactive when offline', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify report cards are still tappable
      final reportCard = find.byType(ReportCard).first;
      final gestureDetector = find.descendant(
        of: reportCard,
        matching: find.byType(GestureDetector),
      );

      expect(
        gestureDetector.evaluate().isNotEmpty,
        isTrue,
        reason: 'Report cards should remain tappable when offline',
      );
    });
  });
}

/// Test notifier that returns preset stats (simulating cached data).
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  _TestDashboardStatsNotifier(this._stats);

  final DashboardStats _stats;

  @override
  Future<DashboardStats> build() async {
    return _stats;
  }
}

/// Test notifier that returns preset recent reports (simulating cached data).
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  _TestRecentReportsNotifier(this._reports);

  final List<RecentReport> _reports;

  @override
  Future<List<RecentReport>> build() async {
    return _reports;
  }
}
