import 'package:flutter/foundation.dart';

/// Dashboard statistics model.
@immutable
class DashboardStats {
  const DashboardStats({
    required this.reportsThisWeek,
    required this.pendingUploads,
    required this.totalProjects,
    required this.recentActivity,
  });

  /// Number of reports created this week.
  final int reportsThisWeek;

  /// Number of entries pending upload.
  final int pendingUploads;

  /// Total number of projects.
  final int totalProjects;

  /// Number of recent activity items.
  final int recentActivity;

  /// Creates a copy with updated values.
  DashboardStats copyWith({
    int? reportsThisWeek,
    int? pendingUploads,
    int? totalProjects,
    int? recentActivity,
  }) {
    return DashboardStats(
      reportsThisWeek: reportsThisWeek ?? this.reportsThisWeek,
      pendingUploads: pendingUploads ?? this.pendingUploads,
      totalProjects: totalProjects ?? this.totalProjects,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStats &&
          runtimeType == other.runtimeType &&
          reportsThisWeek == other.reportsThisWeek &&
          pendingUploads == other.pendingUploads &&
          totalProjects == other.totalProjects &&
          recentActivity == other.recentActivity;

  @override
  int get hashCode =>
      reportsThisWeek.hashCode ^
      pendingUploads.hashCode ^
      totalProjects.hashCode ^
      recentActivity.hashCode;
}
