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
  });

  /// Path to the recorded video file.
  final String path;

  /// Duration of the video in seconds.
  final int durationSeconds;

  /// Path to the video thumbnail image.
  final String? thumbnailPath;
}

/// Service for camera operations.
abstract class CameraService {
  /// Opens the camera for photo capture.
  Future<void> openCamera();

  /// Opens the camera for video recording.
  Future<void> openCameraForVideo();

  /// Captures a photo and returns the file path.
  /// Returns null if capture was cancelled or failed.
  Future<String?> capturePhoto();

  /// Starts video recording.
  Future<void> startRecording();

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
}

/// Default implementation of CameraService.
/// In production, this would use the camera package.
class DefaultCameraService implements CameraService {
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
  Future<void> openCamera() async {
    // Implementation will use camera package
    _lensDirection = CameraLensDirection.back;
    _flashMode = FlashMode.auto;
  }

  @override
  Future<void> openCameraForVideo() async {
    // Implementation will use camera package
  }

  @override
  Future<String?> capturePhoto() async {
    // Implementation will use camera package
    return null;
  }

  @override
  Future<void> startRecording() async {
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
  }
}

/// Provider for the camera service.
final cameraServiceProvider = Provider<CameraService>((ref) {
  return DefaultCameraService();
});
