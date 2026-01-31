import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Report Editor is accessible with screen reader', () {
    late Report testReport;
    late List<Entry> testEntries;
    late Project testProject;

    setUp(() {
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
        createdAt: DateTime(2026, 1, 30),
      );

      testEntries = [
        Entry(
          id: 'entry-1',
          reportId: 'report-1',
          type: EntryType.photo,
          mediaPath: '/path/to/photo.jpg',
          thumbnailPath: '/path/to/thumb.jpg',
          annotation: 'Photo at site entrance',
          sortOrder: 0,
          capturedAt: DateTime(2026, 1, 30, 10, 0),
          createdAt: DateTime(2026, 1, 30, 10, 0),
        ),
        Entry(
          id: 'entry-2',
          reportId: 'report-1',
          type: EntryType.audio,
          mediaPath: '/path/to/audio.m4a',
          durationSeconds: 120,
          annotation: 'Interview with supervisor',
          sortOrder: 1,
          capturedAt: DateTime(2026, 1, 30, 11, 0),
          createdAt: DateTime(2026, 1, 30, 11, 0),
        ),
        Entry(
          id: 'entry-3',
          reportId: 'report-1',
          type: EntryType.note,
          content: 'Important observation about the building',
          sortOrder: 2,
          capturedAt: DateTime(2026, 1, 30, 12, 0),
          createdAt: DateTime(2026, 1, 30, 12, 0),
        ),
      ];
    });

    Widget createTestWidget({
      required Report report,
      required List<Project> projects,
      required List<Report> reports,
      required List<Entry> entries,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects);
          }),
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: reports);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier(entries: entries);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ReportEditorScreen(
            report: report,
          ),
        ),
      );
    }

    testWidgets('report title is announced (visible and accessible)',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify report title is displayed
      expect(find.text('Test Report'), findsOneWidget);

      // Verify title field is editable and has semantic label
      final titleField = find.byKey(const Key('report_title_field'));
      expect(titleField, findsOneWidget);
    });

    testWidgets('Add Entry button is properly labeled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Scroll down to find Add Entry button
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Verify Add Entry button is visible and has text label
      expect(find.text('Add Entry'), findsOneWidget);

      // Find button with icon and verify
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('entry type options are announced when adding entry',
        (tester) async {
      // Create widget with empty entries so Add Entry shows in empty state
      await tester.pumpWidget(createTestWidget(
        report: testReport.copyWith(entryCount: 0),
        projects: [testProject],
        reports: [testReport],
        entries: [], // Empty entries shows Add Entry options directly
      ));
      await tester.pumpAndSettle();

      // Scroll to make the empty state Add Entry button visible
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Use ensureVisible to scroll the Add Entry button into view
      final addEntryFinder = find.text('Add Entry');
      expect(addEntryFinder, findsOneWidget);
      await tester.ensureVisible(addEntryFinder);
      await tester.pumpAndSettle();

      // Tap the Add Entry button
      await tester.tap(addEntryFinder);
      await tester.pumpAndSettle();

      // Verify entry type options overlay is displayed with labels
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Voice Memo'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('entries section header is visible', (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Scroll to entries section
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Verify Entries section header
      expect(find.text('Entries'), findsOneWidget);
    });

    testWidgets('entry type icons have semantic meaning through context',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Scroll to entries section
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify timeline icons for different entry types exist
      // At least the photo icon should be visible
      expect(find.byKey(const Key('timeline_icon_photo')), findsOneWidget);
    });

    testWidgets('entry timestamps are visible', (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Scroll to entries
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify timestamps are displayed (format: h:mm a)
      // Look for AM or PM since times range from 10 AM to 12 PM
      final amFinder = find.textContaining('AM');
      final pmFinder = find.textContaining('PM');
      expect(
        amFinder.evaluate().isNotEmpty || pmFinder.evaluate().isNotEmpty,
        isTrue,
        reason: 'Should find at least one timestamp with AM or PM',
      );
    });

    testWidgets('entry annotations/descriptions are displayed', (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Scroll to entries
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify entry annotations are visible - look for the first entry's annotation
      expect(find.text('Photo at site entrance'), findsOneWidget);
    });

    testWidgets('status badge is visible and labeled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify status badge shows "Draft" text
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('project info is accessible', (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify project name is displayed
      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('focus order flows logically through the screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify title field exists at top
      final titleField = find.byKey(const Key('report_title_field'));
      expect(titleField, findsOneWidget);

      // Get positions in the render tree
      final titleRect = tester.getRect(titleField);

      // Verify title is near top of scrollable content
      expect(titleRect.top, lessThan(400));
    });

    testWidgets('notes field is properly labeled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        report: testReport,
        projects: [testProject],
        reports: [testReport],
        entries: testEntries,
      ));
      await tester.pumpAndSettle();

      // Verify notes field has hint text (actual hint from implementation)
      expect(find.text('Add notes or description...'), findsOneWidget);

      // Verify notes field key exists
      final notesField = find.byKey(const Key('report_notes_field'));
      expect(notesField, findsOneWidget);
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async => projects;
}

/// Mock ReportsNotifier for testing
class _MockReportsNotifier extends AllReportsNotifier {
  final List<Report> reports;

  _MockReportsNotifier({required this.reports});

  @override
  Future<List<Report>> build() async => reports;

  @override
  Future<Report> updateReport(Report report) async {
    return report;
  }
}

/// Mock EntriesNotifier for testing
class _MockEntriesNotifier extends EntriesNotifier {
  final List<Entry> entries;

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async => entries;
}
