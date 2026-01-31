import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/models/photo_metadata.dart';

void main() {
  group('PhotoMetadata gyroscope data', () {
    test('captures gyroscope data when device is stationary', () {
      final metadata = PhotoMetadata(
        filePath: '/test/photo.jpg',
        capturedAt: DateTime(2024, 1, 15, 10, 30, 0),
        compassHeading: 90.0,
        deviceModel: 'iPhone 15',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
        gyroscopeX: 0.0,
        gyroscopeY: 0.0,
        gyroscopeZ: 0.0,
      );

      expect(metadata.gyroscopeX, equals(0.0));
      expect(metadata.gyroscopeY, equals(0.0));
      expect(metadata.gyroscopeZ, equals(0.0));
      expect(metadata.hasGyroscopeData, isTrue);
    });

    test('captures different gyroscope values when device is rotating', () {
      final stationaryMetadata = PhotoMetadata(
        filePath: '/test/photo1.jpg',
        capturedAt: DateTime(2024, 1, 15, 10, 30, 0),
        compassHeading: 90.0,
        deviceModel: 'iPhone 15',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
        gyroscopeX: 0.0,
        gyroscopeY: 0.0,
        gyroscopeZ: 0.0,
      );

      final rotatingMetadata = PhotoMetadata(
        filePath: '/test/photo2.jpg',
        capturedAt: DateTime(2024, 1, 15, 10, 30, 5),
        compassHeading: 90.0,
        deviceModel: 'iPhone 15',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
        gyroscopeX: 1.5,
        gyroscopeY: -0.8,
        gyroscopeZ: 2.1,
      );

      // Verify stationary values are near zero
      expect(stationaryMetadata.gyroscopeX, equals(0.0));
      expect(stationaryMetadata.gyroscopeY, equals(0.0));
      expect(stationaryMetadata.gyroscopeZ, equals(0.0));

      // Verify rotating values are different from stationary
      expect(rotatingMetadata.gyroscopeX,
          isNot(equals(stationaryMetadata.gyroscopeX)));
      expect(rotatingMetadata.gyroscopeY,
          isNot(equals(stationaryMetadata.gyroscopeY)));
      expect(rotatingMetadata.gyroscopeZ,
          isNot(equals(stationaryMetadata.gyroscopeZ)));

      // Verify rotating has non-zero values
      expect(
        rotatingMetadata.gyroscopeX != 0.0 ||
            rotatingMetadata.gyroscopeY != 0.0 ||
            rotatingMetadata.gyroscopeZ != 0.0,
        isTrue,
      );
    });

    test('gyroscope data is optional and null by default', () {
      final metadata = PhotoMetadata(
        filePath: '/test/photo.jpg',
        capturedAt: DateTime(2024, 1, 15, 10, 30, 0),
        compassHeading: 90.0,
        deviceModel: 'iPhone 15',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
      );

      expect(metadata.gyroscopeX, isNull);
      expect(metadata.gyroscopeY, isNull);
      expect(metadata.gyroscopeZ, isNull);
      expect(metadata.hasGyroscopeData, isFalse);
    });

    test('gyroscope data included in EXIF map', () {
      final metadata = PhotoMetadata(
        filePath: '/test/photo.jpg',
        capturedAt: DateTime(2024, 1, 15, 10, 30, 0),
        compassHeading: 90.0,
        deviceModel: 'iPhone 15',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
        gyroscopeX: 1.5,
        gyroscopeY: -0.8,
        gyroscopeZ: 2.1,
      );

      final exifMap = metadata.toExifMap();
      expect(exifMap['GyroscopeX'], equals(1.5));
      expect(exifMap['GyroscopeY'], equals(-0.8));
      expect(exifMap['GyroscopeZ'], equals(2.1));
    });

    test('PhotoCaptureContext includes gyroscope data', () {
      final context = PhotoCaptureContext(
        filePath: '/test/photo.jpg',
        capturedAt: DateTime(2024, 1, 15, 10, 30, 0),
        compassHeading: 90.0,
        deviceModel: 'iPhone 15',
        deviceMake: 'Apple',
        orientation: PhotoOrientation.landscape,
        gyroscopeX: 0.5,
        gyroscopeY: -0.3,
        gyroscopeZ: 0.1,
      );

      expect(context.gyroscopeX, equals(0.5));
      expect(context.gyroscopeY, equals(-0.3));
      expect(context.gyroscopeZ, equals(0.1));
    });
  });
}
