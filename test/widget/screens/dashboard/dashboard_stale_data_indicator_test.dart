import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/services/connectivity_service.dart';
import 'package:field_reporter/widgets/indicators/stale_data_indicator.dart';

void main() {
  group('Dashboard indicates stale data with timestamp', () {
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
    ];

    Widget buildTestWidget({
      required bool isOnline,
      DateTime? lastUpdated,
    }) {
      final connectivityService = ConnectivityService()..setOnline(isOnline);

      return ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivityService),
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(cachedStats, lastUpdated),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(cachedReports),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Step 1-2: Navigate to Dashboard while online - no stale indicator',
        (tester) async {
      // Navigate to Dashboard while online
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Online mode should not show stale data indicator
      expect(find.byType(StaleDataIndicator), findsNothing);
    });

    testWidgets('Step 3-5: After going offline, shows last updated message',
        (tester) async {
      // Simulate going offline with data that was last updated 5 minutes ago
      final lastUpdated = DateTime.now().subtract(const Duration(minutes: 5));

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      // Verify 'Last updated X minutes ago' message appears
      expect(find.byType(StaleDataIndicator), findsOneWidget);
      expect(find.textContaining('Last updated'), findsOneWidget);
      expect(find.textContaining('minutes ago'), findsOneWidget);
    });

    testWidgets('Step 6: Visual indicator that data may be stale', (tester) async {
      // Simulate offline with stale data
      final lastUpdated = DateTime.now().subtract(const Duration(minutes: 10));

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      // Verify visual stale data indicator exists
      expect(find.byKey(const Key('stale_data_indicator')), findsOneWidget);

      // Verify it has a warning/info icon
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('Shows "Just now" for very recent data', (tester) async {
      final lastUpdated = DateTime.now().subtract(const Duration(seconds: 30));

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(StaleDataIndicator), findsOneWidget);
      expect(find.textContaining('Just now'), findsOneWidget);
    });

    testWidgets('Shows "1 minute ago" for data updated 1 minute ago', (tester) async {
      final lastUpdated = DateTime.now().subtract(const Duration(minutes: 1, seconds: 30));

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 minute ago'), findsOneWidget);
    });

    testWidgets('Shows "X hours ago" for data updated hours ago', (tester) async {
      final lastUpdated = DateTime.now().subtract(const Duration(hours: 2));

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 hours ago'), findsOneWidget);
    });

    testWidgets('Stale indicator uses warning color when data is old',
        (tester) async {
      // Data that is 30+ minutes old should show warning styling
      final lastUpdated = DateTime.now().subtract(const Duration(minutes: 35));

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      final indicator = find.byType(StaleDataIndicator);
      expect(indicator, findsOneWidget);

      // The indicator should exist and be styled appropriately
      final staleWidget = tester.widget<StaleDataIndicator>(indicator);
      expect(staleWidget.lastUpdated, equals(lastUpdated));
    });

    testWidgets('Stale indicator not shown when online', (tester) async {
      // Even with a lastUpdated time, online mode shouldn't show stale indicator
      final lastUpdated = DateTime.now().subtract(const Duration(minutes: 30));

      await tester.pumpWidget(buildTestWidget(
        isOnline: true,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(StaleDataIndicator), findsNothing);
    });

    testWidgets('Pull to refresh while offline still shows stale indicator',
        (tester) async {
      final lastUpdated = DateTime.now().subtract(const Duration(minutes: 5));

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        lastUpdated: lastUpdated,
      ));
      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Stale indicator should still be visible
      expect(find.byType(StaleDataIndicator), findsOneWidget);
    });
  });
}

/// Test notifier that returns preset stats with last updated timestamp.
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  _TestDashboardStatsNotifier(this._stats, this._lastUpdated);

  final DashboardStats _stats;
  final DateTime? _lastUpdated;

  @override
  Future<DashboardStats> build() async {
    return _stats;
  }

  @override
  DateTime? get lastUpdated => _lastUpdated;
}

/// Test notifier that returns preset recent reports.
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  _TestRecentReportsNotifier(this._reports);

  final List<RecentReport> _reports;

  @override
  Future<List<RecentReport>> build() async {
    return _reports;
  }
}
