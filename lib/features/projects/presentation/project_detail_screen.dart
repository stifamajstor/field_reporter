import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../reports/domain/report.dart';
import '../../reports/providers/reports_provider.dart';
import '../domain/project.dart';
import '../providers/projects_provider.dart';

/// Screen displaying project details.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteProjectDialog(project: project),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      await ref
          .read(projectsNotifierProvider.notifier)
          .deleteProject(projectId);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pushNamed('/projects/$projectId/edit');
            },
          ),
          Builder(
            builder: (context) {
              final project = projectsAsync.valueOrNull
                  ?.where((p) => p.id == projectId)
                  .firstOrNull;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete' && project != null) {
                    _showDeleteConfirmation(context, ref, project);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color:
                              isDark ? AppColors.darkRose : AppColors.rose500,
                          size: 20,
                        ),
                        AppSpacing.horizontalSm,
                        Text(
                          'Delete Project',
                          style: AppTypography.body2.copyWith(
                            color:
                                isDark ? AppColors.darkRose : AppColors.rose500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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

class _ReportsSection extends ConsumerWidget {
  const _ReportsSection({
    required this.project,
    required this.isDark,
  });

  final Project project;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(projectReportsNotifierProvider(project.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reports',
              style: AppTypography.headline3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushNamed(
                  '/reports/new',
                  arguments: {'projectId': project.id},
                );
              },
              icon: Icon(
                Icons.add,
                size: 18,
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
              label: Text(
                'New Report',
                style: AppTypography.button.copyWith(
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.verticalXs,
        Text(
          '${project.reportCount} reports',
          style: AppTypography.body2.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
          ),
        ),
        AppSpacing.verticalSm,
        // Reports list
        Container(
          key: const Key('project_reports_list'),
          padding: AppSpacing.cardInsets,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            border: isDark ? null : Border.all(color: AppColors.slate200),
          ),
          child: reportsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Error loading reports',
                  style: AppTypography.body2.copyWith(
                    color: isDark ? AppColors.darkRose : AppColors.rose500,
                  ),
                ),
              ),
            ),
            data: (reports) => reports.isEmpty
                ? Center(
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
                  )
                : Column(
                    children: reports.asMap().entries.map((entry) {
                      final index = entry.key;
                      final report = entry.value;
                      return _ReportListItem(
                        key: Key('project_report_item_$index'),
                        report: report,
                        isDark: isDark,
                        isLast: index == reports.length - 1,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pushNamed(
                            '/reports/${report.id}',
                          );
                        },
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ReportListItem extends StatelessWidget {
  const _ReportListItem({
    super.key,
    required this.report,
    required this.isDark,
    required this.isLast,
    required this.onTap,
  });

  final Report report;
  final bool isDark;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
        child: Row(
          children: [
            // Report icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 20,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
            ),
            AppSpacing.horizontalSm,
            // Report details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: AppTypography.body1.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy').format(report.createdAt),
                    style: AppTypography.mono.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            _ReportStatusBadge(status: report.status, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _ReportStatusBadge extends StatelessWidget {
  const _ReportStatusBadge({
    required this.status,
    required this.isDark,
  });

  final ReportStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor, label) = switch (status) {
      ReportStatus.draft => (
          isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
          isDark ? AppColors.darkTextSecondary : AppColors.slate700,
          'DRAFT',
        ),
      ReportStatus.processing => (
          isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
          isDark ? AppColors.darkAmber : AppColors.amber500,
          'PROCESSING',
        ),
      ReportStatus.complete => (
          isDark ? AppColors.darkEmeraldSubtle : AppColors.emerald50,
          isDark ? AppColors.darkEmerald : AppColors.emerald500,
          'COMPLETE',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
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

class _DeleteProjectDialog extends StatelessWidget {
  const _DeleteProjectDialog({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        'Delete Project?',
        style: AppTypography.headline3.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This action cannot be undone.',
            style: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
            ),
          ),
          if (project.reportCount > 0) ...[
            AppSpacing.verticalSm,
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkAmber : AppColors.amber500,
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      'This project has ${project.reportCount} reports that will also be deleted.',
                      style: AppTypography.body2.copyWith(
                        color:
                            isDark ? AppColors.darkAmber : AppColors.amber500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Delete',
            style: AppTypography.button.copyWith(
              color: isDark ? AppColors.darkRose : AppColors.rose500,
            ),
          ),
        ),
      ],
    );
  }
}
