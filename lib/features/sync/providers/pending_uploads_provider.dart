import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/pending_upload.dart';

part 'pending_uploads_provider.g.dart';

/// Provider for pending uploads queue.
@riverpod
class PendingUploadsNotifier extends _$PendingUploadsNotifier {
  @override
  Future<List<PendingUpload>> build() async {
    // Simulate loading pending uploads from local database
    await Future.delayed(const Duration(milliseconds: 100));

    // Return mock data for now - will be replaced with actual repository calls
    return [];
  }

  /// Refreshes the pending uploads list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
