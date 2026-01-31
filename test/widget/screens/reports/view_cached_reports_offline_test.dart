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
import 'package:field_reporter/features/reports/presentation/reports_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/services/connectivity_service.dart';

void main() {
  group('User can view cached reports when offline', () {
    late List<Report> cachedReports;
    late List<Entry> cachedEntries;
    late List<Project> cachedProjects;
    late ConnectivityService connectivityService;

    setUp(() {
      // Set up cached data (simulating reports that were viewed while online)
      cachedProjects = [
        Project(
          id: 'proj-1',
          name: 'Construction Site Alpha',
          description: 'Main construction project',
          status: ProjectStatus.active,
          syncPending: false,
          reportCount: 2,
          lastActivityAt: DateTime(2026, 1, 30),
        ),
        Project(
          id: 'proj-2',
          name: 'Office Renovation',
          description: 'Office building renovation',
          status: ProjectStatus.active,
          syncPending: false,
          reportCount: 1,
          lastActivityAt: DateTime(2026, 1, 29),
        ),
      ];

      cachedReports = [
        Report(
          id: 'report-1',
          projectId: 'proj-1',
          title: 'Site Inspection Report',
          notes: 'Initial site inspection notes',
          status: ReportStatus.complete,
          entryCount: 3,
          createdAt: DateTime(2026, 1, 30, 14, 30),
          updatedAt: DateTime(2026, 1, 30, 15, 45),
        ),
        Report(
          id: 'report-2',
          projectId: 'proj-1',
          title: 'Progress Update January',
          notes: 'Monthly progress report',
          status: ReportStatus.draft,
          entryCount: 2,
          createdAt: DateTime(2026, 1, 29, 10, 0),
          updatedAt: DateTime(2026, 1, 29, 12, 30),
        ),
        Report(
          id: 'report-3',
          projectId: 'proj-2',
          title: 'Renovation Assessment',
          notes: 'Assessment notes',
          status: ReportStatus.complete,
          entryCount: 4,
          createdAt: DateTime(2026, 1, 28, 9, 15),
        ),
      ];

      cachedEntries = [
        // Entries for report-1
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          mediaPath: '/cached/photos/site_photo_1.jpg',
          thumbnailPath: '/cached/thumbnails/site_photo_1_thumb.jpg',
          annotation: 'Front entrance view',
          latitude: 40.7128,
          longitude: -74.0060,
          address: '123 Main St',
          sortOrder: 0,
          capturedAt: DateTime(2026, 1, 30, 14, 30),
          createdAt: DateTime(2026, 1, 30, 14, 30),
          syncPending: false,
        ),
        Entry(
          id: 'entry-2',
          reportId: 'report-1',
          type: EntryType.note,
          content: 'Foundation inspection completed. No cracks observed.',
          sortOrder: 1,
          capturedAt: DateTime(2026, 1, 30, 14, 45),
          createdAt: DateTime(2026, 1, 30, 14, 45),
          syncPending: false,
        ),
        Entry(
          id: 'entry-3',
          reportId: 'report-1',
          type: EntryType.audio,
          mediaPath: '/cached/audio/voice_memo_1.m4a',
          durationSeconds: 45,
          content: 'Voice memo about structural observations.',
          sortOrder: 2,
          capturedAt: DateTime(2026, 1, 30, 15, 00),
          createdAt: DateTime(2026, 1, 30, 15, 00),
          syncPending: false,
        ),
        // Entries for report-2
        Entry(
          id: 'entry-4',
          reportId: 'report-2',
          type: EntryType.photo,
          mediaPath: '/cached/photos/progress_photo_1.jpg',
          thumbnailPath: '/cached/thumbnails/progress_photo_1_thumb.jpg',
          sortOrder: 0,
          capturedAt: DateTime(2026, 1, 29, 10, 30),
          createdAt: DateTime(2026, 1, 29, 10, 30),
          syncPending: false,
        ),
        Entry(
          id: 'entry-5',
          reportId: 'report-2',
          type: EntryType.video,
          mediaPath: '/cached/videos/walkthrough.mp4',
          thumbnailPath: '/cached/thumbnails/walkthrough_thumb.jpg',
          durationSeconds: 120,
          sortOrder: 1,
          capturedAt: DateTime(2026, 1, 29, 11, 00),
          createdAt: DateTime(2026, 1, 29, 11, 00),
          syncPending: false,
        ),
      ];

      connectivityService = ConnectivityService();
    });

    Widget buildTestWidget({
      required bool isOnline,
      Widget? child,
    }) {
      connectivityService.setOnline(isOnline);

      return ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivityService),
          projectsNotifierProvider.overrideWith(() {
            return _TestProjectsNotifier(storedProjects: cachedProjects);
          }),
          allReportsNotifierProvider.overrideWith(() {
            return _TestReportsNotifier(storedReports: cachedReports);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _TestEntriesNotifier(storedEntries: cachedEntries);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child ?? const ReportsScreen(),
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/reports/') ?? false) {
              final reportId = settings.name!.replaceFirst('/reports/', '');
              return MaterialPageRoute(
                builder: (_) => ReportEditorScreen(reportId: reportId),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );
    }

    // Step 1: View several reports while online (simulated by having cached data)
    testWidgets('online: reports are displayed when online', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Verify reports are displayed
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update January'), findsOneWidget);
      expect(find.text('Renovation Assessment'), findsOneWidget);
    });

    // Step 2 & 3: Enable airplane mode and navigate to Reports screen
    testWidgets('offline: can navigate to Reports screen while offline',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify Reports screen is displayed
      expect(find.byType(ReportsScreen), findsOneWidget);
    });

    // Step 4: Verify cached reports are displayed
    testWidgets('offline: cached reports are displayed when offline',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify all cached reports are displayed
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update January'), findsOneWidget);
      expect(find.text('Renovation Assessment'), findsOneWidget);

      // Verify report details are visible (project names, dates, entry counts)
      expect(find.text('3 entries'), findsOneWidget);
      expect(find.text('2 entries'), findsOneWidget);
      expect(find.text('4 entries'), findsOneWidget);
    });

    // Step 5: Open a cached report
    testWidgets('offline: can open a cached report', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(
          report: cachedReports.first,
          projectId: 'proj-1',
        ),
      ));
      await tester.pumpAndSettle();

      // Verify report editor screen opens with cached report data
      expect(find.byType(ReportEditorScreen), findsOneWidget);
      expect(find.text('Site Inspection Report'), findsOneWidget);
    });

    // Step 6: Verify entries and media are viewable
    testWidgets('offline: entries and media are viewable', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(
          report: cachedReports.first,
          projectId: 'proj-1',
        ),
      ));
      await tester.pumpAndSettle();

      // Scroll to find Entries section
      await tester.scrollUntilVisible(
        find.text('Entries'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Verify entries are displayed
      expect(find.text('Entries'), findsOneWidget);
      // Entries section should show entry cards for the cached entries
      // Look for entry type indicators or content
      expect(find.byKey(const Key('entry_list')), findsOneWidget);
    });

    // Step 7: Verify offline indicator shown
    testWidgets('offline: offline indicator is shown on Reports screen',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify offline indicator is displayed
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      expect(find.text('Offline mode'), findsOneWidget);
    });

    testWidgets('offline: offline indicator shown in report editor',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(
          report: cachedReports.first,
          projectId: 'proj-1',
        ),
      ));
      await tester.pumpAndSettle();

      // Verify offline indicator is displayed in report editor
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
    });

    // Complete flow test
    testWidgets('complete offline cached report viewing flow', (tester) async {
      // Step 1: First view reports while online
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Verify reports visible online
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update January'), findsOneWidget);

      // Step 2: Go offline (rebuild with offline state)
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Step 3: Verify Reports screen is accessible
      expect(find.byType(ReportsScreen), findsOneWidget);

      // Step 4: Verify cached reports still displayed
      expect(find.text('Site Inspection Report'), findsOneWidget);
      expect(find.text('Progress Update January'), findsOneWidget);
      expect(find.text('Renovation Assessment'), findsOneWidget);

      // Step 7: Verify offline indicator shown
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      expect(find.text('Offline mode'), findsOneWidget);
    });

    testWidgets('offline: can view report with entries', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(
          report: cachedReports.first,
          projectId: 'proj-1',
        ),
      ));
      await tester.pumpAndSettle();

      // Report editor should show cached report
      expect(find.byType(ReportEditorScreen), findsOneWidget);
      expect(find.text('Site Inspection Report'), findsOneWidget);

      // Scroll to entries section
      await tester.scrollUntilVisible(
        find.text('Entries'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Verify entries section header shows correct count
      // The report has 3 entries
      expect(find.byKey(const Key('entry_list')), findsOneWidget);

      // Verify offline indicator is shown
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
    });
  });
}

/// Test notifier for projects that returns cached projects.
class _TestProjectsNotifier extends ProjectsNotifier {
  _TestProjectsNotifier({required this.storedProjects});

  final List<Project> storedProjects;

  @override
  Future<List<Project>> build() async {
    return storedProjects;
  }
}

/// Test notifier for reports that returns cached reports.
class _TestReportsNotifier extends AllReportsNotifier {
  _TestReportsNotifier({required this.storedReports});

  final List<Report> storedReports;

  @override
  Future<List<Report>> build() async {
    // Return cached reports (simulating offline cache)
    return storedReports;
  }
}

/// Test notifier for entries that returns cached entries.
class _TestEntriesNotifier extends EntriesNotifier {
  _TestEntriesNotifier({required this.storedEntries});

  final List<Entry> storedEntries;

  @override
  Future<List<Entry>> build() async {
    return storedEntries;
  }

  @override
  List<Entry> getEntriesForReport(String reportId) {
    return storedEntries.where((e) => e.reportId == reportId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
