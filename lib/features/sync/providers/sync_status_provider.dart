import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/pending_upload.dart';
import '../domain/sync_status.dart';
import 'pending_uploads_provider.dart';

part 'sync_status_provider.g.dart';

/// Provider for the overall sync status.
@riverpod
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncStatus build() {
    // Watch pending uploads to derive sync status
    final pendingUploadsAsync = ref.watch(pendingUploadsNotifierProvider);

    return pendingUploadsAsync.when(
      data: (uploads) {
        if (uploads.isEmpty) {
          return const SyncStatus.synced();
        }

        // Check if any are actively syncing
        final activeUploads =
            uploads.where((u) => u.status == UploadStatus.uploading).toList();
        if (activeUploads.isNotEmpty) {
          final totalProgress = activeUploads.fold<double>(
            0.0,
            (sum, u) => sum + u.progress,
          );
          return SyncStatus.syncing(
            progress: totalProgress / activeUploads.length,
          );
        }

        // Otherwise, items are pending
        return SyncStatus.pending(pendingCount: uploads.length);
      },
      loading: () => const SyncStatus.synced(),
      error: (e, _) => SyncStatus.error(message: e.toString()),
    );
  }

  /// Manually triggers a sync refresh.
  void refresh() {
    ref.invalidateSelf();
  }
}
