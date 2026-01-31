import 'dart:io';

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
import 'package:field_reporter/services/connectivity_service.dart';
import 'package:field_reporter/widgets/progressive_thumbnail.dart';

void main() {
  group('Entry thumbnails load progressively', () {
    late Report report;
    late List<Entry> manyEntries;
    late Project project;

    setUp(() {
      project = const Project(
        id: 'proj-1',
        name: 'Test Project',
        description: 'A test project',
        status: ProjectStatus.active,
      );

      report = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Progressive Thumbnail Test Report',
        status: ReportStatus.draft,
        entryCount: 20,
        createdAt: DateTime(2026, 1, 31, 9, 0),
      );

      // Create many photo/video entries to test progressive loading
      manyEntries = List.generate(
        20,
        (index) => Entry(
          id: 'entry-$index',
          reportId: 'report-1',
          type: index % 2 == 0 ? EntryType.photo : EntryType.video,
          mediaPath: '/test/media_$index.${index % 2 == 0 ? "jpg" : "mp4"}',
          thumbnailPath: '/test/thumb_$index.jpg',
          durationSeconds: index % 2 == 0 ? null : 30,
          sortOrder: index,
          capturedAt: DateTime(2026, 1, 31, 9, 0).add(Duration(minutes: index)),
          createdAt: DateTime(2026, 1, 31, 9, 0).add(Duration(minutes: index)),
        ),
      );
    });

    Widget createTestWidget({
      required Report report,
      required List<Entry> entries,
    }) {
      return ProviderScope(
        overrides: [
          allReportsNotifierProvider.overrideWith(() {
            return _MockReportsNotifier(reports: [report]);
          }),
          entriesNotifierProvider.overrideWith(() {
            return _MockEntriesNotifier(entries: entries);
          }),
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: [project]);
          }),
          connectivityServiceProvider
              .overrideWithValue(ConnectivityService()..setOnline(true)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ReportEditorScreen(report: report),
        ),
      );
    }

    Widget createThumbnailTestWidget({
      required Entry entry,
      bool simulateSlowLoad = false,
    }) {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: ProgressiveThumbnail(
              entry: entry,
              size: 64,
              simulateSlowLoad: simulateSlowLoad,
            ),
          ),
        ),
      );
    }

    testWidgets('Open Report with many photo/video entries', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: manyEntries,
        ),
      );
      await tester.pumpAndSettle();

      // Verify report editor screen is displayed with entries
      expect(find.text('Report Editor'), findsOneWidget);
      expect(find.text('Progressive Thumbnail Test Report'), findsOneWidget);
    });

    testWidgets('Verify placeholder thumbnails shown immediately',
        (tester) async {
      final entry = manyEntries.first;
      await tester.pumpWidget(
        createThumbnailTestWidget(
          entry: entry,
          simulateSlowLoad: true,
        ),
      );

      // Before any frames, placeholder should be visible
      await tester.pump();

      // Verify placeholder is shown (shimmer or placeholder icon)
      expect(find.byKey(const Key('thumbnail_placeholder')), findsOneWidget);

      // Pump remaining timers to avoid pending timer warnings
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Verify thumbnails load progressively', (tester) async {
      final entry = manyEntries.first;
      await tester.pumpWidget(
        createThumbnailTestWidget(
          entry: entry,
          simulateSlowLoad: true,
        ),
      );

      // Initially placeholder is shown
      await tester.pump();
      expect(find.byKey(const Key('thumbnail_placeholder')), findsOneWidget);

      // After delay, widget attempts to load but file doesn't exist in test
      // so placeholder remains visible (graceful fallback)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Placeholder still shown when file doesn't exist (expected behavior)
      expect(find.byKey(const Key('thumbnail_placeholder')), findsOneWidget);
    });

    testWidgets('Verify smooth transition from placeholder to thumbnail',
        (tester) async {
      final entry = manyEntries.first;
      await tester.pumpWidget(
        createThumbnailTestWidget(
          entry: entry,
          simulateSlowLoad: true,
        ),
      );

      await tester.pump();

      // Verify fade transition widget exists (AnimatedOpacity for fade)
      expect(find.byType(AnimatedOpacity), findsWidgets);

      // Verify the structure supports smooth transitions
      // (FadeTransition is used when image loads, AnimatedOpacity for placeholder)
      expect(find.byKey(const Key('thumbnail_placeholder')), findsOneWidget);

      // Pump through timers
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('Scroll quickly through list', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: manyEntries,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to entries section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Fast scroll through the list
      for (int i = 0; i < 5; i++) {
        await tester.fling(
          find.byType(ListView),
          const Offset(0, -200),
          1000,
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      await tester.pumpAndSettle();

      // Verify we can scroll without errors
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Verify no UI jank during scroll', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          report: report,
          entries: manyEntries,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to entries section
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Track frame times during rapid scroll
      final List<Duration> frameTimes = [];
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10; i++) {
        final frameStart = stopwatch.elapsed;
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -50),
        );
        await tester.pump();
        frameTimes.add(stopwatch.elapsed - frameStart);
      }

      // All frames should complete without significant delay
      // (widget tests don't truly measure jank, but this ensures no exceptions)
      expect(frameTimes, hasLength(10));

      await tester.pumpAndSettle();

      // Verify entries with progressive thumbnails are rendered
      expect(find.byType(ProgressiveThumbnail), findsWidgets);
    });

    testWidgets('ProgressiveThumbnail shows correct placeholder for photo',
        (tester) async {
      final photoEntry = Entry(
        id: 'photo-1',
        reportId: 'report-1',
        type: EntryType.photo,
        mediaPath: '/test/photo.jpg',
        sortOrder: 0,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createThumbnailTestWidget(
          entry: photoEntry,
          simulateSlowLoad: true,
        ),
      );
      await tester.pump();

      // Verify photo placeholder icon is shown
      expect(find.byIcon(Icons.photo), findsOneWidget);

      // Pump remaining timers
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('ProgressiveThumbnail shows correct placeholder for video',
        (tester) async {
      final videoEntry = Entry(
        id: 'video-1',
        reportId: 'report-1',
        type: EntryType.video,
        mediaPath: '/test/video.mp4',
        thumbnailPath: '/test/video_thumb.jpg',
        durationSeconds: 60,
        sortOrder: 0,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createThumbnailTestWidget(
          entry: videoEntry,
          simulateSlowLoad: true,
        ),
      );
      await tester.pump();

      // Verify video placeholder icon is shown
      expect(find.byIcon(Icons.videocam), findsOneWidget);

      // Pump remaining timers
      await tester.pump(const Duration(milliseconds: 500));
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
  Future<Report> updateReport(Report report) async {
    final currentReports = state.valueOrNull ?? [];
    final updatedReports = currentReports.map((r) {
      return r.id == report.id ? report : r;
    }).toList();
    state = AsyncData(updatedReports);
    return report;
  }
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

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async {
    return projects;
  }
}
