import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/services/connectivity_service.dart';

void main() {
  group('Duplicate project name shows appropriate error', () {
    late List<Project> existingProjects;

    setUp(() {
      existingProjects = [
        Project(
          id: 'proj-existing',
          name: 'Test Project',
          status: ProjectStatus.active,
          lastActivityAt: DateTime(2026, 1, 30),
        ),
      ];
    });

    Widget createTestWidget({
      required List<Project> projects,
      void Function(Project)? onCreateProject,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(
              projects: projects,
              onCreateProject: onCreateProject,
            );
          }),
          connectivityServiceProvider.overrideWithValue(
            _MockConnectivityService(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              // Pre-watch the provider to ensure it's loaded
              return Consumer(
                builder: (context, ref, _) {
                  // Force provider initialization before showing screen
                  ref.watch(projectsNotifierProvider);
                  return const CreateProjectScreen();
                },
              );
            },
          ),
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

    testWidgets('shows error when creating project with duplicate name',
        (tester) async {
      await tester.pumpWidget(createTestWidget(projects: existingProjects));
      await tester.pumpAndSettle();

      // Step 1: Verify existing project 'Test Project' exists
      // (mocked in setup)

      // Step 2: Navigate to create project form (already there)
      expect(find.byType(CreateProjectScreen), findsOneWidget);

      // Step 3: Enter 'Test Project' as name (duplicate)
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'Test Project');
      await tester.pump();

      // Step 4: Tap 'Create'
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Step 5: Verify error message about duplicate name
      expect(
          find.text('A project with this name already exists'), findsOneWidget);
    });

    testWidgets('creates successfully after modifying duplicate name',
        (tester) async {
      Project? createdProject;

      await tester.pumpWidget(createTestWidget(
        projects: existingProjects,
        onCreateProject: (project) {
          createdProject = project;
          existingProjects.add(project);
        },
      ));
      await tester.pumpAndSettle();

      // Enter duplicate name
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'Test Project');
      await tester.pump();

      // Tap 'Create' - should show error
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(
          find.text('A project with this name already exists'), findsOneWidget);

      // Step 6: Modify name slightly
      await tester.enterText(nameField, 'Test Project 2');
      await tester.pump();

      // Verify error is cleared when name changes
      expect(
          find.text('A project with this name already exists'), findsNothing);

      // Step 7: Tap 'Create' again
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Step 8: Verify project creates successfully
      expect(createdProject, isNotNull);
      expect(createdProject!.name, equals('Test Project 2'));

      // Verify navigation to detail screen
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
    });

    testWidgets('duplicate check is case-insensitive', (tester) async {
      await tester.pumpWidget(createTestWidget(projects: existingProjects));
      await tester.pumpAndSettle();

      // Enter same name with different case
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'test project');
      await tester.pump();

      // Tap 'Create'
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify error message (case-insensitive duplicate detection)
      expect(
          find.text('A project with this name already exists'), findsOneWidget);
    });

    testWidgets('duplicate check trims whitespace', (tester) async {
      await tester.pumpWidget(createTestWidget(projects: existingProjects));
      await tester.pumpAndSettle();

      // Enter name with extra whitespace
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, '  Test Project  ');
      await tester.pump();

      // Tap 'Create'
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify error message (whitespace-trimmed duplicate detection)
      expect(
          find.text('A project with this name already exists'), findsOneWidget);
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> _initialProjects;
  final void Function(Project)? onCreateProject;

  _MockProjectsNotifier({
    required List<Project> projects,
    this.onCreateProject,
  }) : _initialProjects = List.from(projects);

  @override
  Future<List<Project>> build() async {
    // Return immediately without delay to ensure state is ready
    return _initialProjects;
  }

  @override
  Future<Project> createProject(Project project) async {
    onCreateProject?.call(project);
    _initialProjects.add(project);
    state = AsyncData(List.from(_initialProjects));
    return project;
  }
}

/// Mock ConnectivityService for testing
class _MockConnectivityService extends ConnectivityService {
  @override
  bool get isOnline => true;

  Stream<bool> get onConnectivityChanged => Stream.value(true);
}
