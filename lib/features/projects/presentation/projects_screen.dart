import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/layout/empty_state.dart';
import '../providers/projects_provider.dart';
import 'create_project_screen.dart';
import 'widgets/project_card.dart';

/// Screen displaying the list of all projects.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  void _navigateToCreateProject(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateProjectScreen(),
        settings: const RouteSettings(name: '/projects/create'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
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

          // Sort projects by most recent activity
          final sortedProjects = List.of(projects)
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
                  onTap: () {
                    // TODO: Navigate to project detail
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
