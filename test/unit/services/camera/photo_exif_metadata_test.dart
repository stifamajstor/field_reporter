import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/models/photo_metadata.dart';
import 'package:field_reporter/services/photo_metadata_service.dart';

void main() {
  group('Captured photo is saved with full EXIF metadata', () {
    late PhotoMetadataService metadataService;

    setUp(() {
      metadataService = PhotoMetadataService();
    });

    test('photo metadata contains GPS coordinates', () {
      // Simulate capturing a photo outdoors with GPS
      final metadata = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        altitude: 120.5,
        compassHeading: 45.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        lensInfo: '24mm f/1.78',
        orientation: PhotoOrientation.portrait,
      );

      // Verify GPS coordinates are present
      expect(metadata.latitude, isNotNull);
      expect(metadata.longitude, isNotNull);
      expect(metadata.latitude, equals(45.8150));
      expect(metadata.longitude, equals(15.9819));
      expect(metadata.hasGpsCoordinates, isTrue);
    });

    test('photo metadata contains timestamp', () {
      final captureTime = DateTime(2026, 1, 31, 14, 30, 45);
      final metadata = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: captureTime,
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 90.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
      );

      // Verify timestamp is present
      expect(metadata.capturedAt, isNotNull);
      expect(metadata.capturedAt, equals(captureTime));
      expect(metadata.formattedTimestamp, equals('2026-01-31 14:30:45'));
    });

    test('photo metadata contains camera device info', () {
      final metadata = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 180.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        lensInfo: '24mm f/1.78',
        focalLength: 24.0,
        aperture: 1.78,
        iso: 100,
        exposureTime: '1/120',
        orientation: PhotoOrientation.portrait,
      );

      // Verify camera info (device, lens) is present
      expect(metadata.deviceModel, isNotNull);
      expect(metadata.deviceMake, isNotNull);
      expect(metadata.deviceModel, equals('iPhone 15 Pro'));
      expect(metadata.deviceMake, equals('Apple'));
      expect(metadata.lensInfo, equals('24mm f/1.78'));
      expect(metadata.hasCameraInfo, isTrue);
    });

    test('photo metadata contains orientation data', () {
      final metadataPortrait = PhotoMetadata(
        filePath: '/path/to/photo1.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 270.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.portrait,
      );

      final metadataLandscape = PhotoMetadata(
        filePath: '/path/to/photo2.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 0.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
      );

      // Verify orientation data is present
      expect(metadataPortrait.orientation, isNotNull);
      expect(metadataLandscape.orientation, isNotNull);
      expect(metadataPortrait.orientation, equals(PhotoOrientation.portrait));
      expect(metadataLandscape.orientation, equals(PhotoOrientation.landscape));
    });

    test('photo metadata contains compass direction', () {
      // Test North (0 degrees)
      final metadataNorth = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 0.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.portrait,
      );

      // Test East (90 degrees)
      final metadataEast = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 90.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.portrait,
      );

      // Test South (180 degrees)
      final metadataSouth = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 180.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.portrait,
      );

      // Test West (270 degrees)
      final metadataWest = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime.now(),
        latitude: 45.8150,
        longitude: 15.9819,
        compassHeading: 270.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.portrait,
      );

      // Verify compass direction is present
      expect(metadataNorth.compassHeading, equals(0.0));
      expect(metadataNorth.cardinalDirection, equals('N'));

      expect(metadataEast.compassHeading, equals(90.0));
      expect(metadataEast.cardinalDirection, equals('E'));

      expect(metadataSouth.compassHeading, equals(180.0));
      expect(metadataSouth.cardinalDirection, equals('S'));

      expect(metadataWest.compassHeading, equals(270.0));
      expect(metadataWest.cardinalDirection, equals('W'));
    });

    test(
        'photo metadata service creates complete metadata from capture context',
        () async {
      // Simulate capturing a photo outdoors with all sensor data
      final captureContext = PhotoCaptureContext(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime(2026, 1, 31, 16, 0, 0),
        latitude: 45.8150,
        longitude: 15.9819,
        altitude: 120.5,
        compassHeading: 45.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        lensInfo: '24mm f/1.78',
        focalLength: 24.0,
        aperture: 1.78,
        iso: 100,
        exposureTime: '1/120',
        orientation: PhotoOrientation.portrait,
      );

      final metadata = metadataService.createMetadata(captureContext);

      // Verify all EXIF metadata is present
      expect(metadata.filePath, equals('/path/to/photo.jpg'));
      expect(metadata.capturedAt, equals(DateTime(2026, 1, 31, 16, 0, 0)));
      expect(metadata.latitude, equals(45.8150));
      expect(metadata.longitude, equals(15.9819));
      expect(metadata.altitude, equals(120.5));
      expect(metadata.compassHeading, equals(45.0));
      expect(metadata.cardinalDirection, equals('NE'));
      expect(metadata.deviceModel, equals('iPhone 15 Pro'));
      expect(metadata.deviceMake, equals('Apple'));
      expect(metadata.lensInfo, equals('24mm f/1.78'));
      expect(metadata.orientation, equals(PhotoOrientation.portrait));
    });

    test('photo metadata converts to EXIF-compatible map', () {
      final metadata = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime(2026, 1, 31, 14, 30, 45),
        latitude: 45.8150,
        longitude: 15.9819,
        altitude: 120.5,
        compassHeading: 45.0,
        deviceModel: 'iPhone 15 Pro',
        deviceMake: 'Apple',
        lensInfo: '24mm f/1.78',
        focalLength: 24.0,
        aperture: 1.78,
        iso: 100,
        exposureTime: '1/120',
        orientation: PhotoOrientation.portrait,
      );

      final exifMap = metadata.toExifMap();

      // Standard EXIF tags
      expect(exifMap['DateTimeOriginal'], equals('2026:01:31 14:30:45'));
      expect(exifMap['GPSLatitude'], equals(45.8150));
      expect(exifMap['GPSLongitude'], equals(15.9819));
      expect(exifMap['GPSAltitude'], equals(120.5));
      expect(exifMap['GPSImgDirection'], equals(45.0));
      expect(exifMap['Make'], equals('Apple'));
      expect(exifMap['Model'], equals('iPhone 15 Pro'));
      expect(exifMap['LensModel'], equals('24mm f/1.78'));
      expect(exifMap['FocalLength'], equals(24.0));
      expect(exifMap['FNumber'], equals(1.78));
      expect(exifMap['ISOSpeedRatings'], equals(100));
      expect(exifMap['ExposureTime'], equals('1/120'));
      expect(
          exifMap['Orientation'], equals(6)); // Portrait = EXIF orientation 6
    });

    test('photo metadata handles missing optional fields gracefully', () {
      final metadata = PhotoMetadata(
        filePath: '/path/to/photo.jpg',
        capturedAt: DateTime.now(),
        compassHeading: 90.0,
        deviceModel: 'Generic Phone',
        deviceMake: 'Unknown',
        orientation: PhotoOrientation.landscape,
      );

      // Should not have GPS coordinates
      expect(metadata.hasGpsCoordinates, isFalse);
      expect(metadata.latitude, isNull);
      expect(metadata.longitude, isNull);

      // Should still have basic info
      expect(metadata.capturedAt, isNotNull);
      expect(metadata.compassHeading, equals(90.0));
      expect(metadata.cardinalDirection, equals('E'));
    });
  });
}
