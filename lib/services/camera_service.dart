import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

/// Default implementation of CameraService.
/// In production, this would use the camera package.
class DefaultCameraService implements CameraService {
  @override
  Future<void> openCamera() async {
    // Implementation will use camera package
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
}

/// Provider for the camera service.
final cameraServiceProvider = Provider<CameraService>((ref) {
  return DefaultCameraService();
});
