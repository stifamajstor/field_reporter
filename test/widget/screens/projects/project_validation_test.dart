import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('Project creation validates required fields', () {
    late List<Project> createdProjects;

    setUp(() {
      createdProjects = [];
    });

    Widget createTestWidget({
      void Function(Project)? onCreateProject,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(
              createdProjects: createdProjects,
              onCreateProject: onCreateProject,
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const CreateProjectScreen(),
          onGenerateRoute: (settings) {
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

    testWidgets(
        'shows validation error when submitting empty name, then creates project after entering name',
        (tester) async {
      Project? createdProject;

      await tester.pumpWidget(createTestWidget(
        onCreateProject: (project) {
          createdProject = project;
          createdProjects.add(project);
        },
      ));
      await tester.pumpAndSettle();

      // Step 1: Navigate to create project form (already there)
      expect(find.byType(CreateProjectScreen), findsOneWidget);

      // Step 2: Leave project name empty (it's already empty)
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      expect(nameField, findsOneWidget);

      // Step 3: Tap 'Create' button
      final createButton = find.text('Create');
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Step 4: Verify validation error for project name
      expect(find.text('Project name is required'), findsOneWidget);

      // Should still be on create screen
      expect(find.byType(CreateProjectScreen), findsOneWidget);
      expect(createdProject, isNull);

      // Step 5: Enter project name
      await tester.enterText(nameField, 'My Valid Project');
      await tester.pump();

      // Step 6: Tap 'Create' button again
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Step 7: Verify project is created successfully
      expect(createdProject, isNotNull);
      expect(createdProject!.name, equals('My Valid Project'));

      // Verify navigation to project detail
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
    });

    testWidgets('validation error disappears when user enters text',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap create with empty name to trigger validation error
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Project name is required'), findsOneWidget);

      // Enter text in name field
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'A');
      await tester.pump();

      // Validation error should be cleared
      expect(find.text('Project name is required'), findsNothing);
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> createdProjects;
  final void Function(Project)? onCreateProject;

  _MockProjectsNotifier({
    required this.createdProjects,
    this.onCreateProject,
  });

  @override
  Future<List<Project>> build() async {
    return createdProjects;
  }

  @override
  Future<Project> createProject(Project project) async {
    onCreateProject?.call(project);
    createdProjects.add(project);
    ref.invalidateSelf();
    return project;
  }
}
