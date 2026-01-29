import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A card that displays a statistic with a title and value.
///
/// Used on the Dashboard to show overview statistics like
/// 'Reports This Week', 'Pending Uploads', etc.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.onTap,
  });

  /// The label for this statistic.
  final String title;

  /// The numeric value to display.
  final String value;

  /// Optional icon to display.
  final IconData? icon;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border:
              isDark ? null : Border.all(color: AppColors.slate200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppSpacing.iconSize,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
              AppSpacing.verticalSm,
            ],
            Text(
              value,
              style: AppTypography.headline2.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
            AppSpacing.verticalXs,
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color:
                    isDark ? AppColors.darkTextSecondary : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
