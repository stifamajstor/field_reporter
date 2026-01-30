import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/layout/empty_state.dart';
import '../domain/project.dart';
import '../providers/projects_provider.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';
import 'widgets/project_card.dart';
import 'widgets/project_filter_sheet.dart';

/// Screen displaying the list of all projects.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<ProjectStatus> _selectedStatuses = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final projectsAsync = ref.watch(projectsNotifierProvider);
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
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
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
      body: projectsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: ErrorState(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(projectsNotifierProvider),
          ),
        ),
        data: (projects) {
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

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(projectsNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: AppSpacing.listPadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              itemCount: sortedProjects.length,
              separatorBuilder: (context, index) => AppSpacing.verticalSm,
              itemBuilder: (context, index) {
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
