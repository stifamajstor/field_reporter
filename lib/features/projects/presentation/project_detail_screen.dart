import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../domain/project.dart';
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

              // Location section with map preview
              if (project.address != null) ...[
                _LocationSection(project: project, isDark: isDark),
                AppSpacing.verticalMd,
              ],

              // Reports section
              _ReportsSection(project: project, isDark: isDark),
              AppSpacing.verticalMd,

              // Team section
              _TeamSection(project: project, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.project,
    required this.isDark,
  });

  final Project project;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location card with address
        Container(
          padding: AppSpacing.cardInsets,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            border: isDark ? null : Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
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
        AppSpacing.verticalSm,

        // Map preview
        Container(
          key: const Key('project_map_preview'),
          height: 160,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
            borderRadius: AppSpacing.borderRadiusLg,
            border: isDark ? null : Border.all(color: AppColors.slate200),
          ),
          child: ClipRRect(
            borderRadius: AppSpacing.borderRadiusLg,
            child: Stack(
              children: [
                // Placeholder map background
                Container(
                  color:
                      isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                  child: Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 48,
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                ),
                // Location marker at center
                if (project.latitude != null && project.longitude != null)
                  Center(
                    child: Icon(
                      Icons.location_on,
                      size: 32,
                      color:
                          isDark ? AppColors.darkOrange : AppColors.orange500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection({
    required this.project,
    required this.isDark,
  });

  final Project project;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: AppTypography.headline3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        AppSpacing.verticalSm,
        Text(
          '${project.reportCount} reports',
          style: AppTypography.body2.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
          ),
        ),
        AppSpacing.verticalSm,
        // Reports list placeholder
        Container(
          key: const Key('project_reports_list'),
          padding: AppSpacing.cardInsets,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            border: isDark ? null : Border.all(color: AppColors.slate200),
          ),
          child: project.reportCount > 0
              ? Column(
                  children: List.generate(
                    project.reportCount > 3 ? 3 : project.reportCount,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index < 2 ? AppSpacing.sm : 0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.slate400,
                          ),
                          AppSpacing.horizontalSm,
                          Expanded(
                            child: Text(
                              'Report ${index + 1}',
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
                  ),
                )
              : Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No reports yet',
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.slate400,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({
    required this.project,
    required this.isDark,
  });

  final Project project;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team',
          style: AppTypography.headline3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        AppSpacing.verticalSm,
        Container(
          key: const Key('project_team_members'),
          padding: AppSpacing.cardInsets,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            border: isDark ? null : Border.all(color: AppColors.slate200),
          ),
          child: project.teamMembers.isNotEmpty
              ? Column(
                  children: project.teamMembers
                      .map(
                        (member) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isDark
                                    ? AppColors.darkSurfaceHigh
                                    : AppColors.slate200,
                                child: Text(
                                  member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : '?',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.slate700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AppSpacing.horizontalSm,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: AppTypography.body2.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.slate900,
                                      ),
                                    ),
                                    if (member.role != null)
                                      Text(
                                        member.role!,
                                        style: AppTypography.caption.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.slate400,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                )
              : Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No team members assigned',
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.slate400,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
