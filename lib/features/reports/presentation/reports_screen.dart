import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../services/connectivity_service.dart';
import '../../../widgets/layout/empty_state.dart';
import '../../projects/domain/project.dart';
import '../../projects/providers/projects_provider.dart';
import '../domain/report.dart';
import '../providers/reports_provider.dart';

/// Provider for the current status filter.
final statusFilterProvider = StateProvider<ReportStatus?>((ref) => null);

/// Provider for the current project filter.
final projectFilterProvider = StateProvider<String?>((ref) => null);

/// Provider for the date range filter.
final dateRangeFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

/// Provider for the current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for whether search mode is active.
final isSearchActiveProvider = StateProvider<bool>((ref) => false);

/// Screen displaying the list of all reports.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(allReportsNotifierProvider);
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final projectFilter = ref.watch(projectFilterProvider);
    final dateRangeFilter = ref.watch(dateRangeFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearchActive = ref.watch(isSearchActiveProvider);
    final isDark = context.isDarkMode;
    final connectivityService = ref.watch(connectivityServiceProvider);
    final isOffline = !connectivityService.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: isSearchActive
            ? _SearchField(
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                onClear: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(isSearchActiveProvider.notifier).state = false;
                },
              )
            : const Text('Reports'),
        actions: isSearchActive
            ? null
            : [
                IconButton(
                  key: const Key('search_button'),
                  icon: const Icon(Icons.search),
                  tooltip: 'Search reports',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(isSearchActiveProvider.notifier).state = true;
                  },
                ),
                IconButton(
                  key: const Key('filter_button'),
                  icon: Icon(
                    statusFilter != null ||
                            projectFilter != null ||
                            dateRangeFilter != null
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
      body: Column(
        children: [
          // Offline indicator
          if (isOffline)
            Container(
              key: const Key('offline_indicator'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: isDark ? AppColors.darkAmber : AppColors.amber500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Offline mode',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkAmber : AppColors.amber500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: reportsAsync.when(
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
                // Apply status, project, and date range filters
                var filteredReports = reports;
                if (statusFilter != null) {
                  filteredReports = filteredReports
                      .where((r) => r.status == statusFilter)
                      .toList();
                }
                if (projectFilter != null) {
                  filteredReports = filteredReports
                      .where((r) => r.projectId == projectFilter)
                      .toList();
                }
                if (dateRangeFilter != null) {
                  filteredReports = filteredReports.where((r) {
                    final reportDate = r.createdAt;
                    return !reportDate.isBefore(dateRangeFilter.start) &&
                        !reportDate.isAfter(dateRangeFilter.end);
                  }).toList();
                }

                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  final query = searchQuery.toLowerCase();
                  filteredReports = filteredReports.where((r) {
                    final titleMatch = r.title.toLowerCase().contains(query);
                    final notesMatch =
                        r.notes?.toLowerCase().contains(query) ?? false;
                    return titleMatch || notesMatch;
                  }).toList();
                }

                // Show "No reports found" when search returns empty
                if (filteredReports.isEmpty && searchQuery.isNotEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No reports found',
                    description: 'Try a different search term.',
                  );
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
          ),
        ],
      ),
    );
  }

  void _showFilterMenu(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsAsync = ref.read(projectsNotifierProvider);
    final dateRangeFilter = ref.read(dateRangeFilterProvider);

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

                  // Date range filter section
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Filter by Date Range',
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
                    key: const Key('date_range_filter_option'),
                    title: Text(dateRangeFilter != null
                        ? '${DateFormat('MMM d').format(dateRangeFilter.start)} - ${DateFormat('MMM d').format(dateRangeFilter.end)}'
                        : 'Select Date Range'),
                    leading: const Icon(Icons.date_range),
                    onTap: () {
                      Navigator.pop(context);
                      _showDateRangePickerDialog(context, ref);
                    },
                  ),
                  if (dateRangeFilter != null)
                    ListTile(
                      key: const Key('clear_date_filter_option'),
                      title: const Text('Clear Date Filter'),
                      leading: const Icon(Icons.clear),
                      onTap: () {
                        ref.read(dateRangeFilterProvider.notifier).state = null;
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDateRangePickerDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              key: const Key('date_range_picker_dialog'),
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
              title: Text(
                'Select Date Range',
                style: AppTypography.headline3.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start date field
                  InkWell(
                    key: const Key('start_date_field'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.slate200,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate500,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            startDate != null
                                ? DateFormat('MMM d, yyyy').format(startDate!)
                                : 'Start Date',
                            style: AppTypography.body1.copyWith(
                              color: startDate != null
                                  ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.slate900)
                                  : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.slate400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // End date field
                  InkWell(
                    key: const Key('end_date_field'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.slate200,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate500,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            endDate != null
                                ? DateFormat('MMM d, yyyy').format(endDate!)
                                : 'End Date',
                            style: AppTypography.body1.copyWith(
                              color: endDate != null
                                  ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.slate900)
                                  : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.slate400),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate500,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('apply_date_filter_button'),
                  onPressed: startDate != null && endDate != null
                      ? () {
                          ref.read(dateRangeFilterProvider.notifier).state =
                              DateTimeRange(start: startDate!, end: endDate!);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      color: startDate != null && endDate != null
                          ? (isDark
                              ? AppColors.darkOrange
                              : AppColors.orange500)
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400),
                    ),
                  ),
                ),
              ],
            );
          },
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

/// Search field widget for the app bar.
class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.onChanged,
    required this.onClear,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus when search field appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      key: const Key('search_field'),
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      style: AppTypography.body1.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
      ),
      decoration: InputDecoration(
        hintText: 'Search reports...',
        hintStyle: AppTypography.body1.copyWith(
          color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
        ),
        border: InputBorder.none,
        suffixIcon: IconButton(
          key: const Key('clear_search_button'),
          icon: const Icon(Icons.close),
          onPressed: () {
            _controller.clear();
            widget.onClear();
          },
        ),
      ),
    );
  }
}
