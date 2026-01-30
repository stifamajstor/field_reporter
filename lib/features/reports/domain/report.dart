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

/// A report in the Field Reporter app.
@immutable
class Report {
  const Report({
    required this.id,
    required this.projectId,
    required this.title,
    this.notes,
    this.aiSummary,
    this.status = ReportStatus.draft,
    this.entryCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier of the report.
  final String id;

  /// ID of the project this report belongs to.
  final String projectId;

  /// Title of the report.
  final String title;

  /// User notes on the report.
  final String? notes;

  /// AI-generated summary of the report.
  final String? aiSummary;

  /// Current status of the report.
  final ReportStatus status;

  /// Number of entries in this report.
  final int entryCount;

  /// Timestamp when the report was created.
  final DateTime createdAt;

  /// Timestamp when the report was last updated.
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Report &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          projectId == other.projectId &&
          title == other.title &&
          notes == other.notes &&
          aiSummary == other.aiSummary &&
          status == other.status &&
          entryCount == other.entryCount &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      projectId.hashCode ^
      title.hashCode ^
      notes.hashCode ^
      aiSummary.hashCode ^
      status.hashCode ^
      entryCount.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  Report copyWith({
    String? id,
    String? projectId,
    String? title,
    String? notes,
    String? aiSummary,
    ReportStatus? status,
    int? entryCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      aiSummary: aiSummary ?? this.aiSummary,
      status: status ?? this.status,
      entryCount: entryCount ?? this.entryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
