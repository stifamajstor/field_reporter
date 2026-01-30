import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/presentation/widgets/project_card.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('Project Detail Screen', () {
    late List<Project> testProjects;

    setUp(() {
      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Construction Site Alpha',
          description: 'A large construction project for a new office building',
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
      ];
    });

    Widget createProjectsScreen({List<Project>? projects}) {
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

    Widget createProjectDetailScreen({
      required String projectId,
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
          home: ProjectDetailScreen(projectId: projectId),
        ),
      );
    }

    testWidgets('navigates to Project Detail screen when tapping on a project',
        (tester) async {
      await tester.pumpWidget(createProjectsScreen());
      await tester.pumpAndSettle();

      // Verify projects list is displayed
      expect(find.byType(ProjectCard), findsNWidgets(2));

      // Tap on the first project
      await tester.tap(find.text('Construction Site Alpha'));
      await tester.pumpAndSettle();

      // Verify Project Detail screen opened
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
    });

    testWidgets('displays project name in header', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify project name is displayed prominently
      expect(find.text('Construction Site Alpha'), findsOneWidget);
    });

    testWidgets('displays project description', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify description is shown
      expect(
        find.text('A large construction project for a new office building'),
        findsOneWidget,
      );
    });

    testWidgets('displays location with map preview', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify address is shown
      expect(find.text('123 Main St, New York'), findsOneWidget);

      // Verify map preview exists (looking for the map container)
      expect(find.byKey(const Key('project_map_preview')), findsOneWidget);
    });

    testWidgets('displays list of reports for this project', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify Reports section header
      expect(find.text('Reports'), findsOneWidget);

      // Verify report count is shown
      expect(find.text('5 reports'), findsOneWidget);

      // Verify report list section exists
      expect(find.byKey(const Key('project_reports_list')), findsOneWidget);
    });

    testWidgets('displays team members assigned to project', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Scroll down to make Team section visible
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Verify Team section header
      expect(find.text('Team'), findsOneWidget);

      // Verify team members section exists
      expect(find.byKey(const Key('project_team_members')), findsOneWidget);
    });

    testWidgets('shows project not found message for invalid project id',
        (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'invalid'));
      await tester.pumpAndSettle();

      // Verify not found message
      expect(find.text('Project not found'), findsOneWidget);
    });

    testWidgets('shows location icon with address', (tester) async {
      await tester.pumpWidget(createProjectDetailScreen(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify location icon is present
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    group('Delete Project', () {
      testWidgets('can delete a project via more options menu', (tester) async {
        final deletedProjects = <String>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              projectsNotifierProvider.overrideWith(() {
                return _MockProjectsNotifierWithDelete(
                  projects: testProjects,
                  onDelete: (id) => deletedProjects.add(id),
                );
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: const ProjectsScreen(),
              onGenerateRoute: (settings) {
                if (settings.name == '/projects') {
                  return MaterialPageRoute(
                    builder: (_) => const ProjectsScreen(),
                  );
                }
                return null;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to Project Detail screen
        await tester.tap(find.text('Construction Site Alpha'));
        await tester.pumpAndSettle();

        // Verify we're on the detail screen
        expect(find.byType(ProjectDetailScreen), findsOneWidget);

        // Tap more options menu (three dots)
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Select 'Delete Project'
        await tester.tap(find.text('Delete Project'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(find.text('Delete Project?'), findsOneWidget);

        // Verify warning about associated reports in dialog
        expect(
          find.textContaining('will also be deleted'),
          findsOneWidget,
        );

        // Confirm deletion
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Verify project is deleted
        expect(deletedProjects, contains('proj-1'));

        // Verify navigation back to Projects list
        expect(find.byType(ProjectsScreen), findsOneWidget);

        // Verify deleted project no longer appears
        expect(find.text('Construction Site Alpha'), findsNothing);
      });

      testWidgets('can cancel project deletion', (tester) async {
        final deletedProjects = <String>[];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              projectsNotifierProvider.overrideWith(() {
                return _MockProjectsNotifierWithDelete(
                  projects: testProjects,
                  onDelete: (id) => deletedProjects.add(id),
                );
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: const ProjectDetailScreen(projectId: 'proj-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap more options menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Select 'Delete Project'
        await tester.tap(find.text('Delete Project'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(find.text('Delete Project?'), findsOneWidget);

        // Cancel deletion
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify project is NOT deleted
        expect(deletedProjects, isEmpty);

        // Verify we're still on the detail screen
        expect(find.byType(ProjectDetailScreen), findsOneWidget);
      });

      testWidgets('shows warning for project with no reports', (tester) async {
        final projectWithNoReports = [
          Project(
            id: 'proj-empty',
            name: 'Empty Project',
            description: 'No reports',
            status: ProjectStatus.active,
            reportCount: 0,
            lastActivityAt: DateTime(2026, 1, 30),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              projectsNotifierProvider.overrideWith(() {
                return _MockProjectsNotifierWithDelete(
                  projects: projectWithNoReports,
                  onDelete: (_) {},
                );
              }),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              home: const ProjectDetailScreen(projectId: 'proj-empty'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap more options menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Select 'Delete Project'
        await tester.tap(find.text('Delete Project'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears with appropriate message
        expect(find.text('Delete Project?'), findsOneWidget);
        expect(find.textContaining('cannot be undone'), findsOneWidget);
      });
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

/// Mock ProjectsNotifier that supports delete operations
class _MockProjectsNotifierWithDelete extends ProjectsNotifier {
  List<Project> _projects;
  final void Function(String) onDelete;

  _MockProjectsNotifierWithDelete({
    required List<Project> projects,
    required this.onDelete,
  }) : _projects = List.from(projects);

  @override
  Future<List<Project>> build() async {
    return _projects;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    onDelete(projectId);
    _projects = _projects.where((p) => p.id != projectId).toList();
    state = AsyncData(_projects);
  }
}
