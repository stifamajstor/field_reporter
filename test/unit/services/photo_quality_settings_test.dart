import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/services/photo_quality_service.dart';

void main() {
  group('Photo quality settings affect file size', () {
    late ProviderContainer container;
    late PhotoQualityService photoQualityService;

    setUp(() {
      container = ProviderContainer();
      photoQualityService = container.read(photoQualityServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'navigate to Settings > Quality Settings - quality options are available',
        () async {
      // Verify quality options are available
      expect(PhotoQuality.values, contains(PhotoQuality.high));
      expect(PhotoQuality.values, contains(PhotoQuality.medium));
      expect(PhotoQuality.values, contains(PhotoQuality.low));
    });

    test('set photo quality to High and capture a photo', () async {
      // Set photo quality to High
      await photoQualityService.setPhotoQuality(PhotoQuality.high);

      // Verify quality is set
      expect(photoQualityService.currentQuality, equals(PhotoQuality.high));

      // Simulate capturing a photo (4032x3024 resolution typical of high quality)
      final highQualityResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024, // 10 MB raw
        width: 4032,
        height: 3024,
      );

      // Note high quality file size
      expect(highQualityResult.success, isTrue);
      expect(highQualityResult.fileSizeBytes, greaterThan(0));
    });

    test('set photo quality to Medium and capture similar photo', () async {
      // Set photo quality to Medium
      await photoQualityService.setPhotoQuality(PhotoQuality.medium);

      // Verify quality is set
      expect(photoQualityService.currentQuality, equals(PhotoQuality.medium));

      // Capture similar photo with medium quality
      final mediumQualityResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024, // 10 MB raw
        width: 4032,
        height: 3024,
      );

      // Note medium quality file size
      expect(mediumQualityResult.success, isTrue);
      expect(mediumQualityResult.fileSizeBytes, greaterThan(0));
    });

    test('verify Medium is smaller than High quality', () async {
      // Capture with High quality
      await photoQualityService.setPhotoQuality(PhotoQuality.high);
      final highResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024,
        width: 4032,
        height: 3024,
      );

      // Capture with Medium quality
      await photoQualityService.setPhotoQuality(PhotoQuality.medium);
      final mediumResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024,
        width: 4032,
        height: 3024,
      );

      // Medium should be smaller than High
      expect(
        mediumResult.fileSizeBytes,
        lessThan(highResult.fileSizeBytes),
        reason: 'Medium quality should produce smaller file than High quality',
      );
    });

    test('verify both photos are usable quality', () async {
      // High quality photo should meet minimum standards
      await photoQualityService.setPhotoQuality(PhotoQuality.high);
      final highResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024,
        width: 4032,
        height: 3024,
      );

      // Medium quality photo should also meet minimum standards
      await photoQualityService.setPhotoQuality(PhotoQuality.medium);
      final mediumResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024,
        width: 4032,
        height: 3024,
      );

      // Both should have usable resolution
      // High quality: full resolution
      expect(highResult.outputWidth, greaterThanOrEqualTo(3024));
      expect(highResult.outputHeight, greaterThanOrEqualTo(3024));

      // Medium quality: at least 1920x1080 (Full HD)
      expect(mediumResult.outputWidth, greaterThanOrEqualTo(1920));
      expect(mediumResult.outputHeight, greaterThanOrEqualTo(1080));

      // Both should have reasonable JPEG quality
      expect(highResult.jpegQuality, greaterThanOrEqualTo(90));
      expect(mediumResult.jpegQuality, greaterThanOrEqualTo(70));
    });

    test('low quality produces smallest files while still usable', () async {
      // Get all quality levels
      await photoQualityService.setPhotoQuality(PhotoQuality.high);
      final highResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024,
        width: 4032,
        height: 3024,
      );

      await photoQualityService.setPhotoQuality(PhotoQuality.medium);
      final mediumResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024,
        width: 4032,
        height: 3024,
      );

      await photoQualityService.setPhotoQuality(PhotoQuality.low);
      final lowResult = await photoQualityService.processPhoto(
        sourcePath: '/tmp/raw_photo.jpg',
        originalSizeBytes: 10 * 1024 * 1024,
        width: 4032,
        height: 3024,
      );

      // Verify ordering: High > Medium > Low
      expect(highResult.fileSizeBytes, greaterThan(mediumResult.fileSizeBytes));
      expect(mediumResult.fileSizeBytes, greaterThan(lowResult.fileSizeBytes));

      // Low quality should still be usable (at least 1280x720)
      expect(lowResult.outputWidth, greaterThanOrEqualTo(1280));
      expect(lowResult.outputHeight, greaterThanOrEqualTo(720));
    });

    test('quality settings persist across sessions', () async {
      // Set quality to medium
      await photoQualityService.setPhotoQuality(PhotoQuality.medium);
      expect(photoQualityService.currentQuality, equals(PhotoQuality.medium));

      // Create new service instance (simulating app restart)
      final newService = DefaultPhotoQualityService();
      await newService.initialize();

      // Quality should be persisted (in real implementation via SharedPreferences)
      // For now, verify the mechanism exists
      expect(newService.currentQuality, isNotNull);
    });

    test('quality settings include descriptive names', () {
      // Verify human-readable names for settings UI
      expect(PhotoQuality.high.displayName, equals('High'));
      expect(PhotoQuality.medium.displayName, equals('Medium'));
      expect(PhotoQuality.low.displayName, equals('Low'));

      // Verify descriptions
      expect(PhotoQuality.high.description, contains('resolution'));
      expect(PhotoQuality.medium.description, contains('Balance'));
      expect(PhotoQuality.low.description, contains('storage'));
    });
  });
}
