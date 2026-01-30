import 'package:flutter/foundation.dart';

/// Type of entry in a report.
enum EntryType {
  /// Photo entry.
  photo,

  /// Video entry.
  video,

  /// Audio/voice memo entry.
  audio,

  /// Text note entry.
  note,

  /// QR/barcode scan entry.
  scan,
}

/// An entry in a report.
@immutable
class Entry {
  const Entry({
    required this.id,
    required this.reportId,
    required this.type,
    this.mediaPath,
    this.thumbnailPath,
    this.content,
    this.aiDescription,
    this.annotation,
    this.latitude,
    this.longitude,
    this.address,
    this.compassHeading,
    this.sensorData,
    required this.sortOrder,
    required this.capturedAt,
    required this.createdAt,
    this.syncPending = false,
  });

  /// Unique identifier of the entry.
  final String id;

  /// ID of the report this entry belongs to.
  final String reportId;

  /// Type of entry (photo, video, audio, note, scan).
  final EntryType type;

  /// Local path to the media file (for photo, video, audio).
  final String? mediaPath;

  /// Local path to the thumbnail image.
  final String? thumbnailPath;

  /// Text content (for notes) or transcription (for audio).
  final String? content;

  /// AI-generated description.
  final String? aiDescription;

  /// User annotation/notes for this entry.
  final String? annotation;

  /// GPS latitude.
  final double? latitude;

  /// GPS longitude.
  final double? longitude;

  /// Reverse-geocoded address.
  final String? address;

  /// Compass heading at capture time.
  final double? compassHeading;

  /// JSON-encoded sensor data at capture time.
  final String? sensorData;

  /// Sort order within the report.
  final int sortOrder;

  /// Timestamp when the entry was captured.
  final DateTime capturedAt;

  /// Timestamp when the entry record was created.
  final DateTime createdAt;

  /// Whether this entry has pending changes to sync.
  final bool syncPending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          reportId == other.reportId &&
          type == other.type &&
          mediaPath == other.mediaPath &&
          thumbnailPath == other.thumbnailPath &&
          content == other.content &&
          aiDescription == other.aiDescription &&
          annotation == other.annotation &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          address == other.address &&
          compassHeading == other.compassHeading &&
          sensorData == other.sensorData &&
          sortOrder == other.sortOrder &&
          capturedAt == other.capturedAt &&
          createdAt == other.createdAt &&
          syncPending == other.syncPending;

  @override
  int get hashCode =>
      id.hashCode ^
      reportId.hashCode ^
      type.hashCode ^
      mediaPath.hashCode ^
      thumbnailPath.hashCode ^
      content.hashCode ^
      aiDescription.hashCode ^
      annotation.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      address.hashCode ^
      compassHeading.hashCode ^
      sensorData.hashCode ^
      sortOrder.hashCode ^
      capturedAt.hashCode ^
      createdAt.hashCode ^
      syncPending.hashCode;

  Entry copyWith({
    String? id,
    String? reportId,
    EntryType? type,
    String? mediaPath,
    String? thumbnailPath,
    String? content,
    String? aiDescription,
    String? annotation,
    double? latitude,
    double? longitude,
    String? address,
    double? compassHeading,
    String? sensorData,
    int? sortOrder,
    DateTime? capturedAt,
    DateTime? createdAt,
    bool? syncPending,
  }) {
    return Entry(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      type: type ?? this.type,
      mediaPath: mediaPath ?? this.mediaPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      content: content ?? this.content,
      aiDescription: aiDescription ?? this.aiDescription,
      annotation: annotation ?? this.annotation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      compassHeading: compassHeading ?? this.compassHeading,
      sensorData: sensorData ?? this.sensorData,
      sortOrder: sortOrder ?? this.sortOrder,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      syncPending: syncPending ?? this.syncPending,
    );
  }
}
