import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../services/connectivity_service.dart';
import '../../auth/domain/user.dart';
import '../../auth/providers/user_provider.dart';
import '../domain/project.dart';

part 'projects_provider.g.dart';

/// Provider for managing projects.
@riverpod
class ProjectsNotifier extends _$ProjectsNotifier {
  @override
  Future<List<Project>> build() async {
    // Simulate loading projects from local database/API
    await Future.delayed(const Duration(milliseconds: 100));

    // Return all projects - filtering is done by userVisibleProjectsProvider
    return [
      Project(
        id: 'proj-1',
        name: 'Construction Site A',
        description: 'Main construction site',
        address: '123 Main St, New York',
        latitude: 40.7128,
        longitude: -74.0060,
        status: ProjectStatus.active,
        reportCount: 5,
        lastActivityAt: DateTime(2026, 1, 30, 10, 30),
      ),
      Project(
        id: 'proj-2',
        name: 'Office Building B',
        description: 'Office renovation project',
        address: '456 Oak Ave, Boston',
        latitude: 42.3601,
        longitude: -71.0589,
        status: ProjectStatus.completed,
        reportCount: 12,
        lastActivityAt: DateTime(2026, 1, 29, 15, 45),
      ),
      Project(
        id: 'proj-3',
        name: 'Warehouse C',
        description: 'Warehouse inspection',
        address: '789 Industrial Blvd',
        latitude: 41.8781,
        longitude: -87.6298,
        status: ProjectStatus.archived,
        reportCount: 0,
        lastActivityAt: DateTime(2026, 1, 28, 8, 0),
      ),
    ];
  }

  /// Refreshes the projects list and syncs pending projects when online.
  Future<void> refresh() async {
    state = const AsyncLoading();

    // Check if online to sync pending projects
    final connectivityService = ref.read(connectivityServiceProvider);
    if (connectivityService.isOnline) {
      await syncPendingProjects();
    }

    state = await AsyncValue.guard(() => build());
  }

  /// Syncs projects with pending changes to the server.
  Future<void> syncPendingProjects() async {
    final currentProjects = state.valueOrNull ?? [];
    final pendingProjects = currentProjects.where((p) => p.syncPending);

    if (pendingProjects.isEmpty) return;

    // Mark all pending projects as synced (simulated sync)
    final syncedProjects = currentProjects.map((p) {
      if (p.syncPending) {
        return p.copyWith(syncPending: false);
      }
      return p;
    }).toList();

    state = AsyncData(syncedProjects);
  }

  /// Creates a new project.
  Future<Project> createProject(Project project) async {
    // Save to local storage (to be implemented with actual repository)
    // For now, add to the current list
    final currentProjects = state.valueOrNull ?? [];
    state = AsyncData([project, ...currentProjects]);
    return project;
  }

  /// Updates an existing project.
  Future<Project> updateProject(Project project) async {
    // Update in local storage (to be implemented with actual repository)
    final currentProjects = state.valueOrNull ?? [];
    final updatedProjects = currentProjects.map((p) {
      return p.id == project.id ? project : p;
    }).toList();
    state = AsyncData(updatedProjects);
    return project;
  }

  /// Deletes a project by ID.
  Future<void> deleteProject(String projectId) async {
    // Delete from local storage (to be implemented with actual repository)
    final currentProjects = state.valueOrNull ?? [];
    final updatedProjects =
        currentProjects.where((p) => p.id != projectId).toList();
    state = AsyncData(updatedProjects);
  }

  /// Adds a team member to a project.
  Future<void> addTeamMember(String projectId, TeamMember member) async {
    final currentProjects = state.valueOrNull ?? [];
    final updatedProjects = currentProjects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          teamMembers: [...p.teamMembers, member],
        );
      }
      return p;
    }).toList();
    state = AsyncData(updatedProjects);
  }

  /// Removes a team member from a project.
  Future<void> removeTeamMember(String projectId, String memberId) async {
    final currentProjects = state.valueOrNull ?? [];
    final updatedProjects = currentProjects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          teamMembers: p.teamMembers.where((m) => m.id != memberId).toList(),
        );
      }
      return p;
    }).toList();
    state = AsyncData(updatedProjects);
  }
}

/// Provider that returns projects visible to the current user.
/// Field workers only see projects they are assigned to.
/// Admins and managers see all projects.
@riverpod
FutureOr<List<Project>> userVisibleProjects(Ref ref) async {
  final allProjects = await ref.watch(projectsNotifierProvider.future);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  // Admins and managers can see all projects
  if (user.role == UserRole.admin || user.role == UserRole.manager) {
    return allProjects;
  }

  // Field workers only see projects they are assigned to
  return allProjects.where((project) {
    return project.teamMembers.any((member) => member.id == user.id);
  }).toList();
}
