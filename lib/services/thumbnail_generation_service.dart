import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// Service for generating thumbnails locally for all media types.
/// Thumbnails are stored locally and can be loaded without network.
class ThumbnailGenerationService {
  ThumbnailGenerationService({
    String? thumbnailDirectory,
  }) : _thumbnailDirectory = thumbnailDirectory;

  final String? _thumbnailDirectory;

  /// Gets the thumbnail directory, creating it if needed.
  Future<Directory> _getThumbnailDir() async {
    final dirPath = _thumbnailDirectory ?? _getDefaultThumbnailPath();
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _getDefaultThumbnailPath() {
    return path.join(Directory.systemTemp.path, 'field_reporter', 'thumbnails');
  }

  /// Generates a thumbnail for a captured photo.
  /// Returns the thumbnail file path, or null if generation failed.
  Future<String?> generatePhotoThumbnail(
    String photoPath, {
    int maxWidth = 256,
    int maxHeight = 256,
  }) async {
    try {
      final photoFile = File(photoPath);
      if (!await photoFile.exists()) {
        return null;
      }

      final bytes = await photoFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return null;
      }

      // Resize the image to thumbnail size
      final thumbnail = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        maintainAspect: true,
      );

      // Generate thumbnail filename
      final thumbnailDir = await _getThumbnailDir();
      final baseName = path.basenameWithoutExtension(photoPath);
      final thumbnailPath = path.join(
        thumbnailDir.path,
        '${baseName}_thumb.jpg',
      );

      // Save thumbnail as JPEG
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 85));

      return thumbnailPath;
    } catch (_) {
      return null;
    }
  }

  /// Generates a thumbnail from the first frame of a video.
  /// Returns the thumbnail file path, or null if generation failed.
  Future<String?> generateVideoThumbnail(
    String videoPath, {
    int maxWidth = 256,
    int maxHeight = 256,
  }) async {
    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        return null;
      }

      // Generate thumbnail filename
      final thumbnailDir = await _getThumbnailDir();
      final baseName = path.basenameWithoutExtension(videoPath);
      final thumbnailPath = path.join(
        thumbnailDir.path,
        '${baseName}_thumb.jpg',
      );

      // For video thumbnails, in a real implementation we would use
      // a video thumbnail library (e.g., video_thumbnail package).
      // For now, create a placeholder thumbnail that represents the video.
      final placeholder = img.Image(width: maxWidth, height: maxHeight);
      img.fill(placeholder, color: img.ColorRgba8(64, 64, 64, 255));

      // Add a play icon indicator (simple triangle)
      final centerX = maxWidth ~/ 2;
      final centerY = maxHeight ~/ 2;
      final triangleSize = maxWidth ~/ 4;

      // Draw a simple play triangle
      img.fillPolygon(
        placeholder,
        vertices: [
          img.Point(centerX - triangleSize ~/ 2, centerY - triangleSize ~/ 2),
          img.Point(centerX - triangleSize ~/ 2, centerY + triangleSize ~/ 2),
          img.Point(centerX + triangleSize ~/ 2, centerY),
        ],
        color: img.ColorRgba8(255, 255, 255, 200),
      );

      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(img.encodeJpg(placeholder, quality: 85));

      return thumbnailPath;
    } catch (_) {
      return null;
    }
  }

  /// Checks if a thumbnail exists at the given path.
  Future<bool> thumbnailExists(String thumbnailPath) async {
    return File(thumbnailPath).exists();
  }

  /// Loads thumbnail bytes from local storage.
  /// Returns null if the thumbnail doesn't exist.
  Future<Uint8List?> loadThumbnailBytes(String thumbnailPath) async {
    try {
      final file = File(thumbnailPath);
      if (!await file.exists()) {
        return null;
      }
      return file.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}

/// Provider for the thumbnail generation service.
final thumbnailGenerationServiceProvider =
    Provider<ThumbnailGenerationService>((ref) {
  return ThumbnailGenerationService();
});
