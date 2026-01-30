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

  /// Refreshes the projects list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
