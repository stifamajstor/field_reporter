import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../services/connectivity_service.dart';
import '../../../widgets/indicators/offline_indicator.dart';
import '../../../widgets/layout/empty_state.dart';
import '../domain/project.dart';
import '../providers/projects_provider.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import 'widgets/project_card.dart';
import 'widgets/project_filter_sheet.dart';
import 'widgets/project_map_view.dart';

/// Screen displaying the list of all projects.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  bool _isSearching = false;
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Set<ProjectStatus> _selectedStatuses = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedProjectsNotifierProvider.notifier).loadMore();
    }
  }

  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _toggleMapView() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  void _showFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProjectFilterSheet(
        selectedStatuses: _selectedStatuses,
        onApply: (statuses) {
          setState(() {
            _selectedStatuses = statuses;
          });
        },
      ),
    );
  }

  void _navigateToCreateProject(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateProjectScreen(),
        settings: const RouteSettings(name: '/projects/create'),
      ),
    );
  }

  void _navigateToProjectDetail(BuildContext context, Project project) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(projectId: project.id),
        settings: RouteSettings(name: '/projects/${project.id}'),
      ),
    );
  }

  List<Project> _filterProjects(List<Project> projects) {
    var filtered = projects;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        final name = project.name.toLowerCase();
        final description = project.description?.toLowerCase() ?? '';
        final address = project.address?.toLowerCase() ?? '';
        return name.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            address.contains(_searchQuery);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((project) {
        return _selectedStatuses.contains(project.status);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedProjectsNotifierProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    final isOnline = connectivityService.isOnline;
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                key: const Key('project_search_field'),
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: AppTypography.body1.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                ),
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle: AppTypography.body1.copyWith(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
              )
            : const Text('Projects'),
        actions: [
          if (!isOnline) const OfflineIndicator(),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map_outlined),
            onPressed: _toggleMapView,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedStatuses.isNotEmpty,
              label: Text(_selectedStatuses.length.toString()),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateProject(context),
        backgroundColor: isDark ? AppColors.darkOrange : AppColors.orange500,
        child: Icon(
          Icons.add,
          color: isDark ? AppColors.darkBackground : AppColors.white,
        ),
      ),
      body: paginatedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: ErrorState(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(paginatedProjectsNotifierProvider),
          ),
        ),
        data: (paginatedState) {
          final projects = paginatedState.projects;
          final filteredProjects = _filterProjects(projects);

          if (projects.isEmpty) {
            return EmptyState(
              icon: Icons.folder_outlined,
              title: 'No projects yet',
              description:
                  'Create your first project to start capturing reports.',
              actionLabel: 'Create Project',
              actionIcon: Icons.add,
              onAction: () => _navigateToCreateProject(context),
            );
          }

          if (filteredProjects.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No matches found',
              description: 'Try adjusting your search or filter criteria.',
            );
          }

          // Sort projects by most recent activity
          final sortedProjects = List.of(filteredProjects)
            ..sort((a, b) {
              final aTime = a.lastActivityAt ?? DateTime(1970);
              final bTime = b.lastActivityAt ?? DateTime(1970);
              return bTime.compareTo(aTime);
            });

          // Show map view or list view
          if (_isMapView) {
            return ProjectMapView(
              projects: sortedProjects,
              onProjectTap: (project) =>
                  _navigateToProjectDetail(context, project),
            );
          }

          // Calculate item count including loading indicator
          final itemCount = sortedProjects.length +
              (paginatedState.hasMore || paginatedState.isLoadingMore ? 1 : 0);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(paginatedProjectsNotifierProvider);
              await ref.read(paginatedProjectsNotifierProvider.future);
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: AppSpacing.listPadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              itemCount: itemCount,
              separatorBuilder: (context, index) => AppSpacing.verticalSm,
              itemBuilder: (context, index) {
                // Show loading indicator at the end
                if (index >= sortedProjects.length) {
                  return Center(
                    key: const Key('pagination_loading'),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: paginatedState.isLoadingMore
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final project = sortedProjects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => _navigateToProjectDetail(context, project),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
