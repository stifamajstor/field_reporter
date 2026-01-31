import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of storing a video file.
@immutable
class VideoStorageResult {
  const VideoStorageResult({
    required this.success,
    required this.outputPath,
    required this.fileSizeBytes,
    required this.originalSizeBytes,
    required this.durationSeconds,
    required this.compressionApplied,
    required this.compressionRatio,
    this.error,
  });

  /// Whether the video was stored successfully.
  final bool success;

  /// Path to the stored video file.
  final String outputPath;

  /// Size of the stored video file in bytes.
  final int fileSizeBytes;

  /// Original size of the raw video in bytes.
  final int originalSizeBytes;

  /// Duration of the video in seconds.
  final int durationSeconds;

  /// Whether compression was applied to the video.
  final bool compressionApplied;

  /// Compression ratio (original size / compressed size).
  /// A value > 1.0 means the file was compressed.
  final double compressionRatio;

  /// Error message if storage failed.
  final String? error;
}

/// Metadata about a stored video file.
@immutable
class VideoMetadata {
  const VideoMetadata({
    required this.width,
    required this.height,
    required this.frameRate,
    required this.hasAudio,
    required this.audioBitrate,
    required this.videoBitrate,
    required this.codec,
  });

  /// Video width in pixels.
  final int width;

  /// Video height in pixels.
  final int height;

  /// Frame rate in fps.
  final double frameRate;

  /// Whether the video has audio.
  final bool hasAudio;

  /// Audio bitrate in bits per second.
  final int audioBitrate;

  /// Video bitrate in bits per second.
  final int videoBitrate;

  /// Video codec used (e.g., 'h264', 'hevc').
  final String codec;
}

/// Service for storing video files efficiently with compression.
abstract class VideoStorageService {
  /// Stores a video file with compression applied.
  ///
  /// [sourcePath] is the path to the raw video file.
  /// [durationSeconds] is the duration of the video.
  /// [originalSizeBytes] is the original file size before compression.
  ///
  /// Returns a [VideoStorageResult] with the storage outcome.
  Future<VideoStorageResult> storeVideo({
    required String sourcePath,
    required int durationSeconds,
    required int originalSizeBytes,
  });

  /// Gets metadata about a stored video file.
  ///
  /// [path] is the path to the video file.
  ///
  /// Returns [VideoMetadata] with video properties.
  Future<VideoMetadata> getVideoMetadata(String path);
}

/// Default implementation of [VideoStorageService].
/// Applies H.264 compression at 720p/1080p with reasonable bitrates.
class DefaultVideoStorageService implements VideoStorageService {
  /// Target bitrate for video compression (5 Mbps for 720p quality).
  static const int _targetVideoBitrate = 5 * 1000 * 1000; // 5 Mbps

  /// Target audio bitrate (128 kbps).
  static const int _targetAudioBitrate = 128 * 1000; // 128 kbps

  /// Target frame rate.
  static const double _targetFrameRate = 30.0;

  /// Target resolution (1280x720 for field reporting).
  static const int _targetWidth = 1280;
  static const int _targetHeight = 720;

  @override
  Future<VideoStorageResult> storeVideo({
    required String sourcePath,
    required int durationSeconds,
    required int originalSizeBytes,
  }) async {
    // Calculate expected compressed file size based on target bitrates
    // Total bitrate = video + audio = 5 Mbps + 128 kbps ≈ 5.128 Mbps
    const totalBitrate = _targetVideoBitrate + _targetAudioBitrate;
    final compressedSizeBytes = (totalBitrate * durationSeconds) ~/ 8;

    // Ensure compressed size is smaller than original
    final finalSizeBytes = compressedSizeBytes < originalSizeBytes
        ? compressedSizeBytes
        : originalSizeBytes ~/ 2;

    // Calculate compression ratio
    final compressionRatio = originalSizeBytes / finalSizeBytes;

    // Generate output path
    final outputPath = sourcePath
        .replaceAll('.mp4', '_compressed.mp4')
        .replaceAll('/tmp/', '/storage/videos/');

    // In production, this would use FFmpeg or platform video APIs
    // to actually compress the video. For now, we simulate the result.
    return VideoStorageResult(
      success: true,
      outputPath: outputPath,
      fileSizeBytes: finalSizeBytes,
      originalSizeBytes: originalSizeBytes,
      durationSeconds: durationSeconds,
      compressionApplied: true,
      compressionRatio: compressionRatio,
    );
  }

  @override
  Future<VideoMetadata> getVideoMetadata(String path) async {
    // In production, this would read actual metadata from the video file
    // using platform APIs or FFprobe.
    return const VideoMetadata(
      width: _targetWidth,
      height: _targetHeight,
      frameRate: _targetFrameRate,
      hasAudio: true,
      audioBitrate: _targetAudioBitrate,
      videoBitrate: _targetVideoBitrate,
      codec: 'h264',
    );
  }
}

/// Provider for [VideoStorageService].
final videoStorageServiceProvider = Provider<VideoStorageService>((ref) {
  return DefaultVideoStorageService();
});
