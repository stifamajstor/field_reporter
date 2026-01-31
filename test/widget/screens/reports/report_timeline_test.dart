import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/services/connectivity_service.dart';

void main() {
  group('Report timeline shows chronological entry flow', () {
    late Report report;
    late List<Entry> entriesOverTime;
    late Project project;

    setUp(() {
      project = const Project(
        id: 'proj-1',
        name: 'Test Project',
        description: 'A test project',
        status: ProjectStatus.active,
      );

      report = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Timeline Test Report',
        status: ReportStatus.draft,
        entryCount: 4,
        createdAt: DateTime(2026, 1, 31, 9, 0),
      );

      // Create entries with different timestamps over time
      entriesOverTime = [
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          mediaPath: '/test/photo1.jpg',
          sortOrder: 0,
          capturedAt: DateTime(2026, 1, 31, 9, 0),
          createdAt: DateTime(2026, 1, 31, 9, 0),
        ),
        Entry(
          id: 'entry-2',
          reportId: 'report-1',
          type: EntryType.note,
          content: 'Site inspection started.',
          sortOrder: 1,
          capturedAt: DateTime(2026, 1, 31, 9, 30),
          createdAt: DateTime(2026, 1, 31, 9, 30),
        ),
        Entry(
          id: 'entry-3',
          reportId: 'report-1',
          type: EntryType.audio,
          mediaPath: '/test/audio.m4a',
          durationSeconds: 120,
          sortOrder: 2,
          capturedAt: DateTime(2026, 1, 31, 10, 15),
          createdAt: DateTime(2026, 1, 31, 10, 15),
        ),
        Entry(
          id: 'entry-4',
          reportId: 'report-1',
          type: EntryType.video,
          mediaPath: '/test/video.mp4',
          durationSeconds: 45,
          sortOrder: 3,
          capturedAt: DateTime(2026, 1, 31, 11, 0),
          createdAt: DateTime(2026, 1, 31, 11, 0),
        ),
      ];
    });

    Widget createTestWidget({
      required Report report,
      required List<Entry> entries,
    }) {
      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: [report]);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier(entries: entries);
          }),
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: [project]);
          }),
          connectivityServiceProvider
              .overrideWithValue(ConnectivityService()..setOnline(true)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(report: report),
        ),
      );
    }

    testWidgets('Open Report with multiple entries over time', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entriesOverTime,
        ),
      );
      await tester.pumpAndSettle();

      // Verify report editor screen is displayed
      expect(find.text('Report Editor'), findsOneWidget);
      expect(find.text('Timeline Test Report'), findsOneWidget);
    });

    testWidgets('Entries displayed in timeline format', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entriesOverTime,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to entries section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Verify timeline format is used (timeline container exists)
      expect(find.byKey(const Key('entries_timeline')), findsOneWidget);
    });

    testWidgets('Timestamps visible on timeline', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entriesOverTime,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to entries section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Verify timestamps are visible for entries
      // Timestamps in format like "9:00 AM", "9:30 AM", etc.
      expect(
          find.byKey(const Key('timeline_timestamp_entry-1')), findsOneWidget);
      expect(
          find.byKey(const Key('timeline_timestamp_entry-2')), findsOneWidget);
    });

    testWidgets('Visual connection between entries', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entriesOverTime,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to entries section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Verify visual timeline connector exists (vertical line)
      expect(find.byKey(const Key('timeline_connector')), findsWidgets);
    });

    testWidgets('Different entry types have distinct icons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entriesOverTime,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to entries section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Verify distinct icons for different entry types
      expect(find.byKey(const Key('timeline_icon_photo')), findsOneWidget);
      expect(find.byKey(const Key('timeline_icon_note')), findsOneWidget);
      expect(find.byKey(const Key('timeline_icon_audio')), findsOneWidget);
      expect(find.byKey(const Key('timeline_icon_video')), findsOneWidget);
    });
  });
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;

  _MockReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build() async {
    return reports;
  }

  @override
  Future<Report> updateReport(Report report) async {
    final currentReports = state.valueOrNull ?? [];
    final updatedReports = currentReports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
  }
}

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  final List<Entry> entries;

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async {
    return projects;
  }
}
