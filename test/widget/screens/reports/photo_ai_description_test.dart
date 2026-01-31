import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/presentation/entry_detail_screen.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';

void main() {
  group('User can request AI description for photo entry', () {
    late Entry photoEntryWithoutDescription;
    late Entry audioEntry;

    setUp(() {
      final now = DateTime(2026, 1, 31, 14, 30);

      photoEntryWithoutDescription = Entry(
        id: 'entry-photo-1',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo.jpg',
        aiDescription: null, // No AI description yet
        latitude: 45.8150,
        longitude: 15.9819,
        sortOrder: 0,
        capturedAt: now,
        createdAt: now,
      );

      audioEntry = Entry(
        id: 'entry-audio-1',
        reportId: 'report-1',
        type: EntryType.audio,
        mediaPath: '/test/audio.m4a',
        durationSeconds: 120,
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

    testWidgets('Generate Description button is visible for photo entry',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(entry: photoEntryWithoutDescription),
      );
      await tester.pumpAndSettle();

      // Verify 'Generate Description' button is visible
      expect(
          find.byKey(const Key('generate_description_button')), findsOneWidget);
      expect(find.text('Generate Description'), findsOneWidget);
    });

    testWidgets('Generate Description button is NOT visible for audio entry',
        (tester) async {
      await tester.pumpWidget(createTestWidget(entry: audioEntry));
      await tester.pumpAndSettle();

      // Verify 'Generate Description' button is NOT visible for non-photo entries
      expect(
          find.byKey(const Key('generate_description_button')), findsNothing);
    });

    testWidgets(
        'Tapping Generate Description button shows processing indicator',
        (tester) async {
      final mockNotifier = _MockEntriesNotifierWithSlowDescription(
        entries: [photoEntryWithoutDescription],
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: photoEntryWithoutDescription,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Tap 'Generate Description' button
      await tester.tap(find.byKey(const Key('generate_description_button')));
      await tester.pump();

      // Verify processing indicator appears
      expect(find.byKey(const Key('description_processing_indicator')),
          findsOneWidget);

      // Let the description generation complete
      await tester.pumpAndSettle();
    });

    testWidgets('AI-generated description appears after completion',
        (tester) async {
      final mockNotifier = _MockEntriesNotifierWithDescription(
        entries: [photoEntryWithoutDescription],
        descriptionResult:
            'A construction site showing concrete foundation with visible cracks.',
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: photoEntryWithoutDescription,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Tap 'Generate Description' button
      await tester.tap(find.byKey(const Key('generate_description_button')));
      await tester.pump();

      // Wait for description to complete
      await tester.pumpAndSettle();

      // Verify AI-generated description appears
      expect(find.byKey(const Key('ai_description_section')), findsOneWidget);
      expect(
          find.text(
              'A construction site showing concrete foundation with visible cracks.'),
          findsOneWidget);
    });

    testWidgets('AI description is editable', (tester) async {
      // Start with a photo entry that already has an AI description
      final photoWithDescription = photoEntryWithoutDescription.copyWith(
        aiDescription:
            'A construction site showing concrete foundation with visible cracks.',
      );

      final mockNotifier = _MockEntriesNotifier(
        entries: [photoWithDescription],
      );

      await tester.pumpWidget(
        createTestWidget(
          entry: photoWithDescription,
          entriesNotifier: mockNotifier,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to make the AI description section visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Tap on AI description to edit
      await tester.tap(find.byKey(const Key('ai_description_section')));
      await tester.pumpAndSettle();

      // Verify edit mode is active (text field appears)
      expect(
          find.byKey(const Key('ai_description_text_field')), findsOneWidget);

      // Enter corrected text
      await tester.enterText(
        find.byKey(const Key('ai_description_text_field')),
        'Updated description with additional details.',
      );
      await tester.pumpAndSettle();

      // Scroll to make the save button visible
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Save the correction
      await tester.tap(find.byKey(const Key('ai_description_save_button')));
      await tester.pumpAndSettle();

      // Verify corrected text is displayed
      expect(find.text('Updated description with additional details.'),
          findsOneWidget);
    });

    testWidgets(
        'Photo entry with existing AI description shows description section',
        (tester) async {
      final photoWithDescription = photoEntryWithoutDescription.copyWith(
        aiDescription: 'Existing AI description of the photo.',
      );

      await tester.pumpWidget(
        createTestWidget(entry: photoWithDescription),
      );
      await tester.pumpAndSettle();

      // Verify AI description section is shown
      expect(find.byKey(const Key('ai_description_section')), findsOneWidget);
      expect(
          find.text('Existing AI description of the photo.'), findsOneWidget);

      // Verify 'Generate Description' button is NOT shown (already generated)
      expect(
          find.byKey(const Key('generate_description_button')), findsNothing);
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

  @override
  Future<Entry> updateEntry(Entry entry) async {
    final currentEntries = state.valueOrNull ?? [];
    final updatedEntries = currentEntries.map((e) {
      return e.id == entry.id ? entry : e;
    }).toList();
    state = AsyncData(updatedEntries);
    return entry;
  }
}

/// Mock EntriesNotifier with description support
class _MockEntriesNotifierWithDescription extends EntriesNotifier {
  final List<Entry> entries;
  final String? descriptionResult;

  _MockEntriesNotifierWithDescription({
    required this.entries,
    this.descriptionResult,
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
  Future<Entry> generateDescription(String entryId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final currentEntries = state.valueOrNull ?? [];
    final entry = currentEntries.firstWhere((e) => e.id == entryId);
    final describedEntry = entry.copyWith(aiDescription: descriptionResult);
    await updateEntry(describedEntry);
    return describedEntry;
  }
}

/// Mock EntriesNotifier with slow description for testing processing indicator
class _MockEntriesNotifierWithSlowDescription extends EntriesNotifier {
  final List<Entry> entries;

  _MockEntriesNotifierWithSlowDescription({required this.entries});

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
  Future<Entry> generateDescription(String entryId) async {
    // Simulate slow AI processing
    await Future.delayed(const Duration(milliseconds: 500));
    final currentEntries = state.valueOrNull ?? [];
    final entry = currentEntries.firstWhere((e) => e.id == entryId);
    final describedEntry =
        entry.copyWith(aiDescription: 'AI-generated description of photo.');
    await updateEntry(describedEntry);
    return describedEntry;
  }
}
