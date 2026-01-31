import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/presentation/entry_detail_screen.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';

void main() {
  group('User can view entry details', () {
    late Entry photoEntry;
    late Entry videoEntry;
    late Entry audioEntry;
    late Entry noteEntry;
    late Entry scanEntry;

    setUp(() {
      final now = DateTime(2026, 1, 30, 14, 30);

      photoEntry = Entry(
        id: 'entry-1',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo.jpg',
        thumbnailPath: '/test/photo_thumb.jpg',
        aiDescription: 'AI generated description of the photo',
        latitude: 45.8150,
        longitude: 15.9819,
        address: '123 Test Street, City',
        compassHeading: 180.0,
        sensorData: '{"accelerometer": [0.1, 0.2, 9.8]}',
        sortOrder: 0,
        capturedAt: now,
        createdAt: now,
      );

      videoEntry = Entry(
        id: 'entry-2',
        reportId: 'report-1',
        type: EntryType.video,
        mediaPath: '/test/video.mp4',
        thumbnailPath: '/test/video_thumb.jpg',
        durationSeconds: 45,
        aiDescription: 'AI description of video content',
        latitude: 45.8150,
        longitude: 15.9819,
        sortOrder: 1,
        capturedAt: now,
        createdAt: now,
      );

      audioEntry = Entry(
        id: 'entry-3',
        reportId: 'report-1',
        type: EntryType.audio,
        mediaPath: '/test/audio.m4a',
        durationSeconds: 120,
        content: 'Transcribed audio content here',
        latitude: 45.8150,
        longitude: 15.9819,
        sortOrder: 2,
        capturedAt: now,
        createdAt: now,
      );

      noteEntry = Entry(
        id: 'entry-4',
        reportId: 'report-1',
        type: EntryType.note,
        content: 'This is a text note with detailed observations.',
        sortOrder: 3,
        capturedAt: now,
        createdAt: now,
      );

      scanEntry = Entry(
        id: 'entry-5',
        reportId: 'report-1',
        type: EntryType.scan,
        content: 'ABC-123-XYZ',
        sortOrder: 4,
        capturedAt: now,
        createdAt: now,
      );
    });

    Widget createTestWidget({
      required Entry entry,
      List<Entry>? allEntries,
    }) {
      return ProviderScope(
        overrides: [
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier(entries: allEntries ?? [entry]);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: EntryDetailScreen(entry: entry),
        ),
      );
    }

    testWidgets('Entry Detail screen opens when tapping on entry',
        (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify screen is displayed
      expect(find.byType(EntryDetailScreen), findsOneWidget);
    });

    testWidgets('displays photo entry with full media', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify photo is displayed (placeholder or image widget)
      expect(find.byKey(const Key('entry_media_display')), findsOneWidget);
      // Verify type indicator (appears in app bar and badge)
      expect(find.text('Photo'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays video entry with player', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: videoEntry));
      await tester.pumpAndSettle();

      // Verify video player area is displayed
      expect(find.byKey(const Key('entry_media_display')), findsOneWidget);
      // Verify type indicator (appears in app bar and badge)
      expect(find.text('Video'), findsAtLeastNWidgets(1));
      // Verify duration is shown
      expect(find.text('0:45'), findsOneWidget);
    });

    testWidgets('displays audio entry with player', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: audioEntry));
      await tester.pumpAndSettle();

      // Verify audio player area is displayed
      expect(find.byKey(const Key('entry_media_display')), findsOneWidget);
      // Verify type indicator (appears in app bar and badge)
      expect(find.text('Voice Memo'), findsAtLeastNWidgets(1));
      // Verify duration is shown
      expect(find.text('2:00'), findsOneWidget);
    });

    testWidgets('displays metadata section with GPS coordinates',
        (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify metadata section exists
      expect(find.byKey(const Key('metadata_section')), findsOneWidget);

      // Verify GPS coordinates are shown
      expect(find.textContaining('45.8150'), findsOneWidget);
      expect(find.textContaining('15.9819'), findsOneWidget);
    });

    testWidgets('displays metadata section with timestamp', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify timestamp is shown (format may vary, appears in header and metadata)
      expect(find.textContaining('2:30 PM'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays metadata section with address', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify address is shown
      expect(find.text('123 Test Street, City'), findsOneWidget);
    });

    testWidgets('displays sensor data when available', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify compass heading is shown
      expect(find.textContaining('180'), findsOneWidget);
    });

    testWidgets('displays AI-generated description when available',
        (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify AI description section exists and shows content
      expect(find.byKey(const Key('ai_description_section')), findsOneWidget);
      expect(
          find.text('AI generated description of the photo'), findsOneWidget);
    });

    testWidgets('hides AI description section when not available',
        (tester) async {
      await tester.pumpWidget(createTestWidget(entry: noteEntry));
      await tester.pumpAndSettle();

      // Verify AI description section is not shown
      expect(find.byKey(const Key('ai_description_section')), findsNothing);
    });

    testWidgets('edit option is available', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify edit button exists
      expect(find.byKey(const Key('edit_entry_button')), findsOneWidget);
    });

    testWidgets('delete option is available', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: photoEntry));
      await tester.pumpAndSettle();

      // Verify delete button exists
      expect(find.byKey(const Key('delete_entry_button')), findsOneWidget);
    });

    testWidgets('displays note entry with full text content', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: noteEntry));
      await tester.pumpAndSettle();

      // Verify note content is fully displayed
      expect(find.text('This is a text note with detailed observations.'),
          findsOneWidget);
      // Verify type indicator (appears in app bar, badge, and content section)
      expect(find.text('Note'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays scan entry with scanned data', (tester) async {
      await tester.pumpWidget(createTestWidget(entry: scanEntry));
      await tester.pumpAndSettle();

      // Verify scanned data is displayed
      expect(find.text('ABC-123-XYZ'), findsOneWidget);
      // Verify type indicator (appears in app bar and badge)
      expect(find.text('Scan'), findsAtLeastNWidgets(1));
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
