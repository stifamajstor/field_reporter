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

void main() {
  group('User can add voice memo entry to report', () {
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
      MockAudioRecorderService? audioRecorderService,
      void Function(Entry)? onEntryAdded,
    }) {
      final mockAudioRecorder =
          audioRecorderService ?? MockAudioRecorderService();
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
          audioRecorderServiceProvider.overrideWithValue(mockAudioRecorder),
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

      // Verify entry type options appear including Voice Memo
      expect(find.text('Voice Memo'), findsOneWidget);
    });

    testWidgets(
        'Step 3-4: Select Voice Memo and verify audio recording UI appears',
        (tester) async {
      final mockAudioRecorder = MockAudioRecorderService();

      await tester.pumpWidget(
          createTestWidget(audioRecorderService: mockAudioRecorder));
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

      // Select Voice Memo option
      final voiceMemoOption = find.text('Voice Memo');
      expect(voiceMemoOption, findsOneWidget);

      await tester.tap(voiceMemoOption);
      await tester.pumpAndSettle();

      // Step 4: Verify audio recording UI appears
      expect(find.text('Voice Memo'), findsWidgets); // Title in recording UI
      expect(find.byIcon(Icons.mic), findsWidgets);
    });

    testWidgets(
        'Step 5-6: Tap record button and verify recording indicator and timer',
        (tester) async {
      final mockAudioRecorder = MockAudioRecorderService(
        recordedAudioPath: '/mock/audio/voice_memo.m4a',
        recordedDuration: 5,
      );

      await tester.pumpWidget(
          createTestWidget(audioRecorderService: mockAudioRecorder));
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

      // Select Voice Memo option
      await tester.tap(find.text('Voice Memo'));
      await tester.pumpAndSettle();

      // Step 5: Tap record button
      final recordButton = find.byKey(const Key('record_button'));
      expect(recordButton, findsOneWidget);
      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      // Step 6: Verify recording indicator and timer
      expect(mockAudioRecorder.startRecordingCalled, isTrue);
      expect(find.text('Recording...'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d+:\d{2}')),
          findsWidgets); // Timer format
    });

    testWidgets('Step 7-8: Speak and tap stop, verify playback controls appear',
        (tester) async {
      final mockAudioRecorder = MockAudioRecorderService(
        recordedAudioPath: '/mock/audio/voice_memo.m4a',
        recordedDuration: 5,
      );

      await tester.pumpWidget(
          createTestWidget(audioRecorderService: mockAudioRecorder));
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

      // Select Voice Memo option
      await tester.tap(find.text('Voice Memo'));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pumpAndSettle();

      // Step 8: Tap stop button
      final stopButton = find.byKey(const Key('stop_button'));
      expect(stopButton, findsOneWidget);
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      // Verify stop was called
      expect(mockAudioRecorder.stopRecordingCalled, isTrue);

      // Step 9: Verify playback controls appear
      expect(find.byKey(const Key('play_button')), findsOneWidget);
    });

    testWidgets('Step 10: Play back to verify recording', (tester) async {
      final mockAudioRecorder = MockAudioRecorderService(
        recordedAudioPath: '/mock/audio/voice_memo.m4a',
        recordedDuration: 5,
      );

      await tester.pumpWidget(
          createTestWidget(audioRecorderService: mockAudioRecorder));
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

      // Select Voice Memo option
      await tester.tap(find.text('Voice Memo'));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pumpAndSettle();

      // Stop recording
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Step 10: Play back
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pumpAndSettle();

      expect(mockAudioRecorder.playbackStarted, isTrue);
    });

    testWidgets('Step 11-12: Tap Save and verify audio entry added to report',
        (tester) async {
      final mockAudioRecorder = MockAudioRecorderService(
        recordedAudioPath: '/mock/audio/voice_memo.m4a',
        recordedDuration: 5,
      );

      Entry? addedEntry;
      final entriesList = <Entry>[];

      await tester.pumpWidget(createTestWidget(
        audioRecorderService: mockAudioRecorder,
        entries: entriesList,
        onEntryAdded: (entry) => addedEntry = entry,
      ));
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

      // Select Voice Memo option
      await tester.tap(find.text('Voice Memo'));
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pumpAndSettle();

      // Stop recording
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Step 11: Tap Save
      final saveButton = find.byKey(const Key('voice_memo_save_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Step 12: Verify audio entry added to report
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.audio);
      expect(addedEntry!.mediaPath, '/mock/audio/voice_memo.m4a');
      expect(addedEntry!.durationSeconds, 5);
      expect(addedEntry!.reportId, 'report-1');

      // Verify entry card is displayed
      expect(find.byType(EntryCard), findsOneWidget);
    });

    testWidgets('Full flow: Add voice memo entry from start to finish',
        (tester) async {
      final mockAudioRecorder = MockAudioRecorderService(
        recordedAudioPath: '/mock/audio/voice_memo.m4a',
        recordedDuration: 5,
      );

      Entry? addedEntry;
      final entriesList = <Entry>[];

      await tester.pumpWidget(createTestWidget(
        audioRecorderService: mockAudioRecorder,
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

      // Step 3: Select Voice Memo from options
      expect(find.text('Voice Memo'), findsOneWidget);
      await tester.tap(find.text('Voice Memo'));
      await tester.pumpAndSettle();

      // Step 4: Verify audio recording UI appears
      expect(find.byIcon(Icons.mic), findsWidgets);

      // Step 5: Tap record button
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pumpAndSettle();

      // Step 6: Verify recording indicator and timer
      expect(mockAudioRecorder.startRecordingCalled, isTrue);
      expect(find.text('Recording...'), findsOneWidget);

      // Step 7: Speak for a few seconds (simulated by mock)
      // Step 8: Tap stop button
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Step 9: Verify playback controls appear
      expect(find.byKey(const Key('play_button')), findsOneWidget);

      // Step 10: Play back to verify recording
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pumpAndSettle();
      expect(mockAudioRecorder.playbackStarted, isTrue);

      // Step 11: Tap Save
      await tester.tap(find.byKey(const Key('voice_memo_save_button')));
      await tester.pumpAndSettle();

      // Step 12: Verify audio entry added to report
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.audio);
      expect(addedEntry!.reportId, 'report-1');

      // Verify entry card is displayed
      expect(find.byType(EntryCard), findsOneWidget);
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

/// Mock AudioRecorderService for testing voice memo recording
class MockAudioRecorderService implements AudioRecorderService {
  final String? recordedAudioPath;
  final int? recordedDuration;

  bool startRecordingCalled = false;
  bool stopRecordingCalled = false;
  bool playbackStarted = false;
  List<double> _recordedWaveform = [];

  MockAudioRecorderService({
    this.recordedAudioPath,
    this.recordedDuration,
  });

  @override
  Future<void> startRecording() async {
    startRecordingCalled = true;
  }

  @override
  Future<AudioRecordingResult?> stopRecording() async {
    stopRecordingCalled = true;
    if (recordedAudioPath != null) {
      return AudioRecordingResult(
        path: recordedAudioPath!,
        durationSeconds: recordedDuration ?? 0,
      );
    }
    return null;
  }

  @override
  Future<void> startPlayback(String path) async {
    playbackStarted = true;
  }

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> pausePlayback() async {}

  @override
  Future<void> resumePlayback() async {}

  @override
  void setPositionListener(void Function(Duration)? listener) {}

  @override
  void setCompletionListener(void Function()? listener) {}

  @override
  void setAmplitudeListener(void Function(List<double>)? listener) {}

  @override
  void setPlaybackWaveformListener(void Function(List<double>)? listener) {}

  @override
  List<double> get recordedWaveform => _recordedWaveform;

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Future<void> dispose() async {}
}
