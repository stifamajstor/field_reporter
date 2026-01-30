import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/presentation/widgets/project_map_view.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('ProjectsScreen Map View', () {
    late List<Project> testProjects;

    setUp(() {
      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Construction Site A',
          description: 'Main building',
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
          description: 'Renovation project',
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
          description: 'Inspection',
          address: '789 Industrial Blvd',
          latitude: 41.8781,
          longitude: -87.6298,
          status: ProjectStatus.archived,
          reportCount: 0,
          lastActivityAt: DateTime(2026, 1, 28, 8, 0),
        ),
        // Project without location - should not show marker
        Project(
          id: 'proj-4',
          name: 'Remote Project D',
          description: 'No location',
          status: ProjectStatus.active,
          reportCount: 2,
        ),
      ];
    });

    Widget createTestWidget({
      List<Project>? projects,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects ?? testProjects);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const ProjectsScreen(),
        ),
      );
    }

    testWidgets('tap Map View toggle button shows map view', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify Map View toggle button exists
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);

      // Tap Map View toggle
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      // Verify map view is displayed
      expect(find.byType(ProjectMapView), findsOneWidget);
    });

    testWidgets('map view displays markers for all projects with locations',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Map View toggle
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      // Verify map view is displayed
      expect(find.byType(ProjectMapView), findsOneWidget);

      // Verify markers for projects with locations (3 projects have locations)
      expect(find.byKey(const Key('project_marker_proj-1')), findsOneWidget);
      expect(find.byKey(const Key('project_marker_proj-2')), findsOneWidget);
      expect(find.byKey(const Key('project_marker_proj-3')), findsOneWidget);

      // Verify no marker for project without location
      expect(find.byKey(const Key('project_marker_proj-4')), findsNothing);
    });

    testWidgets('tap on marker shows project info popup', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Map View toggle
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      // Tap on a marker
      await tester.tap(find.byKey(const Key('project_marker_proj-1')));
      await tester.pumpAndSettle();

      // Verify project info popup appears
      expect(find.byKey(const Key('project_popup_proj-1')), findsOneWidget);
      expect(find.text('Construction Site A'), findsOneWidget);
      expect(find.text('123 Main St, New York'), findsOneWidget);
    });

    testWidgets('tap popup navigates to Project Detail', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Map View toggle
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      // Tap on a marker
      await tester.tap(find.byKey(const Key('project_marker_proj-1')));
      await tester.pumpAndSettle();

      // Tap on the popup
      await tester.tap(find.byKey(const Key('project_popup_proj-1')));
      await tester.pumpAndSettle();

      // Verify navigation to Project Detail screen
      expect(find.text('Project Details'), findsOneWidget);
    });

    testWidgets('toggle back to list view from map view', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Map View toggle
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      // Verify map view is displayed
      expect(find.byType(ProjectMapView), findsOneWidget);

      // Tap List View toggle (icon changes to list when in map view)
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // Verify back to list view
      expect(find.byType(ProjectMapView), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('map view shows empty state when no projects have locations',
        (tester) async {
      final projectsWithoutLocations = [
        Project(
          id: 'proj-1',
          name: 'Remote Project',
          description: 'No location',
          status: ProjectStatus.active,
        ),
      ];

      await tester
          .pumpWidget(createTestWidget(projects: projectsWithoutLocations));
      await tester.pumpAndSettle();

      // Tap Map View toggle
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();

      // Verify empty state message for no locations
      expect(find.text('No project locations'), findsOneWidget);
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;

  _MockProjectsNotifier({required this.projects});

  @override
  Future<List<Project>> build() async {
    return projects;
  }
}
