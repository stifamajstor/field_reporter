import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A widget that indicates the app is currently offline.
///
/// Displays a cloud_off icon with "Offline" text in a styled container.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('offline_indicator'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 20,
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Offline',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
