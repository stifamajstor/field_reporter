import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Photo quality levels.
enum PhotoQuality {
  /// Full resolution, highest JPEG quality (90+).
  /// Best for archival and detailed documentation.
  high,

  /// Reduced resolution (Full HD), balanced JPEG quality (75-85).
  /// Good balance between quality and file size.
  medium,

  /// Lower resolution (720p), lower JPEG quality (60-70).
  /// Best for storage-constrained situations.
  low;

  /// Human-readable display name for UI.
  String get displayName => switch (this) {
        PhotoQuality.high => 'High',
        PhotoQuality.medium => 'Medium',
        PhotoQuality.low => 'Low',
      };

  /// Descriptive text for settings UI.
  String get description => switch (this) {
        PhotoQuality.high =>
          'Full resolution, best quality. Ideal for detailed documentation.',
        PhotoQuality.medium =>
          'Balanced quality and file size. Good for most use cases.',
        PhotoQuality.low =>
          'Optimized for storage. Smaller files, still usable quality.',
      };

  /// Target JPEG quality (0-100).
  int get jpegQuality => switch (this) {
        PhotoQuality.high => 92,
        PhotoQuality.medium => 80,
        PhotoQuality.low => 65,
      };

  /// Maximum output dimension (longest side).
  int get maxDimension => switch (this) {
        PhotoQuality.high => 4032, // Full sensor resolution
        PhotoQuality.medium => 1920, // Full HD
        PhotoQuality.low => 1280, // 720p
      };
}

/// Result of processing a photo with quality settings.
@immutable
class PhotoProcessingResult {
  const PhotoProcessingResult({
    required this.success,
    required this.outputPath,
    required this.fileSizeBytes,
    required this.originalSizeBytes,
    required this.outputWidth,
    required this.outputHeight,
    required this.jpegQuality,
    required this.quality,
    this.error,
  });

  /// Whether the photo was processed successfully.
  final bool success;

  /// Path to the processed photo file.
  final String outputPath;

  /// Size of the processed photo file in bytes.
  final int fileSizeBytes;

  /// Original size of the raw photo in bytes.
  final int originalSizeBytes;

  /// Output width in pixels.
  final int outputWidth;

  /// Output height in pixels.
  final int outputHeight;

  /// JPEG quality used (0-100).
  final int jpegQuality;

  /// Quality level used.
  final PhotoQuality quality;

  /// Error message if processing failed.
  final String? error;
}

/// Service for processing photos with quality settings.
abstract class PhotoQualityService {
  /// Gets the current photo quality setting.
  PhotoQuality get currentQuality;

  /// Sets the photo quality level.
  Future<void> setPhotoQuality(PhotoQuality quality);

  /// Processes a photo according to current quality settings.
  ///
  /// [sourcePath] is the path to the raw photo file.
  /// [originalSizeBytes] is the original file size.
  /// [width] is the original image width.
  /// [height] is the original image height.
  ///
  /// Returns a [PhotoProcessingResult] with the processing outcome.
  Future<PhotoProcessingResult> processPhoto({
    required String sourcePath,
    required int originalSizeBytes,
    required int width,
    required int height,
  });

  /// Initializes the service and loads persisted settings.
  Future<void> initialize();
}

/// Default implementation of [PhotoQualityService].
class DefaultPhotoQualityService implements PhotoQualityService {
  PhotoQuality _currentQuality = PhotoQuality.high;

  @override
  PhotoQuality get currentQuality => _currentQuality;

  @override
  Future<void> setPhotoQuality(PhotoQuality quality) async {
    _currentQuality = quality;
    // In production, persist to SharedPreferences
  }

  @override
  Future<void> initialize() async {
    // In production, load from SharedPreferences
    // For now, default to high quality
    _currentQuality = PhotoQuality.high;
  }

  @override
  Future<PhotoProcessingResult> processPhoto({
    required String sourcePath,
    required int originalSizeBytes,
    required int width,
    required int height,
  }) async {
    final quality = _currentQuality;

    // Calculate output dimensions based on quality setting
    final (outputWidth, outputHeight) =
        _calculateOutputDimensions(width, height, quality.maxDimension);

    // Estimate file size based on quality settings
    // Base: ~0.5 bytes per pixel at quality 100
    // Adjusted by quality factor
    final pixelCount = outputWidth * outputHeight;
    final qualityFactor = quality.jpegQuality / 100.0;
    final baseBytesPerPixel = 0.5 * qualityFactor * qualityFactor;
    final estimatedSize = (pixelCount * baseBytesPerPixel).round();

    // Ensure we never exceed original size
    final finalSize =
        estimatedSize < originalSizeBytes ? estimatedSize : originalSizeBytes;

    // Generate output path
    final outputPath = sourcePath
        .replaceAll('.jpg', '_processed.jpg')
        .replaceAll('/tmp/', '/storage/photos/');

    return PhotoProcessingResult(
      success: true,
      outputPath: outputPath,
      fileSizeBytes: finalSize,
      originalSizeBytes: originalSizeBytes,
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      jpegQuality: quality.jpegQuality,
      quality: quality,
    );
  }

  /// Calculates output dimensions maintaining aspect ratio.
  (int, int) _calculateOutputDimensions(
      int width, int height, int maxDimension) {
    // If already smaller than max, keep original
    if (width <= maxDimension && height <= maxDimension) {
      return (width, height);
    }

    // Scale down maintaining aspect ratio
    final aspectRatio = width / height;
    if (width > height) {
      final newWidth = maxDimension;
      final newHeight = (maxDimension / aspectRatio).round();
      return (newWidth, newHeight);
    } else {
      final newHeight = maxDimension;
      final newWidth = (maxDimension * aspectRatio).round();
      return (newWidth, newHeight);
    }
  }
}

/// Provider for [PhotoQualityService].
final photoQualityServiceProvider = Provider<PhotoQualityService>((ref) {
  return DefaultPhotoQualityService();
});
