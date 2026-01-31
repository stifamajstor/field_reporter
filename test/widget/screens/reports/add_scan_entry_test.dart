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
import 'package:field_reporter/services/audio_recorder_service.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/barcode_scanner_service.dart';
import 'package:field_reporter/services/location_service.dart';

void main() {
  group('User can scan QR/barcode and add to report', () {
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
      void Function(Entry)? onEntryAdded,
      MockBarcodeScannerService? scannerService,
    }) {
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
          audioRecorderServiceProvider
              .overrideWithValue(MockAudioRecorderService()),
          cameraServiceProvider.overrideWithValue(MockCameraService()),
          barcodeScannerServiceProvider
              .overrideWithValue(scannerService ?? MockBarcodeScannerService()),
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

      // Verify entry type options appear including Scan
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets(
        'Step 3-4: Select Scan and verify camera opens with scan overlay',
        (tester) async {
      final mockScanner = MockBarcodeScannerService();

      await tester.pumpWidget(createTestWidget(scannerService: mockScanner));
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

      // Step 3: Select Scan option
      final scanOption = find.text('Scan');
      expect(scanOption, findsOneWidget);

      await tester.tap(scanOption);
      // Use pump instead of pumpAndSettle because CircularProgressIndicator animates indefinitely
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Step 4: Verify scanner overlay appears (camera with scan overlay)
      expect(find.byKey(const Key('scan_overlay')), findsOneWidget);
      expect(find.text('Point at QR code or barcode'), findsOneWidget);
    });

    testWidgets('Step 5-6: Point at QR code and verify automatic detection',
        (tester) async {
      final mockScanner = MockBarcodeScannerService(
        scanResult: const ScanResult(
          data: 'https://example.com/product/12345',
          format: BarcodeFormat.qrCode,
        ),
      );

      await tester.pumpWidget(createTestWidget(scannerService: mockScanner));
      await tester.pumpAndSettle();

      // Navigate to scan
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      // Verify scanner is active
      expect(find.byKey(const Key('scan_overlay')), findsOneWidget);

      // Simulate successful scan by triggering the scanner callback
      // The mock scanner will automatically return a result
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Step 7: Verify scanned data is displayed
      expect(find.text('https://example.com/product/12345'), findsOneWidget);
      expect(find.text('QR Code'), findsOneWidget);
    });

    testWidgets('Step 7: Verify scanned data displayed with barcode format',
        (tester) async {
      final mockScanner = MockBarcodeScannerService(
        scanResult: const ScanResult(
          data: '5901234123457',
          format: BarcodeFormat.ean13,
        ),
      );

      await tester.pumpWidget(createTestWidget(scannerService: mockScanner));
      await tester.pumpAndSettle();

      // Navigate to scan
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify barcode data is displayed with format
      expect(find.text('5901234123457'), findsOneWidget);
      expect(find.text('EAN-13'), findsOneWidget);
    });

    testWidgets('Step 8-9: Tap Save and verify scan entry added to report',
        (tester) async {
      Entry? addedEntry;
      final entriesList = <Entry>[];

      final mockScanner = MockBarcodeScannerService(
        scanResult: const ScanResult(
          data: 'https://example.com/product/12345',
          format: BarcodeFormat.qrCode,
        ),
      );

      await tester.pumpWidget(createTestWidget(
        entries: entriesList,
        onEntryAdded: (entry) => addedEntry = entry,
        scannerService: mockScanner,
      ));
      await tester.pumpAndSettle();

      // Navigate to scan
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      // Wait for scan result
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Step 8: Tap Save button
      final saveButton = find.byKey(const Key('scan_save_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Step 9: Verify scan entry added to report
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.scan);
      expect(addedEntry!.content, 'https://example.com/product/12345');
      expect(addedEntry!.reportId, 'report-1');

      // Verify entry card is displayed
      expect(find.byType(EntryCard), findsOneWidget);
    });

    testWidgets('Full flow: Add scan entry from start to finish',
        (tester) async {
      Entry? addedEntry;
      final entriesList = <Entry>[];

      final mockScanner = MockBarcodeScannerService(
        scanResult: const ScanResult(
          data: 'PRODUCT-SKU-789456',
          format: BarcodeFormat.code128,
        ),
      );

      await tester.pumpWidget(createTestWidget(
        entries: entriesList,
        onEntryAdded: (entry) => addedEntry = entry,
        scannerService: mockScanner,
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

      // Step 3: Select Scan from options
      expect(find.text('Scan'), findsOneWidget);
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();

      // Step 4: Verify camera opens with scan overlay
      expect(find.byKey(const Key('scan_overlay')), findsOneWidget);

      // Step 5-6: Point at barcode and verify automatic detection
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Step 7: Verify scanned data displayed
      expect(find.text('PRODUCT-SKU-789456'), findsOneWidget);
      expect(find.text('Code 128'), findsOneWidget);

      // Step 8: Tap Save to add to report
      await tester.tap(find.byKey(const Key('scan_save_button')));
      await tester.pumpAndSettle();

      // Step 9: Verify scan entry added with decoded data
      expect(addedEntry, isNotNull);
      expect(addedEntry!.type, EntryType.scan);
      expect(addedEntry!.content, 'PRODUCT-SKU-789456');
      expect(addedEntry!.reportId, 'report-1');

      // Verify entry card is displayed with scan icon
      expect(find.byType(EntryCard), findsOneWidget);
      final cardFinder = find.descendant(
        of: find.byType(EntryCard),
        matching: find.text('PRODUCT-SKU-789456'),
      );
      expect(cardFinder, findsOneWidget);
    });

    testWidgets('Cancel scan returns to report editor', (tester) async {
      final mockScanner = MockBarcodeScannerService();

      await tester.pumpWidget(createTestWidget(scannerService: mockScanner));
      await tester.pumpAndSettle();

      // Navigate to scan
      await tester.scrollUntilVisible(
        find.text('Add Entry'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan'));
      // Use pump instead of pumpAndSettle because CircularProgressIndicator animates indefinitely
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify scanner is open
      expect(find.byKey(const Key('scan_overlay')), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify back to report editor
      expect(find.byKey(const Key('scan_overlay')), findsNothing);
      expect(find.text('Report Editor'), findsOneWidget);
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

/// Mock AudioRecorderService for testing
class MockAudioRecorderService implements AudioRecorderService {
  @override
  Future<void> startRecording() async {}

  @override
  Future<AudioRecordingResult?> stopRecording() async => null;

  @override
  Future<void> startPlayback(String path) async {}

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> dispose() async {}
}

/// Mock CameraService for testing
class MockCameraService implements CameraService {
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
  Future<String?> capturePhoto({
    double? compassHeading,
    LocationPosition? location,
    bool? isLocationStale,
  }) async => null;

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {}

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

/// Mock BarcodeScannerService for testing
class MockBarcodeScannerService implements BarcodeScannerService {
  final ScanResult? scanResult;

  MockBarcodeScannerService({this.scanResult});

  @override
  Future<ScanResult?> scan() async {
    // Simulate scanning delay
    await Future.delayed(const Duration(milliseconds: 100));
    return scanResult;
  }

  @override
  Future<void> dispose() async {}
}
