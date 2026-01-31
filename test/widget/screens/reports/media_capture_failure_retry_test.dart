import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/features/entries/providers/entries_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/services/camera_service.dart';

void main() {
  group('Media capture failure shows retry option', () {
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
            return _MockEntriesNotifier(entries: entriesList);
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

    testWidgets(
        'Step 1-2: Open Report and attempt to add photo with camera failure',
        (tester) async {
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.cameraFailure,
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Verify Report Editor is open
      expect(find.text('Report Editor'), findsOneWidget);

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

      // Select Photo option (this triggers camera failure)
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify camera was called
      expect(mockCamera.openCameraCalled, isTrue);
    });

    testWidgets('Step 3: Verify error message displayed for camera failure',
        (tester) async {
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.cameraFailure,
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Navigate to photo capture
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Camera Error'), findsOneWidget);
      expect(
        find.textContaining('Unable to access camera'),
        findsOneWidget,
      );
    });

    testWidgets('Step 3: Verify error message displayed for permission denied',
        (tester) async {
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.permissionDenied,
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Navigate to photo capture
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify permission error message is displayed
      expect(find.text('Permission Required'), findsOneWidget);
      expect(
        find.textContaining('Camera permission is required'),
        findsOneWidget,
      );
    });

    testWidgets('Step 4: Verify Retry option for camera failure',
        (tester) async {
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.cameraFailure,
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Navigate to photo capture
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify Retry button is displayed
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Step 4: Verify Check Permissions option for permission denied',
        (tester) async {
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.permissionDenied,
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Navigate to photo capture
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify Check Permissions button is displayed
      expect(find.text('Check Permissions'), findsOneWidget);
    });

    testWidgets('Step 5-6: Grant permissions and retry succeeds',
        (tester) async {
      // Camera that fails first, then succeeds on retry
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.cameraFailure,
        succeedOnRetry: true,
        capturedPhotoPath: '/mock/photos/test_photo.jpg',
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Navigate to photo capture
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.text('Camera Error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify camera was retried
      expect(mockCamera.retryCount, 1);

      // Verify capture succeeded - photo preview should appear
      expect(find.text('Use Photo'), findsOneWidget);
    });

    testWidgets('Full flow: Camera failure with retry and successful capture',
        (tester) async {
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.cameraFailure,
        succeedOnRetry: true,
        capturedPhotoPath: '/mock/photos/test_photo.jpg',
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Step 1: Open Report Editor
      expect(find.text('Report Editor'), findsOneWidget);

      // Step 2: Attempt to add photo
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Step 3: Verify error message displayed
      expect(find.text('Camera Error'), findsOneWidget);
      expect(find.textContaining('Unable to access camera'), findsOneWidget);

      // Step 4: Verify Retry option
      expect(find.text('Retry'), findsOneWidget);

      // Step 5: Tap Retry (simulating grant permissions)
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Step 6: Verify capture succeeds
      expect(find.text('Use Photo'), findsOneWidget);
      expect(mockCamera.capturePhotoCalled, isTrue);
    });

    testWidgets('Dismiss error dialog shows entry type options again',
        (tester) async {
      final mockCamera = MockCameraService(
        shouldFailWithError: CameraError.cameraFailure,
      );

      await tester.pumpWidget(createTestWidget(cameraService: mockCamera));
      await tester.pumpAndSettle();

      // Navigate to photo capture
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify error dialog
      expect(find.text('Camera Error'), findsOneWidget);

      // Find and tap Cancel/Dismiss button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Error dialog should be dismissed
      expect(find.text('Camera Error'), findsNothing);
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

  _MockEntriesNotifier({required this.entries});

  @override
  Future<List<Entry>> build() async {
    return entries;
  }

  @override
  Future<Entry> addEntry(Entry entry) async {
    entries.add(entry);
    state = AsyncData(List<Entry>.from(entries));
    return entry;
  }
}

/// Mock CameraService for testing with error simulation
class MockCameraService implements CameraService {
  final String? capturedPhotoPath;
  final CameraError? shouldFailWithError;
  final bool succeedOnRetry;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;

  bool openCameraCalled = false;
  bool capturePhotoCalled = false;
  int _attemptCount = 0;

  /// Number of retry attempts (after the first failure)
  int get retryCount => _attemptCount > 0 ? _attemptCount - 1 : 0;

  MockCameraService({
    this.capturedPhotoPath,
    this.shouldFailWithError,
    this.succeedOnRetry = false,
  });

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
    _attemptCount++;

    // If should fail and this is first attempt (or no retry configured)
    if (shouldFailWithError != null &&
        (!succeedOnRetry || _attemptCount == 1)) {
      throw CameraServiceException(shouldFailWithError!);
    }
  }

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {
    _attemptCount++;
    if (shouldFailWithError != null &&
        (!succeedOnRetry || _attemptCount == 1)) {
      throw CameraServiceException(shouldFailWithError!);
    }
  }

  @override
  Future<String?> capturePhoto({double? compassHeading}) async {
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
