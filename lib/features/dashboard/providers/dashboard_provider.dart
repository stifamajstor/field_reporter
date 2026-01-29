import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/dashboard_stats.dart';
import '../domain/recent_report.dart';

part 'dashboard_provider.g.dart';

/// Provider for dashboard statistics.
@riverpod
class DashboardStatsNotifier extends _$DashboardStatsNotifier {
  DateTime? _lastUpdated;

  /// The timestamp when the data was last successfully fetched.
  DateTime? get lastUpdated => _lastUpdated;

  @override
  Future<DashboardStats> build() async {
    // Simulate loading stats from local database/API
    await Future.delayed(const Duration(milliseconds: 100));

    // Update the last updated timestamp
    _lastUpdated = DateTime.now();

    // Return mock data for now - will be replaced with actual repository calls
    return const DashboardStats(
      reportsThisWeek: 12,
      pendingUploads: 3,
      totalProjects: 8,
      recentActivity: 24,
    );
  }

  /// Refreshes the dashboard statistics.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Provider for recent reports displayed on the dashboard.
@riverpod
class RecentReportsNotifier extends _$RecentReportsNotifier {
  @override
  Future<List<RecentReport>> build() async {
    // Simulate loading reports from local database/API
    await Future.delayed(const Duration(milliseconds: 100));

    // Return mock data for now - will be replaced with actual repository calls
    return [
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
      RecentReport(
        id: '4',
        title: 'Final Assessment',
        projectName: 'Office D',
        date: DateTime(2026, 1, 26),
        status: ReportStatus.complete,
      ),
      RecentReport(
        id: '5',
        title: 'Weekly Summary',
        projectName: 'Site E',
        date: DateTime(2026, 1, 25),
        status: ReportStatus.draft,
      ),
    ];
  }

  /// Refreshes the recent reports list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
