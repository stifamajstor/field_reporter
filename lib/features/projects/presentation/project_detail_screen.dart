import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../providers/projects_provider.dart';

/// Screen displaying project details.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (projects) {
          final project = projects.where((p) => p.id == projectId).firstOrNull;

          if (project == null) {
            return Center(
              child: Text(
                'Project not found',
                style: AppTypography.body1.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.slate700,
                ),
              ),
            );
          }

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Project name
              Text(
                project.name,
                style: AppTypography.headline1.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                ),
              ),
              AppSpacing.verticalSm,

              // Description
              if (project.description != null) ...[
                Text(
                  project.description!,
                  style: AppTypography.body1.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate700,
                  ),
                ),
                AppSpacing.verticalMd,
              ],

              // Location
              if (project.address != null) ...[
                Container(
                  padding: AppSpacing.cardInsets,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border:
                        isDark ? null : Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.slate400,
                      ),
                      AppSpacing.horizontalSm,
                      Expanded(
                        child: Text(
                          project.address!,
                          style: AppTypography.body2.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalMd,
              ],

              // Reports section
              Text(
                'Reports',
                style: AppTypography.headline3.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                ),
              ),
              AppSpacing.verticalSm,
              Text(
                '${project.reportCount} reports',
                style: AppTypography.body2.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.slate700,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
