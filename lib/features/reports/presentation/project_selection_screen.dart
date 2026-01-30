import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../projects/domain/project.dart';
import '../../projects/providers/projects_provider.dart';
import '../domain/report.dart';

/// Screen for selecting a project when creating a new report.
class ProjectSelectionScreen extends ConsumerWidget {
  const ProjectSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Project'),
      ),
      body: projectsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading projects: $error'),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      size: 64,
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                    AppSpacing.verticalMd,
                    Text(
                      'No projects available',
                      style: AppTypography.headline3.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      ),
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      'Create a project first to start a report.',
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.listPadding.copyWith(
              top: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            itemCount: projects.length,
            separatorBuilder: (context, index) => AppSpacing.verticalSm,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _ProjectSelectionCard(
                project: project,
                onTap: () => _onProjectSelected(context, project),
              );
            },
          );
        },
      ),
    );
  }

  void _onProjectSelected(BuildContext context, Project project) {
    HapticFeedback.lightImpact();

    // Generate auto-title with date
    final today = DateFormat('MMM d, yyyy').format(DateTime.now());
    final title = 'Report - $today';

    // Create a new draft report
    final newReport = Report(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: project.id,
      title: title,
      status: ReportStatus.draft,
      createdAt: DateTime.now(),
    );

    // Navigate to Report Editor with the new report
    Navigator.of(context).pushReplacementNamed(
      '/reports/editor',
      arguments: {
        'projectId': project.id,
        'report': newReport,
      },
    );
  }
}

/// Card widget for displaying a project in the selection list.
class _ProjectSelectionCard extends StatelessWidget {
  const _ProjectSelectionCard({
    required this.project,
    this.onTap,
  });

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.slate200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLg,
        child: Padding(
          padding: AppSpacing.cardInsets,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  Icons.folder_outlined,
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (project.description != null &&
                        project.description!.isNotEmpty) ...[
                      AppSpacing.verticalXs,
                      Text(
                        project.description!,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
