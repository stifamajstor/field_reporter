import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/timestamp_overlay_provider.dart';

/// Arguments for the photo preview screen.
class PhotoPreviewArguments {
  const PhotoPreviewArguments({
    required this.photoPath,
    this.capturedTimestamp,
  });

  /// Path to the captured photo file.
  final String photoPath;

  /// Timestamp when photo was captured.
  final DateTime? capturedTimestamp;
}

/// Screen that displays the captured photo with accept/retake options.
class PhotoPreviewScreen extends ConsumerWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.arguments,
  });

  final PhotoPreviewArguments arguments;

  String _formatTimestamp(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-'
        '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timestampState = ref.watch(timestampOverlayProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo preview
          _buildPhotoPreview(),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retake button
                    _buildRetakeButton(context),
                    const SizedBox(width: 24),
                    // Accept button
                    _buildAcceptButton(context),
                  ],
                ),
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Timestamp overlay on preview
          if (timestampState.isEnabled && arguments.capturedTimestamp != null)
            Positioned(
              right: 16,
              bottom: 120,
              child: Container(
                key: const Key('preview_timestamp_overlay'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(arguments.capturedTimestamp!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    final file = File(arguments.photoPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }
    // Fallback for tests where file doesn't exist
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.image,
          color: AppColors.slate400,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildRetakeButton(BuildContext context) {
    return GestureDetector(
      key: const Key('retake_photo_button'),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(PhotoPreviewResult.retake);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Retake',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return GestureDetector(
      key: const Key('accept_photo_button'),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(PhotoPreviewResult.accept);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.orange500,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Accept',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result from the photo preview screen.
enum PhotoPreviewResult {
  accept,
  retake,
}
