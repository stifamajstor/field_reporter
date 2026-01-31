import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/presentation/entry_card.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/services/audio_recorder_service.dart';
import 'package:field_reporter/services/camera_service.dart';

void main() {
  group('User can add text note entry to report', () {
    late Report testReport;
    late List<Project> testProjects;
    late List<Entry> testEntries;

    setUp(() {
      testProjects = [
        const Project(
          id: 'proj-1',
          name: 'Construction Site A',
          status: ProjectStatus.active,
        ),
      ];

      testReport = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 0,
        createdAt: DateTime(2026, 1, 30, 14, 30),
      );

      testEntries = [];
    });

    Widget createTestWidget({
      Report? report,
      List<Project>? projects,
      List<Entry>? entries,
      void Function(Entry)? onEntryAdded,
    }) {
      final entriesList = entries ?? List<Entry>.from(testEntries);

      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: [report ?? testReport]);
          }),
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects ?? testProjects);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier(
              entries: entriesList,
              onEntryAdded: onEntryAdded,
            );
          }),
          audioRecorderServiceProvider
              .overrideWithValue(MockAudioRecorderService()),
          cameraServiceProvider.overrideWithValue(MockCameraService()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(
            report: report ?? testReport,
            projectId: 'proj-1',
          ),
        ),
      );
    }

    testWidgets('Step 1: Open Report Editor for a report', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Report Editor is open
      expect(find.text('Report Editor'), findsOneWidget);
      expect(find.text('Test Report'), findsOneWidget);
    });

    testWidgets('Step 2: Tap Add Entry button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to make Add Entry button visible
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Find and tap the Add Entry button
      final addEntryButton = find.text('Add Entry');
      expect(addEntryButton, findsOneWidget);

      await tester.tap(addEntryButton);
      await tester.pumpAndSettle();

      // Verify entry type options appear including Note
      expect(find.text('Note'), findsOneWidget);
    });

    testWidgets('Step 3-4: Select Note and verify text input screen appears',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll to make Add Entry button visible
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Add Entry button
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // Step 3: Select Note option
      final noteOption = find.text('Note');
      expect(noteOption, findsOneWidget);

      await tester.tap(noteOption);
      await tester.pumpAndSettle();

      // Step 4: Verify text input screen appears
      expect(find.byKey(const Key('note_text_field')), findsOneWidget);
      expect(find.text('Add Note'), findsOneWidget);
    });

    testWidgets('Step 5: Enter note text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to note input
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();

      // Step 5: Enter note text
      final noteTextField = find.byKey(const Key('note_text_field'));
      expect(noteTextField, findsOneWidget);

      await tester.enterText(noteTextField,
          'This is a test note with some important information.');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('This is a test note with some important information.'),
          findsOneWidget);
    });

    testWidgets('Step 6-7: Tap Save and verify note entry added to report',
        (tester) async {
      Entry? addedEntry;
      final entriesList = <Entry>[];

      await tester.pumpWidget(createTestWidget(
        entries: entriesList,
        onEntryAdded: (entry) => addedEntry = entry,
      ));
      await tester.pumpAndSettle();

      // Navigate to note input
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();

      // Enter note text
      final noteTextField = find.byKey(const Key('note_text_field'));
      await tester.enterText(noteTextField,
          'This is a test note with some important information.');
      await tester.pumpAndSettle();

      // Step 6: Tap Save button
      final saveButton = find.byKey(const Key('note_save_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Step 7: Verify note entry added to report
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.note);
      expect(addedEntry!.content,
          'This is a test note with some important information.');
      expect(addedEntry!.reportId, 'report-1');

      // Verify entry card is displayed
      expect(find.byType(EntryCard), findsOneWidget);
    });

    testWidgets('Step 8: Verify note preview shows truncated text',
        (tester) async {
      final longNoteText =
          'This is a very long note that should be truncated when displayed in the entry card preview. It contains much more text than can be shown in the two line preview area.';

      Entry? addedEntry;
      final entriesList = <Entry>[];

      await tester.pumpWidget(createTestWidget(
        entries: entriesList,
        onEntryAdded: (entry) => addedEntry = entry,
      ));
      await tester.pumpAndSettle();

      // Navigate to note input
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();

      // Enter long note text
      final noteTextField = find.byKey(const Key('note_text_field'));
      await tester.enterText(noteTextField, longNoteText);
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.byKey(const Key('note_save_button')));
      await tester.pumpAndSettle();

      // Verify entry was added
      expect(addedEntry, isNotNull);
      expect(addedEntry!.content, longNoteText);

      // Verify entry card is displayed with truncated text
      final entryCard = find.byType(EntryCard);
      expect(entryCard, findsOneWidget);

      // The card should display the note with ellipsis (truncated)
      // The text widget inside EntryCard has maxLines: 2 and overflow: ellipsis
      final textWidget = tester.widget<Text>(find.descendant(
        of: entryCard,
        matching: find.text(longNoteText),
      ));
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('Full flow: Add note entry from start to finish',
        (tester) async {
      Entry? addedEntry;
      final entriesList = <Entry>[];

      await tester.pumpWidget(createTestWidget(
        entries: entriesList,
        onEntryAdded: (entry) => addedEntry = entry,
      ));
      await tester.pumpAndSettle();

      // Step 1: Verify Report Editor is open
      expect(find.text('Report Editor'), findsOneWidget);

      // Scroll to make Add Entry button visible
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Step 2: Tap Add Entry button
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // Step 3: Select Note from options
      expect(find.text('Note'), findsOneWidget);
      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();

      // Step 4: Verify text input screen appears
      expect(find.byKey(const Key('note_text_field')), findsOneWidget);

      // Step 5: Enter note text
      await tester.enterText(find.byKey(const Key('note_text_field')),
          'Inspection note: Foundation cracks observed on north wall.');
      await tester.pumpAndSettle();

      // Step 6: Tap Save button
      await tester.tap(find.byKey(const Key('note_save_button')));
      await tester.pumpAndSettle();

      // Step 7: Verify note entry added to report
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.note);
      expect(addedEntry!.content,
          'Inspection note: Foundation cracks observed on north wall.');
      expect(addedEntry!.reportId, 'report-1');

      // Verify entry card is displayed
      expect(find.byType(EntryCard), findsOneWidget);

      // Step 8: Verify note preview shows truncated text (the card shows content)
      final noteTextFinder = find.descendant(
        of: find.byType(EntryCard),
        matching: find
            .text('Inspection note: Foundation cracks observed on north wall.'),
      );
      expect(noteTextFinder, findsOneWidget);
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
  Future<Report> createReport(Report report) async {
    reports.add(report);
    state = AsyncData(reports);
    return report;
  }

  @override
  Future<Report> updateReport(Report report) async {
    final index = reports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      reports[index] = report;
    }
    state = AsyncData(reports);
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

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  final List<Entry> entries;
  final void Function(Entry)? onEntryAdded;

  _MockEntriesNotifier({required this.entries, this.onEntryAdded});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }

  @override
  Future<Entry> addEntry(Entry entry) async {
    entries.add(entry);
    state = AsyncData(List<Entry>.from(entries));
    onEntryAdded?.call(entry);
    return entry;
  }
}

/// Mock AudioRecorderService for testing
class MockAudioRecorderService implements AudioRecorderService {
  @override
  Future<void> startRecording() async {}

  @override
  Future<AudioRecordingResult?> stopRecording() async => null;

  @override
  Future<void> startPlayback(String path) async {}

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> dispose() async {}
}

/// Mock CameraService for testing
class MockCameraService implements CameraService {
  @override
  Future<void> openCamera() async {}

  @override
  Future<String?> capturePhoto() async => null;

  @override
  Future<void> openCameraForVideo() async {}

  @override
  Future<void> startRecording() async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async => null;

  @override
  Future<void> closeCamera() async {}
}
