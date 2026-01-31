import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/presentation/entry_detail_screen.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';

void main() {
  group('AI processing failure shows appropriate error', () {
    late Entry audioEntry;

    setUp(() {
      final now = DateTime(2026, 1, 31, 14, 30);

      audioEntry = Entry(
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
    });

    Widget createTestWidget({
      required Entry entry,
      EntriesNotifier? entriesNotifier,
    }) {
      return ProviderScope(
        overrides: [
          entriesNotifierProvider.overrideWith(() {
            return entriesNotifier ??
                _MockEntriesNotifierWithAIFailure(entries: [entry]);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: EntryDetailScreen(entry: entry),
        ),
      );
    }

    testWidgets('AI API failure shows error message', (tester) async {
      final mockNotifier = _MockEntriesNotifierWithAIFailure(
        entries: [audioEntry],
        shouldFail: true,
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: audioEntry,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Open Entry and request AI transcription
      expect(find.byKey(const Key('transcribe_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('transcribe_button')));
      await tester.pump();

      // Simulate AI API failure - wait for processing
      await tester.pumpAndSettle();

      // Verify error message displayed
      expect(find.byKey(const Key('ai_error_message')), findsOneWidget);
      expect(find.text('Transcription failed'), findsOneWidget);
    });

    testWidgets('Retry option is available after AI failure', (tester) async {
      final mockNotifier = _MockEntriesNotifierWithAIFailure(
        entries: [audioEntry],
        shouldFail: true,
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: audioEntry,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Request AI transcription
      await tester.tap(find.byKey(const Key('transcribe_button')));
      await tester.pumpAndSettle();

      // Verify 'Retry' option available
      expect(find.byKey(const Key('ai_retry_button')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Entry is still functional without AI after failure',
        (tester) async {
      final mockNotifier = _MockEntriesNotifierWithAIFailure(
        entries: [audioEntry],
        shouldFail: true,
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: audioEntry,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Request AI transcription - this will fail
      await tester.tap(find.byKey(const Key('transcribe_button')));
      await tester.pumpAndSettle();

      // Entry is still functional - media display should be present
      expect(find.byKey(const Key('entry_media_display')), findsOneWidget);

      // Edit and delete buttons should still be available
      expect(find.byKey(const Key('edit_entry_button')), findsOneWidget);
      expect(find.byKey(const Key('delete_entry_button')), findsOneWidget);

      // Metadata section should still be visible
      expect(find.byKey(const Key('metadata_section')), findsOneWidget);
    });

    testWidgets('Retry button works and clears error state on successful retry',
        (tester) async {
      final retryState = _RetryState();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entriesNotifierProvider.overrideWith(() {
              return _MockEntriesNotifierWithRetry(
                entries: [audioEntry],
                retryState: retryState,
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: EntryDetailScreen(entry: audioEntry),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Request AI transcription - this will fail first time
      await tester.tap(find.byKey(const Key('transcribe_button')));
      await tester.pumpAndSettle();

      // Verify error shown
      expect(find.byKey(const Key('ai_error_message')), findsOneWidget);

      // Tap retry button
      await tester.tap(find.byKey(const Key('ai_retry_button')));
      await tester.pump(); // Frame for setState
      await tester.pump(const Duration(milliseconds: 200)); // Wait for async
      await tester.pumpAndSettle();

      // After successful retry, the transcription section should appear
      // (the content was updated with the retry result)
      expect(find.text('Successfully transcribed on retry.'), findsOneWidget);
    });

    testWidgets('Error message shows specific error details', (tester) async {
      final mockNotifier = _MockEntriesNotifierWithAIFailure(
        entries: [audioEntry],
        shouldFail: true,
        errorMessage: 'Network connection failed',
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: audioEntry,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Request AI transcription
      await tester.tap(find.byKey(const Key('transcribe_button')));
      await tester.pumpAndSettle();

      // Verify specific error message is displayed
      expect(find.text('Network connection failed'), findsOneWidget);
    });
  });
}

/// Mock EntriesNotifier that simulates AI API failure.
class _MockEntriesNotifierWithAIFailure extends EntriesNotifier {
  final List<Entry> entries;
  final bool shouldFail;
  final String errorMessage;

  _MockEntriesNotifierWithAIFailure({
    required this.entries,
    this.shouldFail = false,
    this.errorMessage = 'AI service unavailable',
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
    if (shouldFail) {
      throw Exception(errorMessage);
    }
    final currentEntries = state.valueOrNull ?? [];
    final entry = currentEntries.firstWhere((e) => e.id == entryId);
    final transcribedEntry = entry.copyWith(content: 'Transcribed content.');
    await updateEntry(transcribedEntry);
    return transcribedEntry;
  }

  @override
  Future<Entry> generateDescription(String entryId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (shouldFail) {
      throw Exception(errorMessage);
    }
    final currentEntries = state.valueOrNull ?? [];
    final entry = currentEntries.firstWhere((e) => e.id == entryId);
    final describedEntry = entry.copyWith(aiDescription: 'AI description.');
    await updateEntry(describedEntry);
    return describedEntry;
  }
}

/// Shared state for retry counter across notifier instances.
class _RetryState {
  int transcriptionAttempts = 0;
}

/// Mock EntriesNotifier that fails first, then succeeds on retry.
class _MockEntriesNotifierWithRetry extends EntriesNotifier {
  final List<Entry> entries;
  final _RetryState retryState;

  _MockEntriesNotifierWithRetry({
    required this.entries,
    required this.retryState,
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
    retryState.transcriptionAttempts++;

    if (retryState.transcriptionAttempts == 1) {
      // Fail on first attempt
      throw Exception('AI service unavailable');
    }

    // Succeed on subsequent attempts
    final currentEntries = state.valueOrNull ?? [];
    final entry = currentEntries.firstWhere((e) => e.id == entryId);
    final transcribedEntry =
        entry.copyWith(content: 'Successfully transcribed on retry.');
    await updateEntry(transcribedEntry);
    return transcribedEntry;
  }
}
