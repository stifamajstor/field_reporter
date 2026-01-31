import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/entries/domain/entry.dart';
import 'package:field_reporter/services/audio_recorder_service.dart';
import 'package:field_reporter/services/barcode_scanner_service.dart';
import 'package:field_reporter/services/camera_service.dart';
import 'package:field_reporter/services/connectivity_service.dart';
import 'package:field_reporter/services/offline_capture_service.dart';

void main() {
  group('OfflineCaptureService', () {
    late OfflineCaptureService offlineCaptureService;
    late ConnectivityService connectivityService;
    late _MockCameraService mockCameraService;
    late _MockAudioRecorderService mockAudioRecorderService;
    late _MockBarcodeScannerService mockBarcodeScannerService;
    late _MockLocalStorageService mockLocalStorageService;

    setUp(() {
      connectivityService = ConnectivityService();
      mockCameraService = _MockCameraService();
      mockAudioRecorderService = _MockAudioRecorderService();
      mockBarcodeScannerService = _MockBarcodeScannerService();
      mockLocalStorageService = _MockLocalStorageService();

      offlineCaptureService = OfflineCaptureService(
        connectivityService: connectivityService,
        cameraService: mockCameraService,
        audioRecorderService: mockAudioRecorderService,
        barcodeScannerService: mockBarcodeScannerService,
        localStorageService: mockLocalStorageService,
      );
    });

    group('offline mode (airplane mode)', () {
      setUp(() {
        // Enable airplane mode - device is offline
        connectivityService.setOnline(false);
      });

      test('captures photo and saves locally when offline', () async {
        // Arrange
        mockCameraService.setCapturedPhotoPath('/mock/photos/photo_001.jpg');

        // Act
        final entry = await offlineCaptureService.capturePhoto(
          reportId: 'report-1',
        );

        // Assert
        expect(entry, isNotNull);
        expect(entry!.type, equals(EntryType.photo));
        expect(entry.mediaPath, equals('/mock/photos/photo_001.jpg'));
        expect(entry.syncPending, isTrue);
        expect(mockLocalStorageService.savedEntries.length, equals(1));
        expect(mockLocalStorageService.savedEntries.first.syncPending, isTrue);
      });

      test('records video and saves locally when offline', () async {
        // Arrange
        mockCameraService.setVideoRecordingResult(
          const VideoRecordingResult(
            path: '/mock/videos/video_001.mp4',
            durationSeconds: 30,
            thumbnailPath: '/mock/thumbnails/video_001_thumb.jpg',
          ),
        );

        // Act
        await offlineCaptureService.startVideoRecording();
        final entry = await offlineCaptureService.stopVideoRecording(
          reportId: 'report-1',
        );

        // Assert
        expect(entry, isNotNull);
        expect(entry!.type, equals(EntryType.video));
        expect(entry.mediaPath, equals('/mock/videos/video_001.mp4'));
        expect(entry.durationSeconds, equals(30));
        expect(entry.thumbnailPath,
            equals('/mock/thumbnails/video_001_thumb.jpg'));
        expect(entry.syncPending, isTrue);
        expect(mockLocalStorageService.savedEntries.length, equals(1));
        expect(mockLocalStorageService.savedEntries.first.syncPending, isTrue);
      });

      test('records voice memo and saves locally when offline', () async {
        // Arrange
        mockAudioRecorderService.setAudioRecordingResult(
          const AudioRecordingResult(
            path: '/mock/audio/memo_001.m4a',
            durationSeconds: 15,
          ),
        );

        // Act
        await offlineCaptureService.startAudioRecording();
        final entry = await offlineCaptureService.stopAudioRecording(
          reportId: 'report-1',
        );

        // Assert
        expect(entry, isNotNull);
        expect(entry!.type, equals(EntryType.audio));
        expect(entry.mediaPath, equals('/mock/audio/memo_001.m4a'));
        expect(entry.durationSeconds, equals(15));
        expect(entry.syncPending, isTrue);
        expect(mockLocalStorageService.savedEntries.length, equals(1));
        expect(mockLocalStorageService.savedEntries.first.syncPending, isTrue);
      });

      test('scans barcode and saves locally when offline', () async {
        // Arrange
        mockBarcodeScannerService.setScanResult(
          const ScanResult(
            data: '1234567890123',
            format: BarcodeFormat.ean13,
          ),
        );

        // Act
        final entry = await offlineCaptureService.scanBarcode(
          reportId: 'report-1',
        );

        // Assert
        expect(entry, isNotNull);
        expect(entry!.type, equals(EntryType.scan));
        expect(entry.content, contains('1234567890123'));
        expect(entry.content, contains('EAN-13'));
        expect(entry.syncPending, isTrue);
        expect(mockLocalStorageService.savedEntries.length, equals(1));
        expect(mockLocalStorageService.savedEntries.first.syncPending, isTrue);
      });

      test('all entries marked for sync when online restored', () async {
        // Capture multiple entries while offline
        mockCameraService.setCapturedPhotoPath('/mock/photos/photo_001.jpg');
        await offlineCaptureService.capturePhoto(reportId: 'report-1');

        mockAudioRecorderService.setAudioRecordingResult(
          const AudioRecordingResult(
            path: '/mock/audio/memo_001.m4a',
            durationSeconds: 10,
          ),
        );
        await offlineCaptureService.startAudioRecording();
        await offlineCaptureService.stopAudioRecording(reportId: 'report-1');

        mockBarcodeScannerService.setScanResult(
          const ScanResult(
            data: 'QR_DATA_123',
            format: BarcodeFormat.qrCode,
          ),
        );
        await offlineCaptureService.scanBarcode(reportId: 'report-1');

        // Verify all entries are saved with syncPending = true
        expect(mockLocalStorageService.savedEntries.length, equals(3));
        expect(
          mockLocalStorageService.savedEntries.every((e) => e.syncPending),
          isTrue,
        );

        // Verify entries have correct types
        expect(
          mockLocalStorageService.savedEntries
              .any((e) => e.type == EntryType.photo),
          isTrue,
        );
        expect(
          mockLocalStorageService.savedEntries
              .any((e) => e.type == EntryType.audio),
          isTrue,
        );
        expect(
          mockLocalStorageService.savedEntries
              .any((e) => e.type == EntryType.scan),
          isTrue,
        );

        // Now go online and get pending entries
        connectivityService.setOnline(true);
        final pendingEntries = offlineCaptureService.getPendingSyncEntries();

        // All entries should be returned for sync
        expect(pendingEntries.length, equals(3));
      });
    });

    group('online mode', () {
      setUp(() {
        connectivityService.setOnline(true);
      });

      test('captures photo with syncPending=false when online', () async {
        mockCameraService.setCapturedPhotoPath('/mock/photos/photo_002.jpg');

        final entry = await offlineCaptureService.capturePhoto(
          reportId: 'report-1',
        );

        expect(entry, isNotNull);
        expect(entry!.syncPending, isFalse);
      });

      test('records video with syncPending=false when online', () async {
        mockCameraService.setVideoRecordingResult(
          const VideoRecordingResult(
            path: '/mock/videos/video_002.mp4',
            durationSeconds: 20,
          ),
        );

        await offlineCaptureService.startVideoRecording();
        final entry = await offlineCaptureService.stopVideoRecording(
          reportId: 'report-1',
        );

        expect(entry, isNotNull);
        expect(entry!.syncPending, isFalse);
      });

      test('records audio with syncPending=false when online', () async {
        mockAudioRecorderService.setAudioRecordingResult(
          const AudioRecordingResult(
            path: '/mock/audio/memo_002.m4a',
            durationSeconds: 5,
          ),
        );

        await offlineCaptureService.startAudioRecording();
        final entry = await offlineCaptureService.stopAudioRecording(
          reportId: 'report-1',
        );

        expect(entry, isNotNull);
        expect(entry!.syncPending, isFalse);
      });

      test('scans barcode with syncPending=false when online', () async {
        mockBarcodeScannerService.setScanResult(
          const ScanResult(
            data: '9876543210987',
            format: BarcodeFormat.upcA,
          ),
        );

        final entry = await offlineCaptureService.scanBarcode(
          reportId: 'report-1',
        );

        expect(entry, isNotNull);
        expect(entry!.syncPending, isFalse);
      });
    });
  });
}

/// Mock CameraService for testing.
class _MockCameraService implements CameraService {
  String? _capturedPhotoPath;
  VideoRecordingResult? _videoRecordingResult;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  double _zoomLevel = 1.0;

  void setCapturedPhotoPath(String path) {
    _capturedPhotoPath = path;
  }

  void setVideoRecordingResult(VideoRecordingResult result) {
    _videoRecordingResult = result;
  }

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  double get currentZoomLevel => _zoomLevel;

  @override
  double get minZoomLevel => 1.0;

  @override
  double get maxZoomLevel => 10.0;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> setZoomLevel(double zoom) async {
    _zoomLevel = zoom;
  }

  @override
  Future<void> openCamera() async {}

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {}

  @override
  Future<String?> capturePhoto({double? compassHeading}) async =>
      _capturedPhotoPath;

  @override
  Future<void> startRecording({bool enableAudio = true}) async {}

  @override
  Future<VideoRecordingResult?> stopRecording() async => _videoRecordingResult;

  @override
  Future<void> closeCamera() async {}

  @override
  Future<void> switchCamera() async {
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
  }

  @override
  Future<void> setFocusPoint(double x, double y) async {}
}

/// Mock AudioRecorderService for testing.
class _MockAudioRecorderService implements AudioRecorderService {
  AudioRecordingResult? _audioRecordingResult;
  Duration _currentPosition = Duration.zero;

  void setAudioRecordingResult(AudioRecordingResult result) {
    _audioRecordingResult = result;
  }

  @override
  Future<void> startRecording() async {}

  @override
  Future<AudioRecordingResult?> stopRecording() async => _audioRecordingResult;

  @override
  Future<void> startPlayback(String path) async {
    _currentPosition = Duration.zero;
  }

  @override
  Future<void> stopPlayback() async {
    _currentPosition = Duration.zero;
  }

  @override
  Future<void> pausePlayback() async {}

  @override
  Future<void> resumePlayback() async {}

  @override
  void setPositionListener(void Function(Duration)? listener) {}

  @override
  void setCompletionListener(void Function()? listener) {}

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Future<void> dispose() async {}
}

/// Mock BarcodeScannerService for testing.
class _MockBarcodeScannerService implements BarcodeScannerService {
  ScanResult? _scanResult;
  bool _flashlightOn = false;

  void setScanResult(ScanResult result) {
    _scanResult = result;
  }

  @override
  Future<ScanResult?> scan() async => _scanResult;

  @override
  Future<void> dispose() async {}

  @override
  bool get isFlashlightOn => _flashlightOn;

  @override
  Future<void> toggleFlashlight() async {
    _flashlightOn = !_flashlightOn;
  }
}

/// Mock LocalStorageService for testing.
class _MockLocalStorageService implements LocalStorageService {
  final List<Entry> savedEntries = [];

  @override
  Future<void> saveEntry(Entry entry) async {
    savedEntries.add(entry);
  }

  @override
  List<Entry> getEntriesByReportId(String reportId) {
    return savedEntries.where((e) => e.reportId == reportId).toList();
  }

  @override
  List<Entry> getPendingSyncEntries() {
    return savedEntries.where((e) => e.syncPending).toList();
  }

  @override
  Future<void> markEntrySynced(String entryId) async {
    final index = savedEntries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      savedEntries[index] = savedEntries[index].copyWith(syncPending: false);
    }
  }
}
