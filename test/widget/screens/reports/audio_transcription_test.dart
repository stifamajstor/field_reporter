import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/presentation/entry_detail_screen.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';

void main() {
  group('User can request AI transcription for audio entry', () {
    late Entry audioEntryWithoutTranscription;
    late Entry photoEntry;

    setUp(() {
      final now = DateTime(2026, 1, 31, 14, 30);

      audioEntryWithoutTranscription = Entry(
        id: 'entry-audio-1',
        reportId: 'report-1',
        type: EntryType.audio,
        mediaPath: '/test/audio.m4a',
        durationSeconds: 120,
        content: null, // No transcription yet
        latitude: 45.8150,
        longitude: 15.9819,
        sortOrder: 0,
        capturedAt: now,
        createdAt: now,
      );

      photoEntry = Entry(
        id: 'entry-photo-1',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo.jpg',
        sortOrder: 1,
        capturedAt: now,
        createdAt: now,
      );
    });

    Widget createTestWidget({
      required Entry entry,
      EntriesNotifier? entriesNotifier,
    }) {
      return ProviderScope(
        overrides: [
          entriesNotifierProvider.overrideWith(() {
            return entriesNotifier ?? _MockEntriesNotifier(entries: [entry]);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: EntryDetailScreen(entry: entry),
        ),
      );
    }

    testWidgets('Transcribe button is visible for audio entry', (tester) async {
      await tester.pumpWidget(
        createTestWidget(entry: audioEntryWithoutTranscription),
      );
      await tester.pumpAndSettle();

      // Verify 'Transcribe' button is visible
      expect(find.byKey(const Key('transcribe_button')), findsOneWidget);
      expect(find.text('Transcribe'), findsOneWidget);
    });

    testWidgets('Transcribe button is NOT visible for photo entry',
        (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify 'Transcribe' button is NOT visible for non-audio entries
      expect(find.byKey(const Key('transcribe_button')), findsNothing);
    });

    testWidgets('Tapping Transcribe button shows processing indicator',
        (tester) async {
      final mockNotifier = _MockEntriesNotifierWithSlowTranscription(
        entries: [audioEntryWithoutTranscription],
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: audioEntryWithoutTranscription,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Transcribe' button
      await tester.tap(find.byKey(const Key('transcribe_button')));
      await tester.pump();

      // Verify processing indicator appears
      expect(find.byKey(const Key('transcription_processing_indicator')),
          findsOneWidget);

      // Let the transcription complete
      await tester.pumpAndSettle();
    });

    testWidgets('Transcribed text appears after completion', (tester) async {
      final mockNotifier = _MockEntriesNotifierWithTranscription(
        entries: [audioEntryWithoutTranscription],
        transcriptionResult: 'This is the transcribed audio content.',
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: audioEntryWithoutTranscription,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Transcribe' button
      await tester.tap(find.byKey(const Key('transcribe_button')));
      await tester.pump();

      // Wait for transcription to complete
      await tester.pumpAndSettle();

      // Verify transcribed text appears
      expect(find.byKey(const Key('transcription_section')), findsOneWidget);
      expect(
          find.text('This is the transcribed audio content.'), findsOneWidget);
    });

    testWidgets('Transcribed text is editable for corrections', (tester) async {
      // Start with an audio entry that already has a transcription
      final audioWithTranscription = audioEntryWithoutTranscription.copyWith(
        content: 'This is the transcribed audio content.',
      );

      final mockNotifier = _MockEntriesNotifier(
        entries: [audioWithTranscription],
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: audioWithTranscription,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on transcription to edit
      await tester.tap(find.byKey(const Key('transcription_section')));
      await tester.pumpAndSettle();

      // Verify edit mode is active (text field appears)
      expect(find.byKey(const Key('transcription_text_field')), findsOneWidget);

      // Enter corrected text
      await tester.enterText(
        find.byKey(const Key('transcription_text_field')),
        'This is the corrected transcription.',
      );
      await tester.pumpAndSettle();

      // Scroll to make the save button visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Save the correction
      await tester.tap(find.byKey(const Key('transcription_save_button')));
      await tester.pumpAndSettle();

      // Verify corrected text is displayed
      expect(find.text('This is the corrected transcription.'), findsOneWidget);
    });

    testWidgets(
        'Audio entry with existing transcription shows transcription section',
        (tester) async {
      final audioWithTranscription = audioEntryWithoutTranscription.copyWith(
        content: 'Existing transcription text.',
      );

      await tester.pumpWidget(
        createTestWidget(entry: audioWithTranscription),
      );
      await tester.pumpAndSettle();

      // Verify transcription section is shown
      expect(find.byKey(const Key('transcription_section')), findsOneWidget);
      expect(find.text('Existing transcription text.'), findsOneWidget);

      // Verify 'Transcribe' button is NOT shown (already transcribed)
      expect(find.byKey(const Key('transcribe_button')), findsNothing);
    });
  });
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

/// Mock EntriesNotifier with transcription support
class _MockEntriesNotifierWithTranscription extends EntriesNotifier {
  final List<Entry> entries;
  final String? transcriptionResult;

  _MockEntriesNotifierWithTranscription({
    required this.entries,
    this.transcriptionResult,
  });

  @override
  Future<List<Entry>> build() async {
    return entries;
  }

  @override
  Future<Entry> updateEntry(Entry entry) async {
    final currentEntries = state.valueOrNull ?? [];
    final updatedEntries = currentEntries.map((e) {
      return e.id == entry.id ? entry : e;
    }).toList();
    state = AsyncData(updatedEntries);
    return entry;
  }

  @override
  Future<Entry> transcribeEntry(String entryId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final currentEntries = state.valueOrNull ?? [];
    final entry = currentEntries.firstWhere((e) => e.id == entryId);
    final transcribedEntry = entry.copyWith(content: transcriptionResult);
    await updateEntry(transcribedEntry);
    return transcribedEntry;
  }
}

/// Mock EntriesNotifier with slow transcription for testing processing indicator
class _MockEntriesNotifierWithSlowTranscription extends EntriesNotifier {
  final List<Entry> entries;

  _MockEntriesNotifierWithSlowTranscription({required this.entries});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }

  @override
  Future<Entry> updateEntry(Entry entry) async {
    final currentEntries = state.valueOrNull ?? [];
    final updatedEntries = currentEntries.map((e) {
      return e.id == entry.id ? entry : e;
    }).toList();
    state = AsyncData(updatedEntries);
    return entry;
  }

  @override
  Future<Entry> transcribeEntry(String entryId) async {
    // Simulate slow transcription
    await Future.delayed(const Duration(milliseconds: 500));
    final currentEntries = state.valueOrNull ?? [];
    final entry = currentEntries.firstWhere((e) => e.id == entryId);
    final transcribedEntry =
        entry.copyWith(content: 'Transcribed audio content.');
    await updateEntry(transcribedEntry);
    return transcribedEntry;
  }
}
