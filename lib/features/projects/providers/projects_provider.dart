import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/project.dart';

part 'projects_provider.g.dart';

/// Provider for managing projects.
@riverpod
class ProjectsNotifier extends _$ProjectsNotifier {
  @override
  Future<List<Project>> build() async {
    // Simulate loading projects from local database/API
    await Future.delayed(const Duration(milliseconds: 100));

    // Return mock data for now - will be replaced with actual repository calls
    return const [
      Project(
        id: 'proj-1',
        name: 'Construction Site A',
        description: 'Main construction site',
      ),
      Project(
        id: 'proj-2',
        name: 'Office Building B',
        description: 'Office renovation project',
      ),
      Project(
        id: 'proj-3',
        name: 'Warehouse C',
        description: 'Warehouse inspection',
      ),
    ];
  }

  /// Refreshes the projects list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
