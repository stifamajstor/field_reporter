import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A widget that indicates data may be stale with a timestamp.
///
/// Displays a schedule icon with "Last updated X ago" text when the app
/// is offline and showing cached data.
class StaleDataIndicator extends StatelessWidget {
  const StaleDataIndicator({
    super.key,
    required this.lastUpdated,
  });

  /// The timestamp when the data was last updated.
  final DateTime lastUpdated;

  /// Formats the duration since last update as a human-readable string.
  String _formatTimeSince(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 2) {
      return 'Last updated 1 minute ago';
    } else if (difference.inMinutes < 60) {
      return 'Last updated ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 2) {
      return 'Last updated 1 hour ago';
    } else if (difference.inHours < 24) {
      return 'Last updated ${difference.inHours} hours ago';
    } else if (difference.inDays < 2) {
      return 'Last updated 1 day ago';
    } else {
      return 'Last updated ${difference.inDays} days ago';
    }
  }

  /// Returns true if the data is considered "stale" (30+ minutes old).
  bool get _isStale {
    final difference = DateTime.now().difference(lastUpdated);
    return difference.inMinutes >= 30;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStale = _isStale;

    // Use amber/warning color for stale data, slate for recent data
    final iconColor = isStale
        ? (isDark ? AppColors.darkAmber : AppColors.amber500)
        : (isDark ? AppColors.darkTextMuted : AppColors.slate400);
    final textColor = isStale
        ? (isDark ? AppColors.darkAmber : AppColors.amber500)
        : (isDark ? AppColors.darkTextMuted : AppColors.slate400);
    final backgroundColor = isStale
        ? (isDark ? AppColors.darkAmberSubtle : AppColors.amber50)
        : (isDark ? AppColors.darkSurface : AppColors.slate100);

    return Container(
      key: const Key('stale_data_indicator'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _formatTimeSince(lastUpdated),
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
