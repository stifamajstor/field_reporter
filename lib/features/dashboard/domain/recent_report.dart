import 'package:flutter/foundation.dart';

/// Status of a report.
enum ReportStatus {
  /// Report is in draft state, still being edited.
  draft,

  /// Report is being processed by AI.
  processing,

  /// Report is complete and ready for viewing/export.
  complete,
}

/// A recent report displayed on the dashboard.
@immutable
class RecentReport {
  const RecentReport({
    required this.id,
    required this.title,
    required this.projectName,
    required this.date,
    required this.status,
  });

  /// Unique identifier of the report.
  final String id;

  /// Title of the report.
  final String title;

  /// Name of the project this report belongs to.
  final String projectName;

  /// Date the report was created or last modified.
  final DateTime date;

  /// Current status of the report.
  final ReportStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentReport &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          projectName == other.projectName &&
          date == other.date &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      projectName.hashCode ^
      date.hashCode ^
      status.hashCode;
}
