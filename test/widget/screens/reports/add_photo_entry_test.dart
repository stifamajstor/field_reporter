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
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/location_service.dart';

void main() {
  group('User can add photo entry to report', () {
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
      MockCameraService? cameraService,
      void Function(Entry)? onEntryAdded,
    }) {
      final mockCamera = cameraService ?? MockCameraService();
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
          cameraServiceProvider.overrideWithValue(mockCamera),
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

      // Verify entry type options appear
      expect(find.text('Photo'), findsOneWidget);
    });

    testWidgets('Step 3: Select Photo from options', (tester) async {
      final mockCamera = MockCameraService();

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
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

      // Select Photo option
      final photoOption = find.text('Photo');
      expect(photoOption, findsOneWidget);

      await tester.tap(photoOption);
      await tester.pumpAndSettle();

      // Step 4: Verify camera opens (via mock)
      expect(mockCamera.openCameraCalled, isTrue);
    });

    testWidgets('Step 5-7: Capture photo, preview, and confirm',
        (tester) async {
      final mockCamera = MockCameraService(
        capturedPhotoPath: '/mock/photos/test_photo.jpg',
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
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

      // Select Photo option
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Camera was opened and photo captured (mocked)
      expect(mockCamera.capturePhotoCalled, isTrue);

      // Photo preview should appear with Use Photo button
      expect(find.text('Use Photo'), findsOneWidget);
    });

    testWidgets(
        'Step 8-9: Verify photo entry added with thumbnail and timestamp',
        (tester) async {
      final mockCamera = MockCameraService(
        capturedPhotoPath: '/mock/photos/test_photo.jpg',
      );

      Entry? addedEntry;
      final entriesList = <Entry>[];

      await tester.pumpWidget(createTestWidget(
        cameraService: mockCamera,
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

      // Select Photo option
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Confirm photo
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Verify entry was added
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.photo);
      expect(addedEntry!.mediaPath, '/mock/photos/test_photo.jpg');
      expect(addedEntry!.reportId, 'report-1');

      // Verify entry card is displayed
      expect(find.byType(EntryCard), findsOneWidget);

      // Verify timestamp is displayed (time format like "10:30 AM")
      expect(find.textContaining(RegExp(r'\d{1,2}:\d{2}')), findsWidgets);
    });

    testWidgets('Full flow: Add photo entry from start to finish',
        (tester) async {
      final mockCamera = MockCameraService(
        capturedPhotoPath: '/mock/photos/test_photo.jpg',
      );

      Entry? addedEntry;
      final entriesList = <Entry>[];

      await tester.pumpWidget(createTestWidget(
        cameraService: mockCamera,
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

      // Step 3: Select Photo from options
      expect(find.text('Photo'), findsOneWidget);
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Step 4: Verify camera opens
      expect(mockCamera.openCameraCalled, isTrue);

      // Step 5: Capture photo (automatic in mock)
      expect(mockCamera.capturePhotoCalled, isTrue);

      // Step 6: Verify photo preview appears
      expect(find.text('Use Photo'), findsOneWidget);

      // Step 7: Tap Use Photo to confirm
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Step 8: Verify photo entry added to report
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.photo);
      expect(addedEntry!.reportId, 'report-1');

      // Step 9: Verify entry shows thumbnail and timestamp
      // The entry should now be in the list
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

/// Mock CameraService for testing
class MockCameraService implements CameraService {
  final String? capturedPhotoPath;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;

  bool openCameraCalled = false;
  bool capturePhotoCalled = false;

  MockCameraService({this.capturedPhotoPath});

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> openCamera() async {
    openCameraCalled = true;
  }

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {}

  @override
  Future<String?> capturePhoto({
    double? compassHeading,
    LocationPosition? location,
    bool? isLocationStale,
  }) async {
    capturePhotoCalled = true;
    return capturedPhotoPath;
  }

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
