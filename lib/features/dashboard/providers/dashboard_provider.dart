import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/dashboard_stats.dart';

part 'dashboard_provider.g.dart';

/// Provider for dashboard statistics.
@riverpod
class DashboardStatsNotifier extends _$DashboardStatsNotifier {
  @override
  Future<DashboardStats> build() async {
    // Simulate loading stats from local database/API
    await Future.delayed(const Duration(milliseconds: 100));

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
