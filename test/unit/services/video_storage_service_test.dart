import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/services/video_storage_service.dart';

void main() {
  group('Large video files are stored efficiently', () {
    late VideoStorageService videoStorageService;

    setUp(() {
      videoStorageService = DefaultVideoStorageService();
    });

    test('record a 2-minute video and verify saves without error', () async {
      // Simulate recording a 2-minute video (120 seconds)
      final result = await videoStorageService.storeVideo(
        sourcePath: '/tmp/raw_video.mp4',
        durationSeconds: 120,
        originalSizeBytes: 500 * 1024 * 1024, // 500 MB raw
      );

      // Verify video saves without error
      expect(result, isNotNull);
      expect(result.success, isTrue);
      expect(result.outputPath, isNotEmpty);
      expect(result.error, isNull);
    });

    test('check storage usage for video file is reasonable', () async {
      // Store a 2-minute video
      final result = await videoStorageService.storeVideo(
        sourcePath: '/tmp/raw_video.mp4',
        durationSeconds: 120,
        originalSizeBytes: 500 * 1024 * 1024, // 500 MB raw
      );

      // Verify storage usage is tracked
      expect(result.fileSizeBytes, greaterThan(0));
      expect(result.fileSizeBytes, lessThan(result.originalSizeBytes));
    });

    test('verify compression applied - file size reasonable for 2 minutes',
        () async {
      // Store a 2-minute video
      final result = await videoStorageService.storeVideo(
        sourcePath: '/tmp/raw_video.mp4',
        durationSeconds: 120,
        originalSizeBytes: 500 * 1024 * 1024, // 500 MB raw
      );

      // For a 2-minute video at reasonable quality:
      // - H.264 at 720p ~5 Mbps = ~75 MB
      // - H.264 at 1080p ~8 Mbps = ~120 MB
      // Should be significantly smaller than original raw footage
      expect(result.compressionApplied, isTrue);
      expect(result.compressionRatio,
          greaterThan(1.0)); // At least some compression

      // Max 150 MB for 2-minute video (reasonable for mobile)
      const maxSizeBytes = 150 * 1024 * 1024;
      expect(result.fileSizeBytes, lessThanOrEqualTo(maxSizeBytes));
    });

    test('playback video - verify quality is acceptable', () async {
      // Store video with compression
      final result = await videoStorageService.storeVideo(
        sourcePath: '/tmp/raw_video.mp4',
        durationSeconds: 120,
        originalSizeBytes: 500 * 1024 * 1024,
      );

      // Get video metadata to verify quality
      final metadata = await videoStorageService.getVideoMetadata(
        result.outputPath,
      );

      // Verify quality parameters are acceptable
      // Minimum 720p resolution for field reporting
      expect(metadata.width, greaterThanOrEqualTo(1280));
      expect(metadata.height, greaterThanOrEqualTo(720));
      // Minimum 24fps for smooth playback
      expect(metadata.frameRate, greaterThanOrEqualTo(24));
      // Audio should be preserved
      expect(metadata.hasAudio, isTrue);
      expect(metadata.audioBitrate, greaterThan(0));
    });

    test('video storage reports accurate file size and metadata', () async {
      final result = await videoStorageService.storeVideo(
        sourcePath: '/tmp/raw_video.mp4',
        durationSeconds: 120,
        originalSizeBytes: 500 * 1024 * 1024,
      );

      // Verify metadata is accurate
      expect(result.durationSeconds, equals(120));
      expect(result.originalSizeBytes, equals(500 * 1024 * 1024));
      expect(result.fileSizeBytes, greaterThan(0));
    });

    test('video storage handles different durations efficiently', () async {
      // Test 30 second video
      final shortResult = await videoStorageService.storeVideo(
        sourcePath: '/tmp/short_video.mp4',
        durationSeconds: 30,
        originalSizeBytes: 125 * 1024 * 1024,
      );

      // Test 5 minute video
      final longResult = await videoStorageService.storeVideo(
        sourcePath: '/tmp/long_video.mp4',
        durationSeconds: 300,
        originalSizeBytes: 1250 * 1024 * 1024,
      );

      // Both should succeed
      expect(shortResult.success, isTrue);
      expect(longResult.success, isTrue);

      // Longer video should have proportionally larger file
      final shortBytesPerSecond = shortResult.fileSizeBytes / 30;
      final longBytesPerSecond = longResult.fileSizeBytes / 300;

      // Bytes per second should be similar (within 50%)
      expect(
        longBytesPerSecond / shortBytesPerSecond,
        closeTo(1.0, 0.5),
      );
    });
  });
}
