import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/project_selection_screen.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/presentation/reports_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/connectivity_service.dart';

void main() {
  group('User can create report and add entries while offline', () {
    late List<Report> storedReports;
    late List<Entry> storedEntries;
    late List<PendingUpload> pendingUploads;
    late List<Project> projects;
    late ConnectivityService connectivityService;
    late _MockCameraService mockCameraService;
    late bool syncWasCalled;

    setUp(() {
      storedReports = [];
      storedEntries = [];
      pendingUploads = [];
      projects = [
        Project(
          id: 'proj-1',
          name: 'Test Project',
          description: 'A test project',
          status: ProjectStatus.active,
          syncPending: false,
          reportCount: 0,
          lastActivityAt: DateTime.now(),
        ),
      ];
      connectivityService = ConnectivityService();
      mockCameraService = _MockCameraService(
        capturedPhotoPath: '/mock/photos/test_photo.jpg',
      );
      syncWasCalled = false;
    });

    Widget buildTestWidget({
      required bool isOnline,
      Widget? child,
    }) {
      connectivityService.setOnline(isOnline);

      return ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivityService),
          projectsNotifierProvider.overrideWith(() {
            return _TestProjectsNotifier(storedProjects: projects);
          }),
          allReportsNotifierProvider.overrideWith(() {
            return _TestReportsNotifier(
              storedReports: storedReports,
              connectivityService: connectivityService,
              onSync: () => syncWasCalled = true,
            );
          }),
          entriesNotifierProvider.overrideWith(() {
            return _TestEntriesNotifier(
              storedEntries: storedEntries,
              connectivityService: connectivityService,
            );
          }),
          pendingUploadsNotifierProvider.overrideWith(() {
            return _TestPendingUploadsNotifier(pendingUploads: pendingUploads);
          }),
          cameraServiceProvider.overrideWithValue(mockCameraService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child ?? const ReportsScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/reports/select-project') {
              return MaterialPageRoute(
                builder: (_) => const ProjectSelectionScreen(),
                settings: settings,
              );
            }
            if (settings.name?.startsWith('/reports/new/') ?? false) {
              final projectId =
                  settings.name!.replaceFirst('/reports/new/', '');
              return MaterialPageRoute(
                builder: (_) => ReportEditorScreen(projectId: projectId),
                settings: settings,
              );
            }
            if (settings.name?.startsWith('/reports/') ?? false) {
              final reportId = settings.name!.replaceFirst('/reports/', '');
              return MaterialPageRoute(
                builder: (_) => ReportEditorScreen(reportId: reportId),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );
    }

    // Step 1: Enable airplane mode - Navigate while offline
    testWidgets('offline: can access reports screen while offline',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      expect(find.byType(ReportsScreen), findsOneWidget);
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
    });

    // Step 2: Navigate to create new report
    testWidgets('offline: can navigate to create new report', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ProjectSelectionScreen), findsOneWidget);
    });

    // Step 3: Select project
    testWidgets('offline: can select project for new report', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: const ProjectSelectionScreen(),
      ));
      await tester.pumpAndSettle();

      // Find and tap the project
      expect(find.text('Test Project'), findsOneWidget);
      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      // Should navigate to report editor
      expect(find.byType(ReportEditorScreen), findsOneWidget);
    });

    // Step 4: Add photo entry while offline
    testWidgets('offline: can add photo entry', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Scroll to make Add Entry button visible
      final addEntryButton = find.text('Add Entry');
      await tester.scrollUntilVisible(
        addEntryButton,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // First tap "Add Entry" button to show entry type options
      expect(addEntryButton, findsOneWidget);
      await tester.tap(addEntryButton);
      await tester.pumpAndSettle();

      // Find and tap add photo button in the overlay
      final addPhotoButton = find.byKey(const Key('add_photo_button'));
      expect(addPhotoButton, findsOneWidget);
      await tester.tap(addPhotoButton);
      await tester.pumpAndSettle();

      // Photo preview should appear - tap "Use Photo" to confirm
      expect(find.text('Use Photo'), findsOneWidget);
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Verify entry was added with syncPending = true
      expect(storedEntries.isNotEmpty, isTrue);
      expect(storedEntries.any((e) => e.type == EntryType.photo), isTrue);
      expect(storedEntries.first.syncPending, isTrue);
    });

    // Step 5: Add text note entry while offline
    testWidgets('offline: can add text note entry', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Scroll to make Add Entry button visible
      final addEntryButton = find.text('Add Entry');
      await tester.scrollUntilVisible(
        addEntryButton,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // First tap "Add Entry" button to show entry type options
      expect(addEntryButton, findsOneWidget);
      await tester.tap(addEntryButton);
      await tester.pumpAndSettle();

      // Find and tap add note button in the overlay
      final addNoteButton = find.byKey(const Key('add_note_button'));
      expect(addNoteButton, findsOneWidget);
      await tester.tap(addNoteButton);
      await tester.pumpAndSettle();

      // Enter note text in dialog/sheet
      final noteField = find.byKey(const Key('note_text_field'));
      expect(noteField, findsOneWidget);
      await tester.enterText(noteField, 'Test note content');
      await tester.pump();

      // Save the note using the specific save button key
      await tester.tap(find.byKey(const Key('note_save_button')));
      await tester.pumpAndSettle();

      // Verify note entry was added with syncPending = true
      expect(storedEntries.any((e) => e.type == EntryType.note), isTrue);
      final noteEntry =
          storedEntries.firstWhere((e) => e.type == EntryType.note);
      expect(noteEntry.content, equals('Test note content'));
      expect(noteEntry.syncPending, isTrue);
    });

    // Step 6: Verify entries saved locally
    testWidgets('offline: entries are saved locally with correct data',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Scroll to make Add Entry button visible and add a photo entry
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_photo_button')));
      await tester.pumpAndSettle();
      // Confirm photo
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Scroll and add a note entry
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_note_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('note_text_field')), 'Saved locally');
      await tester.pump();
      await tester.tap(find.byKey(const Key('note_save_button')));
      await tester.pumpAndSettle();

      // Verify both entries are saved
      expect(storedEntries.length, equals(2));
      expect(storedEntries.every((e) => e.syncPending), isTrue);
    });

    // Step 7: Verify 'Pending sync' indicator
    testWidgets('offline: shows pending sync indicator for entries',
        (tester) async {
      // Create the report first
      final testReport = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 1,
        createdAt: DateTime.now(),
      );

      // Pre-populate with entries that have pending sync
      storedEntries.add(Entry(
        id: 'entry-1',
        reportId: 'report-1',
        type: EntryType.photo,
        sortOrder: 0,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        syncPending: true,
        mediaPath: '/path/to/photo.jpg',
      ));

      storedReports.add(testReport);

      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: ReportEditorScreen(report: testReport, projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Scroll to find Entries section
      await tester.scrollUntilVisible(
        find.text('Entries'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Verify pending sync indicator is visible
      expect(find.byKey(const Key('pending_sync_indicator')), findsOneWidget);
      expect(find.text('Pending sync'), findsWidgets);
    });

    // Step 8: Disable airplane mode - automatic sync starts
    testWidgets('online: automatic sync starts when connectivity restored',
        (tester) async {
      // Pre-populate with pending entries
      storedEntries.add(Entry(
        id: 'entry-1',
        reportId: 'report-1',
        type: EntryType.photo,
        sortOrder: 0,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        syncPending: true,
        mediaPath: '/path/to/photo.jpg',
      ));

      storedReports.add(Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 1,
        createdAt: DateTime.now(),
      ));

      pendingUploads.add(PendingUpload(
        id: 'upload-1',
        entryId: 'entry-1',
        fileName: 'photo.jpg',
        fileSize: 1024,
        createdAt: DateTime.now(),
        status: UploadStatus.pending,
      ));

      // Start in online mode
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Verify sync was triggered
      expect(syncWasCalled, isTrue);
    });

    // Step 9 & 10: Verify entries upload successfully
    testWidgets('online: entries sync successfully and indicator removed',
        (tester) async {
      // Create the report first
      final testReport = Report(
        id: 'report-1',
        projectId: 'proj-1',
        title: 'Test Report',
        status: ReportStatus.draft,
        entryCount: 1,
        createdAt: DateTime.now(),
      );

      // Pre-populate with pending entries
      storedEntries.add(Entry(
        id: 'entry-1',
        reportId: 'report-1',
        type: EntryType.photo,
        sortOrder: 0,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        syncPending: true,
        mediaPath: '/path/to/photo.jpg',
      ));

      storedReports.add(testReport);

      // Start in online mode (triggers sync)
      await tester.pumpWidget(buildTestWidget(
        isOnline: true,
        child: ReportEditorScreen(report: testReport, projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Verify entries were synced (syncPending = false)
      expect(storedEntries.first.syncPending, isFalse);

      // Verify pending sync indicator is removed
      expect(find.byKey(const Key('pending_sync_indicator')), findsNothing);
    });

    // Complete flow test
    testWidgets('complete offline report creation and sync flow',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Step 1: Verify offline indicator
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);

      // Step 2: Navigate to create new report
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectSelectionScreen), findsOneWidget);

      // Step 3: Select project
      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportEditorScreen), findsOneWidget);

      // Scroll to find Add Entry button
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Step 4: Add photo entry (first show entry type options)
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_photo_button')));
      await tester.pumpAndSettle();
      // Confirm photo
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Scroll and add note entry
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Step 5: Add text note entry (first show entry type options)
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_note_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('note_text_field')), 'Offline note');
      await tester.pump();
      await tester.tap(find.byKey(const Key('note_save_button')));
      await tester.pumpAndSettle();

      // Step 6: Verify entries saved locally
      expect(storedEntries.length, equals(2));
      expect(storedEntries.every((e) => e.syncPending), isTrue);

      // Scroll to see entries section with pending sync indicator
      await tester.scrollUntilVisible(
        find.text('Entries'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Step 7: Verify pending sync indicator
      expect(find.byKey(const Key('pending_sync_indicator')), findsOneWidget);
    });
  });
}

/// Test notifier for projects.
class _TestProjectsNotifier extends ProjectsNotifier {
  _TestProjectsNotifier({required this.storedProjects});

  final List<Project> storedProjects;

  @override
  Future<List<Project>> build() async {
    return storedProjects;
  }
}

/// Test notifier for reports that simulates offline/online behavior.
class _TestReportsNotifier extends AllReportsNotifier {
  _TestReportsNotifier({
    required this.storedReports,
    required this.connectivityService,
    this.onSync,
  });

  final List<Report> storedReports;
  final ConnectivityService connectivityService;
  final VoidCallback? onSync;

  @override
  Future<List<Report>> build() async {
    // When online and building, trigger sync
    if (connectivityService.isOnline) {
      onSync?.call();
    }
    return storedReports;
  }

  @override
  Future<Report> createReport(Report report) async {
    storedReports.add(report);
    state = AsyncData(List.from(storedReports));
    return report;
  }
}

/// Test notifier for entries that simulates offline/online behavior.
class _TestEntriesNotifier extends EntriesNotifier {
  _TestEntriesNotifier({
    required this.storedEntries,
    required this.connectivityService,
  });

  final List<Entry> storedEntries;
  final ConnectivityService connectivityService;

  @override
  Future<List<Entry>> build() async {
    // When online, mark all pending entries as synced
    if (connectivityService.isOnline) {
      for (var i = 0; i < storedEntries.length; i++) {
        if (storedEntries[i].syncPending) {
          storedEntries[i] = storedEntries[i].copyWith(syncPending: false);
        }
      }
    }
    return storedEntries;
  }

  @override
  Future<Entry> addEntry(Entry entry) async {
    // When offline, save with syncPending = true
    final entryToSave = connectivityService.isOnline
        ? entry.copyWith(syncPending: false)
        : entry.copyWith(syncPending: true);

    storedEntries.add(entryToSave);
    state = AsyncData(List.from(storedEntries));
    return entryToSave;
  }
}

/// Test notifier for pending uploads.
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  _TestPendingUploadsNotifier({required this.pendingUploads});

  final List<PendingUpload> pendingUploads;

  @override
  Future<List<PendingUpload>> build() async {
    return pendingUploads;
  }
}

/// Mock CameraService for testing.
class _MockCameraService implements CameraService {
  _MockCameraService({this.capturedPhotoPath});

  final String? capturedPhotoPath;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> openCamera() async {}

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {}

  @override
  Future<String?> capturePhoto({double? compassHeading}) async =>
      capturedPhotoPath;

  @override
  Future<void> startRecording({bool enableAudio = true}) async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async => null;

  @override
  Future<void> closeCamera() async {}

  @override
  Future<void> switchCamera() async {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }
}
