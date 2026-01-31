import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/layout/empty_state.dart';
import '../../projects/domain/project.dart';
import '../../projects/providers/projects_provider.dart';
import '../domain/report.dart';
import '../providers/reports_provider.dart';

/// Provider for the current status filter.
final statusFilterProvider = StateProvider<ReportStatus?>((ref) => null);

/// Provider for the current project filter.
final projectFilterProvider = StateProvider<String?>((ref) => null);

/// Screen displaying the list of all reports.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(allReportsNotifierProvider);
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final projectFilter = ref.watch(projectFilterProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            key: const Key('filter_button'),
            icon: Icon(
              statusFilter != null || projectFilter != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            tooltip: 'Filter reports',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showFilterMenu(context, ref);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pushNamed('/reports/select-project');
        },
        backgroundColor: isDark ? AppColors.darkOrange : AppColors.orange500,
        tooltip: 'Create new report',
        child: Icon(
          Icons.add,
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
      ),
      body: reportsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: ErrorState(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(allReportsNotifierProvider),
          ),
        ),
        data: (reports) {
          // Apply status and project filters
          var filteredReports = reports;
          if (statusFilter != null) {
            filteredReports =
                filteredReports.where((r) => r.status == statusFilter).toList();
          }
          if (projectFilter != null) {
            filteredReports = filteredReports
                .where((r) => r.projectId == projectFilter)
                .toList();
          }

          if (filteredReports.isEmpty) {
            return const EmptyState(
              icon: Icons.description_outlined,
              title: 'No reports yet',
              description:
                  'Create your first report to document your findings.',
            );
          }

          // Get projects map for looking up project names
          final projectsMap = <String, Project>{};
          projectsAsync.whenData((projects) {
            for (final project in projects) {
              projectsMap[project.id] = project;
            }
          });

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allReportsNotifierProvider);
              await ref.read(allReportsNotifierProvider.future);
            },
            child: ListView.separated(
              padding: AppSpacing.listPadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              itemCount: filteredReports.length,
              separatorBuilder: (context, index) => AppSpacing.verticalSm,
              itemBuilder: (context, index) {
                final report = filteredReports[index];
                final project = projectsMap[report.projectId];

                return _ReportCard(
                  report: report,
                  projectName: project?.name ?? 'Unknown Project',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Navigate to report detail
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showFilterMenu(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsAsync = ref.read(projectsNotifierProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status filter section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Filter by Status',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('All'),
                    leading: const Icon(Icons.list),
                    onTap: () {
                      ref.read(statusFilterProvider.notifier).state = null;
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Draft'),
                    leading: const Icon(Icons.edit_outlined),
                    onTap: () {
                      ref.read(statusFilterProvider.notifier).state =
                          ReportStatus.draft;
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Processing'),
                    leading: const Icon(Icons.hourglass_empty),
                    onTap: () {
                      ref.read(statusFilterProvider.notifier).state =
                          ReportStatus.processing;
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Complete'),
                    leading: const Icon(Icons.check_circle_outline),
                    onTap: () {
                      ref.read(statusFilterProvider.notifier).state =
                          ReportStatus.complete;
                      Navigator.pop(context);
                    },
                  ),

                  // Project filter section
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Filter by Project',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    key: const Key('all_projects_filter'),
                    title: const Text('All Projects'),
                    leading: const Icon(Icons.folder_outlined),
                    onTap: () {
                      ref.read(projectFilterProvider.notifier).state = null;
                      Navigator.pop(context);
                    },
                  ),
                  ...projectsAsync.maybeWhen(
                    data: (projects) => projects.map(
                      (project) => ListTile(
                        key: Key('project_filter_${project.id}'),
                        title: Text(project.name),
                        leading: const Icon(Icons.folder),
                        onTap: () {
                          ref.read(projectFilterProvider.notifier).state =
                              project.id;
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    orElse: () => const [
                      ListTile(
                        title: Text('Loading projects...'),
                        leading: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card widget for displaying a report in the list.
class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.projectName,
    this.onTap,
  });

  final Report report;
  final String projectName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d');
    final displayDate = report.updatedAt ?? report.createdAt;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.horizontalSm,
                  _StatusBadge(status: report.status),
                ],
              ),
              AppSpacing.verticalSm,

              // Project name
              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                  AppSpacing.horizontalXs,
                  Expanded(
                    child: Text(
                      projectName,
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalXs,

              // Date and entry count row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                  AppSpacing.horizontalXs,
                  Text(
                    dateFormat.format(displayDate),
                    style: AppTypography.caption.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                  AppSpacing.horizontalMd,
                  Icon(
                    Icons.photo_library_outlined,
                    size: 14,
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                  AppSpacing.horizontalXs,
                  Text(
                    '${report.entryCount} entries',
                    style: AppTypography.caption.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge widget for displaying report status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final (color, bgColor, label) = switch (status) {
      ReportStatus.draft => (
          AppColors.warning(brightness),
          AppColors.warningBackground(brightness),
          'DRAFT',
        ),
      ReportStatus.processing => (
          AppColors.primary(brightness),
          AppColors.orange50,
          'PROCESSING',
        ),
      ReportStatus.complete => (
          AppColors.success(brightness),
          AppColors.successBackground(brightness),
          'COMPLETE',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
