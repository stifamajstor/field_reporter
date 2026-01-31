import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/presentation/entry_detail_screen.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';

void main() {
  group('User can edit entry annotation/notes', () {
    late Entry photoEntry;
    late List<Entry> allEntries;

    setUp(() {
      final now = DateTime(2026, 1, 30, 14, 30);

      photoEntry = Entry(
        id: 'entry-1',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo.jpg',
        annotation: 'Initial annotation',
        sortOrder: 0,
        capturedAt: now,
        createdAt: now,
      );

      allEntries = [photoEntry];
    });

    Widget createTestWidget({
      required Entry entry,
      required _MockEntriesNotifier mockNotifier,
    }) {
      return ProviderScope(
        overrides: [
          entriesNotifierProvider.overrideWith(() => mockNotifier),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: EntryDetailScreen(entry: entry),
        ),
      );
    }

    testWidgets('Navigate to Entry Detail screen', (tester) async {
      final mockNotifier = _MockEntriesNotifier(entries: allEntries);
      await tester.pumpWidget(createTestWidget(
        entry: photoEntry,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Verify Entry Detail screen is displayed
      expect(find.byType(EntryDetailScreen), findsOneWidget);
    });

    testWidgets('Tap on annotation/notes field - text input becomes active',
        (tester) async {
      final mockNotifier = _MockEntriesNotifier(entries: allEntries);
      await tester.pumpWidget(createTestWidget(
        entry: photoEntry,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Scroll to find and tap annotation field
      final annotationField = find.byKey(const Key('annotation_field'));
      await tester.scrollUntilVisible(annotationField, 100);
      await tester.pumpAndSettle();

      expect(annotationField, findsOneWidget);
      await tester.tap(annotationField);
      await tester.pumpAndSettle();

      // Verify text field is editable (focused)
      final textField = find.byKey(const Key('annotation_text_field'));
      expect(textField, findsOneWidget);
    });

    testWidgets('Add or modify annotation text', (tester) async {
      final mockNotifier = _MockEntriesNotifier(entries: allEntries);
      await tester.pumpWidget(createTestWidget(
        entry: photoEntry,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Scroll to and tap annotation field to activate it
      final annotationField = find.byKey(const Key('annotation_field'));
      await tester.scrollUntilVisible(annotationField, 100);
      await tester.pumpAndSettle();
      await tester.tap(annotationField);
      await tester.pumpAndSettle();

      // Find the text field and enter new text
      final textField = find.byKey(const Key('annotation_text_field'));
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Updated annotation text');
      await tester.pumpAndSettle();

      // Verify the text was entered
      expect(find.text('Updated annotation text'), findsOneWidget);
    });

    testWidgets('Tap save or tap outside - changes are saved', (tester) async {
      final mockNotifier = _MockEntriesNotifier(entries: allEntries);
      await tester.pumpWidget(createTestWidget(
        entry: photoEntry,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Scroll to and tap annotation field to activate it
      final annotationField = find.byKey(const Key('annotation_field'));
      await tester.scrollUntilVisible(annotationField, 100);
      await tester.pumpAndSettle();
      await tester.tap(annotationField);
      await tester.pumpAndSettle();

      // Enter new text
      final textField = find.byKey(const Key('annotation_text_field'));
      await tester.enterText(textField, 'Updated annotation text');
      await tester.pumpAndSettle();

      // Tap save button
      final saveButton = find.byKey(const Key('annotation_save_button'));
      expect(saveButton, findsOneWidget);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify updateEntry was called
      expect(mockNotifier.updateEntryCalled, isTrue);
      expect(
          mockNotifier.lastUpdatedEntry?.annotation, 'Updated annotation text');
    });

    testWidgets('Return to report - annotation visible in entry preview',
        (tester) async {
      // Create entry with annotation already set
      final entryWithAnnotation = Entry(
        id: 'entry-1',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo.jpg',
        annotation: 'Visible annotation',
        sortOrder: 0,
        capturedAt: DateTime(2026, 1, 30, 14, 30),
        createdAt: DateTime(2026, 1, 30, 14, 30),
      );

      final mockNotifier = _MockEntriesNotifier(entries: [entryWithAnnotation]);
      await tester.pumpWidget(createTestWidget(
        entry: entryWithAnnotation,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Scroll to annotation section
      final annotationSection = find.byKey(const Key('annotation_section'));
      await tester.scrollUntilVisible(annotationSection, 100);
      await tester.pumpAndSettle();

      // Verify annotation is displayed in the annotation section
      expect(annotationSection, findsOneWidget);
      expect(find.text('Visible annotation'), findsOneWidget);
    });

    testWidgets('Entry without annotation shows add annotation option',
        (tester) async {
      final entryWithoutAnnotation = Entry(
        id: 'entry-2',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo2.jpg',
        sortOrder: 1,
        capturedAt: DateTime(2026, 1, 30, 14, 30),
        createdAt: DateTime(2026, 1, 30, 14, 30),
      );

      final mockNotifier =
          _MockEntriesNotifier(entries: [entryWithoutAnnotation]);
      await tester.pumpWidget(createTestWidget(
        entry: entryWithoutAnnotation,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Scroll to add annotation button
      final addButton = find.byKey(const Key('add_annotation_button'));
      await tester.scrollUntilVisible(addButton, 100);
      await tester.pumpAndSettle();

      // Verify add annotation button is shown
      expect(addButton, findsOneWidget);
    });

    testWidgets('Tap add annotation shows text input', (tester) async {
      final entryWithoutAnnotation = Entry(
        id: 'entry-2',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo2.jpg',
        sortOrder: 1,
        capturedAt: DateTime(2026, 1, 30, 14, 30),
        createdAt: DateTime(2026, 1, 30, 14, 30),
      );

      final mockNotifier =
          _MockEntriesNotifier(entries: [entryWithoutAnnotation]);
      await tester.pumpWidget(createTestWidget(
        entry: entryWithoutAnnotation,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Scroll to and tap add annotation button
      final addButton = find.byKey(const Key('add_annotation_button'));
      await tester.scrollUntilVisible(addButton, 100);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verify text field appears
      expect(find.byKey(const Key('annotation_text_field')), findsOneWidget);
    });

    testWidgets('Cancel editing discards changes', (tester) async {
      final mockNotifier = _MockEntriesNotifier(entries: allEntries);
      await tester.pumpWidget(createTestWidget(
        entry: photoEntry,
        mockNotifier: mockNotifier,
      ));
      await tester.pumpAndSettle();

      // Scroll to and tap annotation field to activate it
      final annotationField = find.byKey(const Key('annotation_field'));
      await tester.scrollUntilVisible(annotationField, 100);
      await tester.pumpAndSettle();
      await tester.tap(annotationField);
      await tester.pumpAndSettle();

      // Enter new text
      final textField = find.byKey(const Key('annotation_text_field'));
      await tester.enterText(textField, 'Text that will be cancelled');
      await tester.pumpAndSettle();

      // Tap cancel button
      final cancelButton = find.byKey(const Key('annotation_cancel_button'));
      expect(cancelButton, findsOneWidget);
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify updateEntry was NOT called
      expect(mockNotifier.updateEntryCalled, isFalse);

      // Verify original annotation is still displayed
      final annotationFieldAfter = find.byKey(const Key('annotation_field'));
      await tester.ensureVisible(annotationFieldAfter);
      await tester.pumpAndSettle();
      expect(find.text('Initial annotation'), findsOneWidget);
    });
  });
}

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  final List<Entry> entries;
  bool updateEntryCalled = false;
  Entry? lastUpdatedEntry;

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }

  @override
  Future<Entry> updateEntry(Entry entry) async {
    updateEntryCalled = true;
    lastUpdatedEntry = entry;
    final updatedEntries = entries.map((e) {
      return e.id == entry.id ? entry : e;
    }).toList();
    state = AsyncData(updatedEntries);
    return entry;
  }
}
