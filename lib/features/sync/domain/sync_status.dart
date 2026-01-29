import 'package:flutter/foundation.dart';

/// Represents the current synchronization status.
@immutable
sealed class SyncStatus {
  const SyncStatus();

  /// Creates a synced status (all items uploaded).
  const factory SyncStatus.synced() = SyncStatusSynced;

  /// Creates a pending status (items waiting to sync).
  const factory SyncStatus.pending({required int pendingCount}) =
      SyncStatusPending;

  /// Creates a syncing status (currently uploading).
  const factory SyncStatus.syncing({required double progress}) =
      SyncStatusSyncing;

  /// Creates an error status.
  const factory SyncStatus.error({required String message}) = SyncStatusError;
}

/// Fully synced status.
@immutable
class SyncStatusSynced extends SyncStatus {
  const SyncStatusSynced();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusSynced && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Items pending sync status.
@immutable
class SyncStatusPending extends SyncStatus {
  const SyncStatusPending({required this.pendingCount});

  /// Number of items pending sync.
  final int pendingCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusPending &&
          runtimeType == other.runtimeType &&
          pendingCount == other.pendingCount;

  @override
  int get hashCode => pendingCount.hashCode;
}

/// Currently syncing status.
@immutable
class SyncStatusSyncing extends SyncStatus {
  const SyncStatusSyncing({required this.progress});

  /// Sync progress from 0.0 to 1.0.
  final double progress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusSyncing &&
          runtimeType == other.runtimeType &&
          progress == other.progress;

  @override
  int get hashCode => progress.hashCode;
}

/// Sync error status.
@immutable
class SyncStatusError extends SyncStatus {
  const SyncStatusError({required this.message});

  /// Error message.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
