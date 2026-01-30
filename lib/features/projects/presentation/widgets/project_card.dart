import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../widgets/indicators/status_badge.dart';
import '../../domain/project.dart';

/// A card displaying project information in a list.
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  /// The project to display.
  final Project project;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Semantics(
      label: '${project.name}, ${project.address ?? 'No location'}, '
          '${project.reportCount} reports, ${_statusLabel(project.status)}',
      button: onTap != null,
      child: GestureDetector(
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
            border: isDark ? null : Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Name and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: AppTypography.headline3.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.horizontalSm,
                  StatusBadge(
                    label: _statusLabel(project.status),
                    type: _statusType(project.status),
                  ),
                ],
              ),
              AppSpacing.verticalSm,

              // Location row
              if (project.address != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                    AppSpacing.horizontalXs,
                    Expanded(
                      child: Text(
                        project.address!,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalXs,
              ],

              // Report count row
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                  AppSpacing.horizontalXs,
                  Text(
                    '${project.reportCount} reports',
                    style: AppTypography.caption.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                ],
              ),

              // Pending sync indicator
              if (project.syncPending) ...[
                AppSpacing.verticalSm,
                Row(
                  key: const Key('pending_sync_indicator'),
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 16,
                      color: isDark ? AppColors.darkAmber : AppColors.amber500,
                    ),
                    AppSpacing.horizontalXs,
                    Text(
                      'Pending sync',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? AppColors.darkAmber : AppColors.amber500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.active => 'ACTIVE',
      ProjectStatus.completed => 'COMPLETED',
      ProjectStatus.archived => 'ARCHIVED',
    };
  }

  StatusType _statusType(ProjectStatus status) {
    return switch (status) {
      ProjectStatus.active => StatusType.success,
      ProjectStatus.completed => StatusType.neutral,
      ProjectStatus.archived => StatusType.warning,
    };
  }
}
