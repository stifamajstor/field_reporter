import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/edit_project_screen.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('Edit Project Flow', () {
    late List<Project> testProjects;
    late List<Project> updatedProjects;

    setUp(() {
      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Original Project Name',
          description: 'Original description',
          address: '123 Main St, New York',
          latitude: 40.7128,
          longitude: -74.0060,
          status: ProjectStatus.active,
          reportCount: 5,
          lastActivityAt: DateTime(2026, 1, 30, 10, 30),
        ),
      ];
      updatedProjects = [];
    });

    Widget createTestWidget({
      Widget? child,
      List<Project>? projects,
      void Function(Project)? onUpdateProject,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(
              projects: projects ?? testProjects,
              updatedProjects: updatedProjects,
              onUpdateProject: onUpdateProject,
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child ?? const ProjectDetailScreen(projectId: 'proj-1'),
          onGenerateRoute: (settings) {
            if (settings.name == '/projects/proj-1/edit') {
              return MaterialPageRoute(
                builder: (_) => const EditProjectScreen(projectId: 'proj-1'),
                settings: settings,
              );
            }
            if (settings.name?.startsWith('/projects/') ?? false) {
              final projectId = settings.name!.replaceFirst('/projects/', '');
              return MaterialPageRoute(
                builder: (_) => ProjectDetailScreen(projectId: projectId),
                settings: settings,
              );
            }
            return null;
          },
        ),
      );
    }

    testWidgets('Navigate to Project Detail screen and tap edit button',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify on project detail screen
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Original Project Name'), findsOneWidget);

      // Find and tap edit button (pencil icon)
      final editButton = find.byIcon(Icons.edit);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Verify edit form appears
      expect(find.byType(EditProjectScreen), findsOneWidget);
    });

    testWidgets('Edit form appears with current values', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const EditProjectScreen(projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Verify edit form shows current name
      expect(find.text('Original Project Name'), findsOneWidget);

      // Verify edit form shows current description
      expect(find.text('Original description'), findsOneWidget);

      // Verify screen title
      expect(find.text('Edit Project'), findsOneWidget);
    });

    testWidgets('Can modify project name', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const EditProjectScreen(projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Find the name field and clear it
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      expect(nameField, findsOneWidget);

      // Clear and enter new name
      await tester.enterText(nameField, '');
      await tester.pump();
      await tester.enterText(nameField, 'Updated Project Name');
      await tester.pump();

      // Verify new name is shown
      expect(find.text('Updated Project Name'), findsOneWidget);
    });

    testWidgets('Can modify project description', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const EditProjectScreen(projectId: 'proj-1'),
      ));
      await tester.pumpAndSettle();

      // Find the description field
      final descField = find.widgetWithText(TextFormField, 'Description');
      expect(descField, findsOneWidget);

      // Clear and enter new description
      await tester.enterText(descField, '');
      await tester.pump();
      await tester.enterText(descField, 'Updated description text');
      await tester.pump();

      // Verify new description is shown
      expect(find.text('Updated description text'), findsOneWidget);
    });

    testWidgets('Tap Save button saves changes', (tester) async {
      Project? savedProject;

      await tester.pumpWidget(createTestWidget(
        child: const EditProjectScreen(projectId: 'proj-1'),
        onUpdateProject: (project) {
          savedProject = project;
          updatedProjects.add(project);
        },
      ));
      await tester.pumpAndSettle();

      // Modify name
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'Updated Project Name');
      await tester.pump();

      // Modify description
      final descField = find.widgetWithText(TextFormField, 'Description');
      await tester.enterText(descField, 'Updated description');
      await tester.pump();

      // Find and tap Save button
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify changes were saved
      expect(savedProject, isNotNull);
      expect(savedProject!.name, equals('Updated Project Name'));
      expect(savedProject!.description, equals('Updated description'));
    });

    testWidgets(
        'After save, navigates back to detail screen with updated values',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        onUpdateProject: (project) {
          // Update testProjects so detail screen shows new values
          testProjects = [project];
          updatedProjects.add(project);
        },
      ));
      await tester.pumpAndSettle();

      // Navigate to edit screen
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Modify name and description
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'Updated Project Name');
      await tester.pump();

      final descField = find.widgetWithText(TextFormField, 'Description');
      await tester.enterText(descField, 'Updated description');
      await tester.pump();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify back on detail screen
      expect(find.byType(ProjectDetailScreen), findsOneWidget);

      // Verify updated values are displayed
      expect(find.text('Updated Project Name'), findsOneWidget);
      expect(find.text('Updated description'), findsOneWidget);
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  List<Project> projects;
  final List<Project> updatedProjects;
  final void Function(Project)? onUpdateProject;

  _MockProjectsNotifier({
    required this.projects,
    required this.updatedProjects,
    this.onUpdateProject,
  });

  @override
  Future<List<Project>> build() async {
    // Return updated projects if available
    if (updatedProjects.isNotEmpty) {
      return updatedProjects;
    }
    return projects;
  }

  @override
  Future<Project> updateProject(Project project) async {
    onUpdateProject?.call(project);
    // Update in place
    projects = projects.map((p) => p.id == project.id ? project : p).toList();
    ref.invalidateSelf();
    return project;
  }
}
