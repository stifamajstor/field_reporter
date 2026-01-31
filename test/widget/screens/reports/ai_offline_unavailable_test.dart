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
  group('AI features show unavailable state when offline', () {
    late Report report;
    late List<Entry> entries;
    late Project project;
    late ConnectivityService offlineConnectivityService;

    setUp(() {
      final now = DateTime(2026, 1, 31, 14, 30);

      project = const Project(
        id: 'proj-1',
        name: 'Test Project',
        description: 'A test project',
        status: ProjectStatus.active,
      );

      report = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 2,
        createdAt: now,
      );

      entries = [
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          mediaPath: '/test/photo1.jpg',
          sortOrder: 0,
          capturedAt: now,
          createdAt: now,
        ),
        Entry(
          id: 'entry-2',
          reportId: 'report-1',
          type: EntryType.note,
          content: 'Test note content.',
          sortOrder: 1,
          capturedAt: now,
          createdAt: now,
        ),
      ];

      // Create offline connectivity service
      offlineConnectivityService = ConnectivityService()..setOnline(false);
    });

    Widget createTestWidget({
      required Report report,
      required List<Entry> entries,
      required ConnectivityService connectivityService,
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
          connectivityServiceProvider.overrideWithValue(connectivityService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(report: report),
        ),
      );
    }

    testWidgets('Enable airplane mode - shows offline indicator',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entries,
          connectivityService: offlineConnectivityService,
        ),
      );
      await tester.pumpAndSettle();

      // Verify offline indicator is shown
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      expect(find.text('Offline mode'), findsOneWidget);
    });

    testWidgets('Open a report while offline', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entries,
          connectivityService: offlineConnectivityService,
        ),
      );
      await tester.pumpAndSettle();

      // Verify report editor screen is displayed
      expect(find.text('Report Editor'), findsOneWidget);
      expect(find.text('Test Report'), findsOneWidget);
    });

    testWidgets(
        'Attempt to generate AI summary while offline shows unavailable message',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entries,
          connectivityService: offlineConnectivityService,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find the AI Summary section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Verify message that AI features require connection
      expect(
        find.byKey(const Key('ai_offline_message')),
        findsOneWidget,
      );
      expect(
        find.text('AI features require an internet connection'),
        findsOneWidget,
      );
    });

    testWidgets('Option to queue for later processing is shown when offline',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entries,
          connectivityService: offlineConnectivityService,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find the AI Summary section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Verify option to queue for later processing
      expect(
        find.byKey(const Key('queue_for_later_button')),
        findsOneWidget,
      );
      expect(find.text('Queue for Later'), findsOneWidget);
    });

    testWidgets('Tapping queue for later shows confirmation', (tester) async {
      final mockReportsNotifier = _MockReportsNotifierWithQueue(
        reports: [report],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allReportsNotifierProvider.overrideWith(() => mockReportsNotifier),
            entriesNotifierProvider.overrideWith(() {
              return _MockEntriesNotifier(entries: entries);
            }),
            projectsNotifierProvider.overrideWith(() {
              return _MockProjectsNotifier(projects: [project]);
            }),
            connectivityServiceProvider
                .overrideWithValue(offlineConnectivityService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ReportEditorScreen(report: report),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find the AI Summary section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Tap queue for later button
      await tester.tap(find.byKey(const Key('queue_for_later_button')));
      await tester.pumpAndSettle();

      // Verify queued confirmation
      expect(
        find.byKey(const Key('ai_queued_message')),
        findsOneWidget,
      );
      expect(
        find.text('AI summary will be generated when online'),
        findsOneWidget,
      );
    });

    testWidgets('Generate Summary button is not shown when offline',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entries,
          connectivityService: offlineConnectivityService,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find the AI Summary section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Verify Generate Summary button is NOT shown when offline
      expect(find.byKey(const Key('generate_summary_button')), findsNothing);
    });

    testWidgets('When online, Generate Summary button is shown',
        (tester) async {
      final onlineConnectivityService = ConnectivityService()..setOnline(true);

      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: entries,
          connectivityService: onlineConnectivityService,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find the AI Summary section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Verify Generate Summary button IS shown when online
      expect(find.byKey(const Key('generate_summary_button')), findsOneWidget);
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

/// Mock ReportsNotifier with queue support for testing
class _MockReportsNotifierWithQueue extends AllReportsNotifier {
  final List<Report> _initialReports;
  bool _isQueued = false;

  _MockReportsNotifierWithQueue({required List<Report> reports})
      : _initialReports = reports;

  @override
  Future<List<Report>> build() async {
    return _initialReports;
  }

  @override
  Future<Report> updateReport(Report report) async {
    final currentReports = state.valueOrNull ?? _initialReports;
    final updatedReports = currentReports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
  }

  @override
  Future<void> queueSummaryForLater(String reportId) async {
    _isQueued = true;
    final currentReports = state.valueOrNull ?? _initialReports;
    final report = currentReports.firstWhere((r) => r.id == reportId);
    final updatedReport = report.copyWith(
      aiSummaryQueued: true,
      updatedAt: DateTime.now(),
    );
    await updateReport(updatedReport);
  }

  bool get isQueued => _isQueued;
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
