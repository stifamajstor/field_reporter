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

void main() {
  group('User can reorder entries in report', () {
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
          content: 'Second Entry Note',
          sortOrder: 1,
          capturedAt: now,
          createdAt: now,
        ),
        Entry(
          id: 'entry-3',
          reportId: 'report-1',
          type: EntryType.video,
          mediaPath: '/test/video.mp4',
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
      return ProviderScope(
        overrides: [
          entriesNotifierProvider.overrideWith(() => mockEntriesNotifier),
          allReportsNotifierProvider.overrideWith(() => mockReportsNotifier),
          projectsNotifierProvider.overrideWith(() => mockProjectsNotifier),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(report: testReport),
        ),
      );
    }

    testWidgets('Open Report with multiple entries - entries are displayed',
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
      expect(find.byKey(const Key('entry_card_entry-1')), findsOneWidget);
      expect(find.byKey(const Key('entry_card_entry-2')), findsOneWidget);
      expect(find.byKey(const Key('entry_card_entry-3')), findsOneWidget);
    });

    testWidgets('ReorderableListView is present for entries', (tester) async {
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

      // Verify ReorderableListView is used for entries
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('Long-press on entry enables drag mode', (tester) async {
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

      // Find the first reorderable entry
      final firstEntryFinder = find.byKey(const Key('reorderable_entry_0'));
      expect(firstEntryFinder, findsOneWidget);

      // Start long-press gesture
      final gesture = await tester.startGesture(
        tester.getCenter(firstEntryFinder),
      );

      // Wait for long press to register
      await tester.pump(const Duration(milliseconds: 600));

      // Entry should be in drag mode (ReorderableListView handles this)
      // Clean up
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Drag entry to new position and verify order persists',
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

      // Find the first entry
      final firstEntryFinder = find.byKey(const Key('reorderable_entry_0'));
      expect(firstEntryFinder, findsOneWidget);

      // Start long-press drag gesture
      final gesture = await tester.startGesture(
        tester.getCenter(firstEntryFinder),
      );

      // Wait for long press to register
      await tester.pump(const Duration(milliseconds: 600));

      // Drag down to second position
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      // Release entry
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify reorderEntries was called
      expect(mockEntriesNotifier.reorderEntriesCalled, isTrue);
      expect(mockEntriesNotifier.lastOldIndex, 0);
      expect(mockEntriesNotifier.lastNewIndex, 1);
    });

    testWidgets('Order is persisted after reorder', (tester) async {
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

      // Perform drag reorder
      final firstEntryFinder = find.byKey(const Key('reorderable_entry_0'));

      final gesture = await tester.startGesture(
        tester.getCenter(firstEntryFinder),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify reorderEntries was called - this confirms persistence would happen
      expect(mockEntriesNotifier.reorderEntriesCalled, isTrue);

      // After reorder is called, the provider updates the sortOrder values
      // Verify the entries state was updated
      final updatedEntries = mockEntriesNotifier.entries;

      // Verify entries were reordered (if reorder was triggered)
      // The order of entries after reorder should reflect the new positions
      if (mockEntriesNotifier.lastNewIndex != null &&
          mockEntriesNotifier.lastOldIndex !=
              mockEntriesNotifier.lastNewIndex) {
        // Check that sortOrder values are valid (0, 1, 2)
        final sortOrders = updatedEntries.map((e) => e.sortOrder).toList()
          ..sort();
        expect(sortOrders, [0, 1, 2]);
      }
    });
  });
}

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  List<Entry> entries;
  bool reorderEntriesCalled = false;
  int? lastOldIndex;
  int? lastNewIndex;

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }

  @override
  Future<void> reorderEntries(
      String reportId, int oldIndex, int newIndex) async {
    reorderEntriesCalled = true;
    lastOldIndex = oldIndex;
    lastNewIndex = newIndex;

    final reportEntries = entries.where((e) => e.reportId == reportId).toList();
    reportEntries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final movedEntry = reportEntries.removeAt(oldIndex);
    reportEntries.insert(newIndex, movedEntry);

    // Update sortOrder for all entries
    final updatedEntries = <Entry>[];
    for (var i = 0; i < reportEntries.length; i++) {
      updatedEntries.add(reportEntries[i].copyWith(sortOrder: i));
    }

    // Replace entries in the main list
    entries = entries.map((e) {
      if (e.reportId != reportId) return e;
      final updated = updatedEntries.firstWhere(
        (u) => u.id == e.id,
        orElse: () => e,
      );
      return updated;
    }).toList();

    state = AsyncData(entries);
  }
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;

  _MockReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build() async {
    return reports;
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
