import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/services/connectivity_service.dart';

void main() {
  group('User can delete an entry from report', () {
    late Report testReport;
    late Project testProject;
    late List<Entry> testEntries;

    setUp(() {
      final now = DateTime(2026, 1, 30, 14, 30);

      testProject = const Project(
        id: 'proj-1',
        name: 'Test Project',
      );

      testReport = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 3,
        createdAt: now,
      );

      testEntries = [
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
          content: 'Test note content',
          sortOrder: 1,
          capturedAt: now,
          createdAt: now,
        ),
        Entry(
          id: 'entry-3',
          reportId: 'report-1',
          type: EntryType.audio,
          mediaPath: '/test/audio.mp3',
          durationSeconds: 30,
          sortOrder: 2,
          capturedAt: now,
          createdAt: now,
        ),
      ];
    });

    Widget createTestWidget({
      required _MockEntriesNotifier mockEntriesNotifier,
      required _MockReportsNotifier mockReportsNotifier,
      required _MockProjectsNotifier mockProjectsNotifier,
    }) {
      final connectivityService = ConnectivityService()..setOnline(true);
      return ProviderScope(
        overrides: [
          entriesNotifierProvider.overrideWith(() => mockEntriesNotifier),
          allReportsNotifierProvider.overrideWith(() => mockReportsNotifier),
          projectsNotifierProvider.overrideWith(() => mockProjectsNotifier),
          connectivityServiceProvider.overrideWithValue(connectivityService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(report: testReport),
        ),
      );
    }

    testWidgets('Open Report with entries - entries are displayed',
        (tester) async {
      final mockEntriesNotifier = _MockEntriesNotifier(entries: testEntries);
      final mockReportsNotifier = _MockReportsNotifier(reports: [testReport]);
      final mockProjectsNotifier =
          _MockProjectsNotifier(projects: [testProject]);

      await tester.pumpWidget(createTestWidget(
        mockEntriesNotifier: mockEntriesNotifier,
        mockReportsNotifier: mockReportsNotifier,
        mockProjectsNotifier: mockProjectsNotifier,
      ));
      await tester.pumpAndSettle();

      // Verify report editor is displayed
      expect(find.byType(ReportEditorScreen), findsOneWidget);

      // Verify entries section shows all entries
      expect(find.text('Entries'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Voice Memo'), findsOneWidget);
    });

    testWidgets('Swipe left on entry reveals delete button', (tester) async {
      final mockEntriesNotifier = _MockEntriesNotifier(entries: testEntries);
      final mockReportsNotifier = _MockReportsNotifier(reports: [testReport]);
      final mockProjectsNotifier =
          _MockProjectsNotifier(projects: [testProject]);

      await tester.pumpWidget(createTestWidget(
        mockEntriesNotifier: mockEntriesNotifier,
        mockReportsNotifier: mockReportsNotifier,
        mockProjectsNotifier: mockProjectsNotifier,
      ));
      await tester.pumpAndSettle();

      // Find the first entry card (Photo)
      final entryCard = find.byKey(const Key('entry_card_entry-1'));
      expect(entryCard, findsOneWidget);

      // Swipe left to reveal delete action
      await tester.drag(entryCard, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Verify delete button is revealed
      expect(find.byKey(const Key('delete_button_entry-1')), findsOneWidget);
    });

    testWidgets('Tap delete button shows confirmation dialog', (tester) async {
      final mockEntriesNotifier = _MockEntriesNotifier(entries: testEntries);
      final mockReportsNotifier = _MockReportsNotifier(reports: [testReport]);
      final mockProjectsNotifier =
          _MockProjectsNotifier(projects: [testProject]);

      await tester.pumpWidget(createTestWidget(
        mockEntriesNotifier: mockEntriesNotifier,
        mockReportsNotifier: mockReportsNotifier,
        mockProjectsNotifier: mockProjectsNotifier,
      ));
      await tester.pumpAndSettle();

      // Swipe left on entry to reveal delete
      final entryCard = find.byKey(const Key('entry_card_entry-1'));
      await tester.drag(entryCard, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Tap delete button
      final deleteButton = find.byKey(const Key('delete_button_entry-1'));
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify delete confirmation dialog appears
      expect(
          find.byKey(const Key('delete_confirmation_dialog')), findsOneWidget);
      expect(find.text('Delete Entry'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this entry?'),
          findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Confirm deletion removes entry from list', (tester) async {
      final mockEntriesNotifier = _MockEntriesNotifier(entries: testEntries);
      final mockReportsNotifier = _MockReportsNotifier(reports: [testReport]);
      final mockProjectsNotifier =
          _MockProjectsNotifier(projects: [testProject]);

      await tester.pumpWidget(createTestWidget(
        mockEntriesNotifier: mockEntriesNotifier,
        mockReportsNotifier: mockReportsNotifier,
        mockProjectsNotifier: mockProjectsNotifier,
      ));
      await tester.pumpAndSettle();

      // Verify 3 entries initially
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Voice Memo'), findsOneWidget);

      // Find and scroll to the note entry
      final entryCard = find.byKey(const Key('entry_card_entry-2'));
      await tester.ensureVisible(entryCard);
      await tester.pumpAndSettle();

      // Swipe left on note entry
      await tester.drag(entryCard, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Find and tap delete button
      final deleteButton = find.byKey(const Key('delete_button_entry-2'));
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Confirm deletion
      final confirmButton = find.byKey(const Key('confirm_delete_button'));
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify deleteEntry was called
      expect(mockEntriesNotifier.deleteEntryCalled, isTrue);
      expect(mockEntriesNotifier.lastDeletedEntryId, 'entry-2');

      // Verify Note entry is removed from list (only Photo and Voice Memo remain)
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Note'), findsNothing);
      expect(find.text('Voice Memo'), findsOneWidget);
    });

    testWidgets('Cancel deletion keeps entry in list', (tester) async {
      final mockEntriesNotifier = _MockEntriesNotifier(entries: testEntries);
      final mockReportsNotifier = _MockReportsNotifier(reports: [testReport]);
      final mockProjectsNotifier =
          _MockProjectsNotifier(projects: [testProject]);

      await tester.pumpWidget(createTestWidget(
        mockEntriesNotifier: mockEntriesNotifier,
        mockReportsNotifier: mockReportsNotifier,
        mockProjectsNotifier: mockProjectsNotifier,
      ));
      await tester.pumpAndSettle();

      // Swipe left on entry
      final entryCard = find.byKey(const Key('entry_card_entry-1'));
      await tester.drag(entryCard, const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Tap delete button
      final deleteButton = find.byKey(const Key('delete_button_entry-1'));
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Cancel deletion
      final cancelButton = find.byKey(const Key('cancel_delete_button'));
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify deleteEntry was NOT called
      expect(mockEntriesNotifier.deleteEntryCalled, isFalse);

      // Verify all entries still present
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Voice Memo'), findsOneWidget);
    });

    testWidgets('Entry count updates after deletion', (tester) async {
      final mockEntriesNotifier = _MockEntriesNotifier(entries: testEntries);
      final mockReportsNotifier = _MockReportsNotifier(reports: [testReport]);
      final mockProjectsNotifier =
          _MockProjectsNotifier(projects: [testProject]);

      await tester.pumpWidget(createTestWidget(
        mockEntriesNotifier: mockEntriesNotifier,
        mockReportsNotifier: mockReportsNotifier,
        mockProjectsNotifier: mockProjectsNotifier,
      ));
      await tester.pumpAndSettle();

      // Swipe and delete an entry
      final entryCard = find.byKey(const Key('entry_card_entry-1'));
      await tester.drag(entryCard, const Offset(-200, 0));
      await tester.pumpAndSettle();

      final deleteButton = find.byKey(const Key('delete_button_entry-1'));
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      final confirmButton = find.byKey(const Key('confirm_delete_button'));
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify report's entry count was updated
      expect(mockReportsNotifier.updateReportCalled, isTrue);
      expect(mockReportsNotifier.lastUpdatedReport?.entryCount, 2);
    });
  });
}

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  final List<Entry> entries;
  bool deleteEntryCalled = false;
  String? lastDeletedEntryId;

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    deleteEntryCalled = true;
    lastDeletedEntryId = entryId;
    final updatedEntries = entries.where((e) => e.id != entryId).toList();
    state = AsyncData(updatedEntries);
  }
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;
  bool updateReportCalled = false;
  Report? lastUpdatedReport;

  _MockReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build() async {
    return reports;
  }

  @override
  Future<Report> updateReport(Report report) async {
    updateReportCalled = true;
    lastUpdatedReport = report;
    final updatedReports = reports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
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
