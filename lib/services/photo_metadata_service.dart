import '../models/photo_metadata.dart';

/// Service for creating and managing photo metadata.
class PhotoMetadataService {
  /// Creates PhotoMetadata from a capture context.
  PhotoMetadata createMetadata(PhotoCaptureContext context) {
    return PhotoMetadata(
      filePath: context.filePath,
      capturedAt: context.capturedAt,
      latitude: context.latitude,
      longitude: context.longitude,
      altitude: context.altitude,
      compassHeading: context.compassHeading,
      deviceModel: context.deviceModel,
      deviceMake: context.deviceMake,
      lensInfo: context.lensInfo,
      focalLength: context.focalLength,
      aperture: context.aperture,
      iso: context.iso,
      exposureTime: context.exposureTime,
      orientation: context.orientation,
    );
  }
}
