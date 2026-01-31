import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share_service.g.dart';

/// Service for sharing files via the native share sheet.
abstract class ShareService {
  /// Shares a file via the native share sheet.
  ///
  /// Returns true if the share sheet was shown successfully.
  Future<bool> shareFile({
    required String filePath,
    String? mimeType,
    String? subject,
    String? text,
  });
}

/// Default implementation using share_plus.
class DefaultShareService implements ShareService {
  @override
  Future<bool> shareFile({
    required String filePath,
    String? mimeType,
    String? subject,
    String? text,
  }) async {
    final file = XFile(filePath, mimeType: mimeType);

    final result = await Share.shareXFiles(
      [file],
      subject: subject,
      text: text,
    );

    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  }
}

/// Provider for the share service.
@riverpod
ShareService shareService(Ref ref) {
  return DefaultShareService();
}
