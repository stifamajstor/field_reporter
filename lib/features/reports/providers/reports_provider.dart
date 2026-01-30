import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/report.dart';

part 'reports_provider.g.dart';

/// Provider for fetching all reports across all projects.
@riverpod
class AllReportsNotifier extends _$AllReportsNotifier {
  @override
  Future<List<Report>> build() async {
    // Simulate loading reports from local database/API
    await Future.delayed(const Duration(milliseconds: 100));

    // Return sample reports sorted by most recent first
    final reports = [
      Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Site Inspection Report',
        status: ReportStatus.complete,
        entryCount: 5,
        createdAt: DateTime(2026, 1, 30, 14, 30),
        updatedAt: DateTime(2026, 1, 30, 15, 45),
      ),
      Report(
        id: 'report-2',
        projectId: 'proj-2',
        title: 'Progress Update',
        status: ReportStatus.draft,
        entryCount: 3,
        createdAt: DateTime(2026, 1, 29, 10, 0),
        updatedAt: DateTime(2026, 1, 29, 12, 30),
      ),
      Report(
        id: 'report-3',
        projectId: 'proj-1',
        title: 'Final Assessment',
        status: ReportStatus.processing,
        entryCount: 8,
        createdAt: DateTime(2026, 1, 28, 9, 15),
      ),
    ];

    // Sort by most recent first (using updatedAt if available, otherwise createdAt)
    reports.sort((a, b) {
      final aTime = a.updatedAt ?? a.createdAt;
      final bTime = b.updatedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return reports;
  }

  /// Creates a new report.
  Future<Report> createReport(Report report) async {
    final currentReports = state.valueOrNull ?? [];
    state = AsyncData([report, ...currentReports]);
    return report;
  }

  /// Updates an existing report.
  Future<Report> updateReport(Report report) async {
    final currentReports = state.valueOrNull ?? [];
    final updatedReports = currentReports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
  }

  /// Deletes a report by ID.
  Future<void> deleteReport(String reportId) async {
    final currentReports = state.valueOrNull ?? [];
    final updatedReports =
        currentReports.where((r) => r.id != reportId).toList();
    state = AsyncData(updatedReports);
  }
}

/// Provider for fetching reports by project ID.
@riverpod
class ProjectReportsNotifier extends _$ProjectReportsNotifier {
  @override
  Future<List<Report>> build(String projectId) async {
    // TODO: Fetch from repository
    return [];
  }
}
