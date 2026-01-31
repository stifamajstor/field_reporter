import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/entries/domain/entry.dart';
import 'audio_recorder_service.dart';
import 'barcode_scanner_service.dart';
import 'camera_service.dart';
import 'connectivity_service.dart';

/// Service for local entry storage operations.
abstract class LocalStorageService {
  /// Saves an entry to local storage.
  Future<void> saveEntry(Entry entry);

  /// Gets entries for a specific report.
  List<Entry> getEntriesByReportId(String reportId);

  /// Gets all entries pending sync.
  List<Entry> getPendingSyncEntries();

  /// Marks an entry as synced.
  Future<void> markEntrySynced(String entryId);
}

/// Default implementation of LocalStorageService.
class DefaultLocalStorageService implements LocalStorageService {
  final List<Entry> _entries = [];

  @override
  Future<void> saveEntry(Entry entry) async {
    _entries.add(entry);
  }

  @override
  List<Entry> getEntriesByReportId(String reportId) {
    return _entries.where((e) => e.reportId == reportId).toList();
  }

  @override
  List<Entry> getPendingSyncEntries() {
    return _entries.where((e) => e.syncPending).toList();
  }

  @override
  Future<void> markEntrySynced(String entryId) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(syncPending: false);
    }
  }
}

/// Service for capturing media entries with offline support.
/// All captures work without network connection and are marked for sync when online.
class OfflineCaptureService {
  OfflineCaptureService({
    required this.connectivityService,
    required this.cameraService,
    required this.audioRecorderService,
    required this.barcodeScannerService,
    required this.localStorageService,
  });

  final ConnectivityService connectivityService;
  final CameraService cameraService;
  final AudioRecorderService audioRecorderService;
  final BarcodeScannerService barcodeScannerService;
  final LocalStorageService localStorageService;

  final _uuid = const Uuid();

  /// Captures a photo and saves it locally.
  /// Returns the created entry, or null if capture failed.
  Future<Entry?> capturePhoto({
    required String reportId,
    double? compassHeading,
    double? latitude,
    double? longitude,
  }) async {
    final photoPath = await cameraService.capturePhoto(
      compassHeading: compassHeading,
    );

    if (photoPath == null) {
      return null;
    }

    final now = DateTime.now();
    final entry = Entry(
      id: _uuid.v4(),
      reportId: reportId,
      type: EntryType.photo,
      mediaPath: photoPath,
      latitude: latitude,
      longitude: longitude,
      compassHeading: compassHeading,
      sortOrder: 0,
      capturedAt: now,
      createdAt: now,
      syncPending: !connectivityService.isOnline,
    );

    await localStorageService.saveEntry(entry);
    return entry;
  }

  /// Starts video recording.
  Future<void> startVideoRecording({bool enableAudio = true}) async {
    await cameraService.startRecording(enableAudio: enableAudio);
  }

  /// Stops video recording and saves it locally.
  /// Returns the created entry, or null if recording failed.
  Future<Entry?> stopVideoRecording({
    required String reportId,
    double? latitude,
    double? longitude,
    double? compassHeading,
  }) async {
    final result = await cameraService.stopRecording();

    if (result == null) {
      return null;
    }

    final now = DateTime.now();
    final entry = Entry(
      id: _uuid.v4(),
      reportId: reportId,
      type: EntryType.video,
      mediaPath: result.path,
      thumbnailPath: result.thumbnailPath,
      durationSeconds: result.durationSeconds,
      latitude: latitude,
      longitude: longitude,
      compassHeading: compassHeading,
      sortOrder: 0,
      capturedAt: now,
      createdAt: now,
      syncPending: !connectivityService.isOnline,
    );

    await localStorageService.saveEntry(entry);
    return entry;
  }

  /// Starts audio recording.
  Future<void> startAudioRecording() async {
    await audioRecorderService.startRecording();
  }

  /// Stops audio recording and saves it locally.
  /// Returns the created entry, or null if recording failed.
  Future<Entry?> stopAudioRecording({
    required String reportId,
    double? latitude,
    double? longitude,
  }) async {
    final result = await audioRecorderService.stopRecording();

    if (result == null) {
      return null;
    }

    final now = DateTime.now();
    final entry = Entry(
      id: _uuid.v4(),
      reportId: reportId,
      type: EntryType.audio,
      mediaPath: result.path,
      durationSeconds: result.durationSeconds,
      latitude: latitude,
      longitude: longitude,
      sortOrder: 0,
      capturedAt: now,
      createdAt: now,
      syncPending: !connectivityService.isOnline,
    );

    await localStorageService.saveEntry(entry);
    return entry;
  }

  /// Scans a barcode/QR code and saves it locally.
  /// Returns the created entry, or null if scan failed.
  Future<Entry?> scanBarcode({
    required String reportId,
    double? latitude,
    double? longitude,
  }) async {
    final result = await barcodeScannerService.scan();

    if (result == null) {
      return null;
    }

    final now = DateTime.now();
    final content = '${result.formatDisplayName}: ${result.data}';
    final entry = Entry(
      id: _uuid.v4(),
      reportId: reportId,
      type: EntryType.scan,
      content: content,
      latitude: latitude,
      longitude: longitude,
      sortOrder: 0,
      capturedAt: now,
      createdAt: now,
      syncPending: !connectivityService.isOnline,
    );

    await localStorageService.saveEntry(entry);
    return entry;
  }

  /// Gets all entries pending sync.
  List<Entry> getPendingSyncEntries() {
    return localStorageService.getPendingSyncEntries();
  }

  /// Marks an entry as synced.
  Future<void> markEntrySynced(String entryId) async {
    await localStorageService.markEntrySynced(entryId);
  }
}

/// Provider for LocalStorageService.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return DefaultLocalStorageService();
});

/// Provider for OfflineCaptureService.
final offlineCaptureServiceProvider = Provider<OfflineCaptureService>((ref) {
  return OfflineCaptureService(
    connectivityService: ref.watch(connectivityServiceProvider),
    cameraService: ref.watch(cameraServiceProvider),
    audioRecorderService: ref.watch(audioRecorderServiceProvider),
    barcodeScannerService: ref.watch(barcodeScannerServiceProvider),
    localStorageService: ref.watch(localStorageServiceProvider),
  );
});
