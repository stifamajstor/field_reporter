import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../domain/entry.dart';

/// A card widget that displays an entry with thumbnail and timestamp.
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  /// The entry to display.
  final Entry entry;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when delete is requested.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final timeFormat = DateFormat('h:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: isDark ? null : Border.all(color: AppColors.slate200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            _EntryThumbnail(entry: entry, isDark: isDark),
            AppSpacing.horizontalSm,
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry type label
                  Row(
                    children: [
                      Icon(
                        _iconForType(entry.type),
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate700,
                      ),
                      AppSpacing.horizontalXs,
                      Text(
                        _labelForType(entry.type),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalXs,
                  // Timestamp and duration
                  Row(
                    children: [
                      Text(
                        timeFormat.format(entry.capturedAt),
                        style: AppTypography.mono.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400,
                        ),
                      ),
                      if (entry.durationSeconds != null) ...[
                        AppSpacing.horizontalSm,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceHigh
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(entry.durationSeconds!),
                            style: AppTypography.mono.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.slate400,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Annotation or content preview
                  if (entry.annotation != null || entry.content != null) ...[
                    AppSpacing.verticalXs,
                    Text(
                      entry.annotation ?? entry.content ?? '',
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(EntryType type) => switch (type) {
        EntryType.photo => Icons.photo,
        EntryType.video => Icons.videocam,
        EntryType.audio => Icons.mic,
        EntryType.note => Icons.note,
        EntryType.scan => Icons.qr_code_scanner,
      };

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _labelForType(EntryType type) => switch (type) {
        EntryType.photo => 'Photo',
        EntryType.video => 'Video',
        EntryType.audio => 'Voice Memo',
        EntryType.note => 'Note',
        EntryType.scan => 'Scan',
      };
}

class _EntryThumbnail extends StatelessWidget {
  const _EntryThumbnail({
    required this.entry,
    required this.isDark,
  });

  final Entry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: _buildThumbnailContent(),
      ),
    );
  }

  Widget _buildThumbnailContent() {
    // If we have a thumbnail path, show the image
    if (entry.thumbnailPath != null) {
      final file = File(entry.thumbnailPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
    }

    // If we have a media path for photo, show the image
    if (entry.type == EntryType.photo && entry.mediaPath != null) {
      final file = File(entry.mediaPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
    }

    // Otherwise show a placeholder icon
    return Container(
      color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
      child: Icon(
        _iconForType(entry.type),
        color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
        size: 28,
      ),
    );
  }

  IconData _iconForType(EntryType type) => switch (type) {
        EntryType.photo => Icons.photo,
        EntryType.video => Icons.videocam,
        EntryType.audio => Icons.mic,
        EntryType.note => Icons.note,
        EntryType.scan => Icons.qr_code_scanner,
      };
}
