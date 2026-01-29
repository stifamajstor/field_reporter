import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/dashboard/domain/recent_report.dart';

/// A card that displays a report summary.
///
/// Shows the report title, project name, date, and status indicator.
/// Used in the Recent Reports section on the Dashboard.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  /// The report data to display.
  final RecentReport report;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report icon
            Container(
              width: AppSpacing.thumbnailSm,
              height: AppSpacing.thumbnailSm,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(
                Icons.description_outlined,
                size: AppSpacing.iconSize,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
            ),
            AppSpacing.horizontalMd,
            // Report details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    report.title,
                    style: AppTypography.headline3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.verticalXs,
                  // Project name
                  Text(
                    report.projectName,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.verticalXs,
                  // Date and status row
                  Row(
                    children: [
                      // Date
                      Text(
                        DateFormat('MMM d, yyyy').format(report.date),
                        style: AppTypography.mono.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400,
                        ),
                      ),
                      const Spacer(),
                      // Status indicator
                      _StatusBadge(status: report.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A badge showing the report status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final (backgroundColor, textColor, label) = switch (status) {
      ReportStatus.complete => (
          isDark ? AppColors.darkEmeraldSubtle : AppColors.emerald50,
          isDark ? AppColors.darkEmerald : AppColors.emerald500,
          'COMPLETE',
        ),
      ReportStatus.processing => (
          isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
          isDark ? AppColors.darkAmber : AppColors.amber500,
          'PROCESSING',
        ),
      ReportStatus.draft => (
          isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
          isDark ? AppColors.darkTextSecondary : AppColors.slate700,
          'DRAFT',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(color: textColor),
      ),
    );
  }
}
