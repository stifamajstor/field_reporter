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
  group('Dashboard handles API error gracefully', () {
    /// Cached stats to show when API fails but cache is available.
    const cachedStats = DashboardStats(
      reportsThisWeek: 5,
      pendingUploads: 1,
      totalProjects: 3,
      recentActivity: 10,
    );

    /// Cached reports to show when API fails but cache is available.
    final cachedReports = [
      RecentReport(
        id: '1',
        title: 'Cached Report',
        projectName: 'Cached Project',
        date: DateTime(2026, 1, 29),
        status: ReportStatus.complete,
      ),
    ];

    Widget buildTestWidget({
      required _TestDashboardStatsNotifier statsNotifier,
      required _TestRecentReportsNotifier reportsNotifier,
    }) {
      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(() => statsNotifier),
          recentReportsNotifierProvider.overrideWith(() => reportsNotifier),
          pendingUploadsNotifierProvider
              .overrideWith(() => _TestPendingUploadsNotifier()),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('API error displays error message', (tester) async {
      // Step 1-2: Navigate to Dashboard and simulate API error
      final statsNotifier = _TestDashboardStatsNotifier.withError(
        Exception('Server error: 500'),
      );
      final reportsNotifier = _TestRecentReportsNotifier.withError(
        Exception('Server error: 500'),
      );

      await tester.pumpWidget(buildTestWidget(
        statsNotifier: statsNotifier,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Step 3: Verify error message is displayed
      expect(find.text('Something went wrong'), findsOneWidget,
          reason: 'Error message should be displayed when API fails');
    });

    testWidgets('Cached data is shown when API fails with cache available',
        (tester) async {
      // Step 4: Verify cached data is shown if available
      final statsNotifier = _TestDashboardStatsNotifier.withErrorAndCache(
        error: Exception('Server error: 500'),
        cachedStats: cachedStats,
      );
      final reportsNotifier = _TestRecentReportsNotifier.withErrorAndCache(
        error: Exception('Server error: 500'),
        cachedReports: cachedReports,
      );

      await tester.pumpWidget(buildTestWidget(
        statsNotifier: statsNotifier,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Cached stats should be displayed
      expect(find.text('5'), findsOneWidget,
          reason: 'Cached reportsThisWeek should be displayed');
      expect(find.text('Cached Report'), findsOneWidget,
          reason: 'Cached reports should be displayed');
    });

    testWidgets('Retry button is displayed on API error', (tester) async {
      // Step 5: Verify 'Retry' button is displayed
      final statsNotifier = _TestDashboardStatsNotifier.withError(
        Exception('Server error: 500'),
      );
      final reportsNotifier = _TestRecentReportsNotifier.withError(
        Exception('Server error: 500'),
      );

      await tester.pumpWidget(buildTestWidget(
        statsNotifier: statsNotifier,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget,
          reason: 'Retry button should be displayed on error');
    });

    testWidgets('Tapping Retry attempts fresh load', (tester) async {
      // Step 6-7: Tap 'Retry' and verify fresh attempt to load data
      final statsNotifier = _TestDashboardStatsNotifier.withError(
        Exception('Server error: 500'),
      );
      final reportsNotifier = _TestRecentReportsNotifier.withError(
        Exception('Server error: 500'),
      );

      await tester.pumpWidget(buildTestWidget(
        statsNotifier: statsNotifier,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Verify retry button exists
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      // Prepare success data for retry
      statsNotifier.setSuccessOnRetry(const DashboardStats(
        reportsThisWeek: 12,
        pendingUploads: 3,
        totalProjects: 8,
        recentActivity: 24,
      ));

      // Tap retry
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Verify refresh was called
      expect(statsNotifier.refreshCalled, isTrue,
          reason: 'Retry should trigger refresh');
    });

    testWidgets('After successful retry, data is displayed', (tester) async {
      final statsNotifier = _TestDashboardStatsNotifier.withError(
        Exception('Server error: 500'),
      );
      final reportsNotifier = _TestRecentReportsNotifier.withError(
        Exception('Server error: 500'),
      );

      await tester.pumpWidget(buildTestWidget(
        statsNotifier: statsNotifier,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Prepare success data for retry
      statsNotifier.setSuccessOnRetry(const DashboardStats(
        reportsThisWeek: 12,
        pendingUploads: 3,
        totalProjects: 8,
        recentActivity: 24,
      ));
      reportsNotifier.setSuccessOnRetry([
        RecentReport(
          id: '1',
          title: 'Fresh Report',
          projectName: 'Fresh Project',
          date: DateTime(2026, 1, 30),
          status: ReportStatus.complete,
        ),
      ]);

      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify fresh data is displayed
      expect(find.text('12'), findsOneWidget,
          reason: 'Fresh data should be displayed after retry');
      expect(find.text('Fresh Report'), findsOneWidget,
          reason: 'Fresh reports should be displayed after retry');
    });

    testWidgets('Error state shows error icon', (tester) async {
      final statsNotifier = _TestDashboardStatsNotifier.withError(
        Exception('Server error: 500'),
      );
      final reportsNotifier = _TestRecentReportsNotifier.withError(
        Exception('Server error: 500'),
      );

      await tester.pumpWidget(buildTestWidget(
        statsNotifier: statsNotifier,
        reportsNotifier: reportsNotifier,
      ));
      await tester.pumpAndSettle();

      // Verify error icon is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget,
          reason: 'Error icon should be displayed');
    });
  });
}

/// Test notifier that can simulate errors and cache scenarios.
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  _TestDashboardStatsNotifier() : _shouldError = false;

  _TestDashboardStatsNotifier.withError(this._error) : _shouldError = true;

  _TestDashboardStatsNotifier.withErrorAndCache({
    required Exception error,
    required DashboardStats cachedStats,
  })  : _error = error,
        _shouldError = true,
        _cachedStats = cachedStats,
        _hasCachedData = true;

  bool _shouldError;
  Exception? _error;
  DashboardStats? _cachedStats;
  bool _hasCachedData = false;
  DashboardStats? _successStats;
  bool refreshCalled = false;

  void setSuccessOnRetry(DashboardStats stats) {
    _successStats = stats;
  }

  @override
  Future<DashboardStats> build() async {
    if (_shouldError && !_hasCachedData) {
      throw _error!;
    }
    if (_hasCachedData) {
      return _cachedStats!;
    }
    return const DashboardStats(
      reportsThisWeek: 12,
      pendingUploads: 3,
      totalProjects: 8,
      recentActivity: 24,
    );
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
    if (_successStats != null) {
      _shouldError = false;
      state = AsyncData(_successStats!);
    } else {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => build());
    }
  }
}

/// Test notifier for recent reports that can simulate errors.
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  _TestRecentReportsNotifier() : _shouldError = false;

  _TestRecentReportsNotifier.withError(this._error) : _shouldError = true;

  _TestRecentReportsNotifier.withErrorAndCache({
    required Exception error,
    required List<RecentReport> cachedReports,
  })  : _error = error,
        _shouldError = true,
        _cachedReports = cachedReports,
        _hasCachedData = true;

  bool _shouldError;
  Exception? _error;
  List<RecentReport>? _cachedReports;
  bool _hasCachedData = false;
  List<RecentReport>? _successReports;
  bool refreshCalled = false;

  void setSuccessOnRetry(List<RecentReport> reports) {
    _successReports = reports;
  }

  @override
  Future<List<RecentReport>> build() async {
    if (_shouldError && !_hasCachedData) {
      throw _error!;
    }
    if (_hasCachedData) {
      return _cachedReports!;
    }
    return [];
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
    if (_successReports != null) {
      _shouldError = false;
      state = AsyncData(_successReports!);
    } else {
      state = const AsyncLoading();
      state = await AsyncValue.guard(() => build());
    }
  }
}

/// Test notifier for pending uploads.
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  @override
  Future<List<PendingUpload>> build() async {
    return [];
  }
}
