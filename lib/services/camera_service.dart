import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Camera lens direction.
enum CameraLensDirection {
  front,
  back,
}

/// Flash mode for camera.
enum FlashMode {
  auto,
  on,
  off,
}

/// Error types for camera service.
enum CameraError {
  cameraFailure,
  permissionDenied,
}

/// Exception thrown by camera service.
class CameraServiceException implements Exception {
  final CameraError error;

  const CameraServiceException(this.error);

  String get message {
    switch (error) {
      case CameraError.cameraFailure:
        return 'Unable to access camera';
      case CameraError.permissionDenied:
        return 'Camera permission is required';
    }
  }

  bool get isPermissionError => error == CameraError.permissionDenied;
}

/// Result of a video recording.
@immutable
class VideoRecordingResult {
  const VideoRecordingResult({
    required this.path,
    required this.durationSeconds,
    this.thumbnailPath,
    this.hasAudio = true,
  });

  /// Path to the recorded video file.
  final String path;

  /// Duration of the video in seconds.
  final int durationSeconds;

  /// Path to the video thumbnail image.
  final String? thumbnailPath;

  /// Whether the video has audio.
  final bool hasAudio;
}

/// Service for camera operations.
abstract class CameraService {
  /// Opens the camera for photo capture.
  Future<void> openCamera();

  /// Opens the camera for video recording.
  /// [enableAudio] controls whether the camera is configured to capture audio.
  Future<void> openCameraForVideo({bool enableAudio = true});

  /// Captures a photo and returns the file path.
  /// Returns null if capture was cancelled or failed.
  /// [compassHeading] is the compass direction in degrees (0-360) at capture time.
  Future<String?> capturePhoto({double? compassHeading});

  /// Starts video recording.
  /// [enableAudio] controls whether audio is captured (requires microphone permission).
  Future<void> startRecording({bool enableAudio = true});

  /// Stops video recording and returns the result.
  /// Returns null if recording was cancelled or failed.
  Future<VideoRecordingResult?> stopRecording();

  /// Closes the camera and releases resources.
  Future<void> closeCamera();

  /// Switches between front and back camera.
  Future<void> switchCamera();

  /// Gets the current lens direction.
  CameraLensDirection get lensDirection;

  /// Sets the flash mode.
  Future<void> setFlashMode(FlashMode mode);

  /// Gets the current flash mode.
  FlashMode get currentFlashMode;

  /// Sets the zoom level.
  /// [zoom] is a multiplier value (e.g., 1.0 = no zoom, 2.0 = 2x zoom).
  Future<void> setZoomLevel(double zoom);

  /// Gets the current zoom level.
  double get currentZoomLevel;

  /// Gets the minimum supported zoom level.
  double get minZoomLevel;

  /// Gets the maximum supported zoom level.
  double get maxZoomLevel;

  /// Sets the focus point on the camera preview.
  /// [x] and [y] are normalized coordinates (0.0 to 1.0) relative to the preview.
  Future<void> setFocusPoint(double x, double y);
}

/// Default implementation of CameraService.
/// In production, this would use the camera package.
class DefaultCameraService implements CameraService {
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  FlashMode _flashMode = FlashMode.auto;
  double _zoomLevel = 1.0;
  final double _minZoom = 1.0;
  final double _maxZoom = 10.0;

  @override
  CameraLensDirection get lensDirection => _lensDirection;

  @override
  FlashMode get currentFlashMode => _flashMode;

  @override
  double get currentZoomLevel => _zoomLevel;

  @override
  double get minZoomLevel => _minZoom;

  @override
  double get maxZoomLevel => _maxZoom;

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    _flashMode = mode;
  }

  @override
  Future<void> setZoomLevel(double zoom) async {
    _zoomLevel = zoom.clamp(_minZoom, _maxZoom);
  }

  @override
  Future<void> openCamera() async {
    // Implementation will use camera package
    _lensDirection = CameraLensDirection.back;
    _flashMode = FlashMode.auto;
    _zoomLevel = 1.0;
  }

  @override
  Future<void> openCameraForVideo({bool enableAudio = true}) async {
    // Implementation will use camera package
  }

  @override
  Future<String?> capturePhoto({double? compassHeading}) async {
    // Implementation will use camera package
    // compassHeading would be stored in EXIF metadata
    return null;
  }

  @override
  Future<void> startRecording({bool enableAudio = true}) async {
    // Implementation will use camera package
  }

  @override
  Future<VideoRecordingResult?> stopRecording() async {
    // Implementation will use camera package
    return null;
  }

  @override
  Future<void> closeCamera() async {
    // Implementation will use camera package
  }

  @override
  Future<void> switchCamera() async {
    // Implementation will use camera package
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    // Reset zoom when switching cameras
    _zoomLevel = 1.0;
  }

  @override
  Future<void> setFocusPoint(double x, double y) async {
    // Implementation will use camera package to set focus point
  }
}

/// Provider for the camera service.
final cameraServiceProvider = Provider<CameraService>((ref) {
  return DefaultCameraService();
});
