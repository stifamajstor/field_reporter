import 'package:flutter/foundation.dart';

/// Photo orientation values matching EXIF orientation standards.
enum PhotoOrientation {
  /// Normal landscape (horizontal)
  landscape,

  /// Portrait (vertical)
  portrait,

  /// Landscape flipped
  landscapeFlipped,

  /// Portrait flipped
  portraitFlipped,
}

/// Extension to convert PhotoOrientation to EXIF orientation value.
extension PhotoOrientationExif on PhotoOrientation {
  /// Returns the EXIF orientation value (1-8).
  int get exifValue {
    switch (this) {
      case PhotoOrientation.landscape:
        return 1; // Horizontal (normal)
      case PhotoOrientation.portrait:
        return 6; // Rotated 90 CW
      case PhotoOrientation.landscapeFlipped:
        return 3; // Rotated 180
      case PhotoOrientation.portraitFlipped:
        return 8; // Rotated 90 CCW
    }
  }
}

/// Metadata associated with a captured photo, including EXIF-compatible fields.
@immutable
class PhotoMetadata {
  const PhotoMetadata({
    required this.filePath,
    required this.capturedAt,
    required this.compassHeading,
    required this.deviceModel,
    required this.deviceMake,
    required this.orientation,
    this.latitude,
    this.longitude,
    this.altitude,
    this.lensInfo,
    this.focalLength,
    this.aperture,
    this.iso,
    this.exposureTime,
  });

  /// Path to the photo file.
  final String filePath;

  /// Timestamp when the photo was captured.
  final DateTime capturedAt;

  /// GPS latitude in decimal degrees.
  final double? latitude;

  /// GPS longitude in decimal degrees.
  final double? longitude;

  /// GPS altitude in meters.
  final double? altitude;

  /// Compass heading in degrees (0-360).
  final double compassHeading;

  /// Device model name (e.g., "iPhone 15 Pro").
  final String deviceModel;

  /// Device manufacturer (e.g., "Apple").
  final String deviceMake;

  /// Lens information string.
  final String? lensInfo;

  /// Focal length in mm.
  final double? focalLength;

  /// Aperture f-number.
  final double? aperture;

  /// ISO speed rating.
  final int? iso;

  /// Exposure time as a string (e.g., "1/120").
  final String? exposureTime;

  /// Photo orientation.
  final PhotoOrientation orientation;

  /// Whether GPS coordinates are available.
  bool get hasGpsCoordinates => latitude != null && longitude != null;

  /// Whether camera info is available.
  bool get hasCameraInfo => deviceModel.isNotEmpty && deviceMake.isNotEmpty;

  /// Formatted timestamp in ISO-like format.
  String get formattedTimestamp {
    return '${capturedAt.year.toString().padLeft(4, '0')}-'
        '${capturedAt.month.toString().padLeft(2, '0')}-'
        '${capturedAt.day.toString().padLeft(2, '0')} '
        '${capturedAt.hour.toString().padLeft(2, '0')}:'
        '${capturedAt.minute.toString().padLeft(2, '0')}:'
        '${capturedAt.second.toString().padLeft(2, '0')}';
  }

  /// Get cardinal direction from compass heading.
  String get cardinalDirection {
    if (compassHeading >= 337.5 || compassHeading < 22.5) return 'N';
    if (compassHeading >= 22.5 && compassHeading < 67.5) return 'NE';
    if (compassHeading >= 67.5 && compassHeading < 112.5) return 'E';
    if (compassHeading >= 112.5 && compassHeading < 157.5) return 'SE';
    if (compassHeading >= 157.5 && compassHeading < 202.5) return 'S';
    if (compassHeading >= 202.5 && compassHeading < 247.5) return 'SW';
    if (compassHeading >= 247.5 && compassHeading < 292.5) return 'W';
    if (compassHeading >= 292.5 && compassHeading < 337.5) return 'NW';
    return 'N';
  }

  /// Convert to EXIF-compatible map for writing to image file.
  Map<String, dynamic> toExifMap() {
    final exifTimestamp =
        '${capturedAt.year}:${capturedAt.month.toString().padLeft(2, '0')}:${capturedAt.day.toString().padLeft(2, '0')} '
        '${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}:${capturedAt.second.toString().padLeft(2, '0')}';

    final map = <String, dynamic>{
      'DateTimeOriginal': exifTimestamp,
      'Make': deviceMake,
      'Model': deviceModel,
      'Orientation': orientation.exifValue,
      'GPSImgDirection': compassHeading,
    };

    if (latitude != null) {
      map['GPSLatitude'] = latitude;
    }
    if (longitude != null) {
      map['GPSLongitude'] = longitude;
    }
    if (altitude != null) {
      map['GPSAltitude'] = altitude;
    }
    if (lensInfo != null) {
      map['LensModel'] = lensInfo;
    }
    if (focalLength != null) {
      map['FocalLength'] = focalLength;
    }
    if (aperture != null) {
      map['FNumber'] = aperture;
    }
    if (iso != null) {
      map['ISOSpeedRatings'] = iso;
    }
    if (exposureTime != null) {
      map['ExposureTime'] = exposureTime;
    }

    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoMetadata &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          capturedAt == other.capturedAt &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          compassHeading == other.compassHeading;

  @override
  int get hashCode =>
      filePath.hashCode ^
      capturedAt.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      compassHeading.hashCode;
}

/// Context data collected at the moment of photo capture.
@immutable
class PhotoCaptureContext {
  const PhotoCaptureContext({
    required this.filePath,
    required this.capturedAt,
    required this.compassHeading,
    required this.deviceModel,
    required this.deviceMake,
    required this.orientation,
    this.latitude,
    this.longitude,
    this.altitude,
    this.lensInfo,
    this.focalLength,
    this.aperture,
    this.iso,
    this.exposureTime,
  });

  final String filePath;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double compassHeading;
  final String deviceModel;
  final String deviceMake;
  final String? lensInfo;
  final double? focalLength;
  final double? aperture;
  final int? iso;
  final String? exposureTime;
  final PhotoOrientation orientation;
}
