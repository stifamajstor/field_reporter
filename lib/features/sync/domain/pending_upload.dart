import 'package:flutter/foundation.dart';

/// Status of a pending upload.
enum UploadStatus {
  /// Upload is waiting in queue.
  pending,

  /// Upload is currently in progress.
  uploading,

  /// Upload completed successfully.
  completed,

  /// Upload failed.
  failed,
}

/// Represents an item pending upload to the server.
@immutable
class PendingUpload {
  const PendingUpload({
    required this.id,
    required this.entryId,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    required this.status,
    this.progress = 0.0,
  });

  /// Unique identifier of the pending upload.
  final String id;

  /// ID of the entry this upload belongs to.
  final String entryId;

  /// Name of the file being uploaded.
  final String fileName;

  /// Size of the file in bytes.
  final int fileSize;

  /// When the upload was queued.
  final DateTime createdAt;

  /// Current status of the upload.
  final UploadStatus status;

  /// Upload progress from 0.0 to 1.0.
  final double progress;

  /// Creates a copy with updated values.
  PendingUpload copyWith({
    String? id,
    String? entryId,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    UploadStatus? status,
    double? progress,
  }) {
    return PendingUpload(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingUpload &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          entryId == other.entryId &&
          fileName == other.fileName &&
          fileSize == other.fileSize &&
          createdAt == other.createdAt &&
          status == other.status &&
          progress == other.progress;

  @override
  int get hashCode =>
      id.hashCode ^
      entryId.hashCode ^
      fileName.hashCode ^
      fileSize.hashCode ^
      createdAt.hashCode ^
      status.hashCode ^
      progress.hashCode;
}
