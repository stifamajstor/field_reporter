import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('Create Project Flow', () {
    late List<Project> testProjects;
    late List<Project> createdProjects;

    setUp(() {
      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Existing Project',
          description: 'An existing project',
          address: '123 Main St',
          status: ProjectStatus.active,
          reportCount: 0,
          lastActivityAt: DateTime(2026, 1, 30),
        ),
      ];
      createdProjects = [];
    });

    Widget createTestWidget({
      Widget? child,
      List<Project>? projects,
      void Function(Project)? onCreateProject,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(
              projects: projects ?? testProjects,
              createdProjects: createdProjects,
              onCreateProject: onCreateProject,
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child ?? const ProjectsScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == '/projects/create') {
              return MaterialPageRoute(
                builder: (_) => const CreateProjectScreen(),
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

    testWidgets('can navigate to create project from Projects screen',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find and tap Create Project button or FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify project creation form appears
      expect(find.byType(CreateProjectScreen), findsOneWidget);
    });

    testWidgets('project creation form displays required fields',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify form fields are present
      expect(find.text('Create Project'), findsOneWidget); // Screen title
      expect(
          find.byType(TextFormField), findsAtLeast(2)); // Name and description

      // Verify name field
      expect(
          find.widgetWithText(TextFormField, 'Project Name'), findsOneWidget);

      // Verify description field
      expect(find.widgetWithText(TextFormField, 'Description'), findsOneWidget);

      // Verify location field exists
      expect(find.text('Location'), findsOneWidget);

      // Verify Create button exists
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('can enter project name and description', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Enter project name
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'New Test Project');
      await tester.pump();

      expect(find.text('New Test Project'), findsOneWidget);

      // Enter project description
      final descField = find.widgetWithText(TextFormField, 'Description');
      await tester.enterText(descField, 'This is a test project description');
      await tester.pump();

      expect(find.text('This is a test project description'), findsOneWidget);
    });

    testWidgets('tapping location field shows location picker', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Find and tap location field
      final locationField = find.text('Location');
      expect(locationField, findsOneWidget);

      await tester.tap(locationField);
      await tester.pumpAndSettle();

      // Verify location picker appears (modal or new screen)
      expect(find.byKey(const Key('location_picker')), findsOneWidget);
    });

    testWidgets('can select location via address search', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap location field to open picker
      await tester.tap(find.text('Location'));
      await tester.pumpAndSettle();

      // Find address search field in location picker
      final searchField = find.byKey(const Key('address_search_field'));
      expect(searchField, findsOneWidget);

      // Enter address
      await tester.enterText(searchField, '456 Oak Street, Boston');
      await tester.pumpAndSettle();

      // Verify a suggestion or select button appears
      // Use byWidgetPredicate to find the button specifically
      final selectButton = find.widgetWithText(
        GestureDetector,
        'Select Location',
      );
      expect(selectButton, findsOneWidget);

      await tester.tap(selectButton);
      await tester.pumpAndSettle();

      // Verify location is now set in the form
      expect(find.textContaining('456 Oak Street'), findsOneWidget);
    });

    testWidgets('can create project and navigate to detail', (tester) async {
      Project? createdProject;

      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
        onCreateProject: (project) {
          createdProject = project;
          createdProjects.add(project);
        },
      ));
      await tester.pumpAndSettle();

      // Fill in project name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name'),
        'My New Project',
      );
      await tester.pump();

      // Fill in description
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'A great new project',
      );
      await tester.pump();

      // Tap Create button
      final createButton = find.text('Create');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Verify project was created
      expect(createdProject, isNotNull);
      expect(createdProject!.name, equals('My New Project'));
      expect(createdProject!.description, equals('A great new project'));

      // Verify navigation to project detail
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
    });

    testWidgets('FAB shows add icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.child, isA<Icon>());
      expect((fab.child as Icon).icon, equals(Icons.add));
    });

    testWidgets('create button is disabled when name is empty', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Find Create button - should be disabled initially
      final createButtonFinder = find.text('Create');
      expect(createButtonFinder, findsOneWidget);

      // Try tapping the disabled button
      await tester.tap(createButtonFinder);
      await tester.pumpAndSettle();

      // Should still be on create screen (button was disabled)
      expect(find.byType(CreateProjectScreen), findsOneWidget);
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;
  final List<Project> createdProjects;
  final void Function(Project)? onCreateProject;

  _MockProjectsNotifier({
    required this.projects,
    required this.createdProjects,
    this.onCreateProject,
  });

  @override
  Future<List<Project>> build() async {
    return [...projects, ...createdProjects];
  }

  @override
  Future<Project> createProject(Project project) async {
    onCreateProject?.call(project);
    createdProjects.add(project);
    ref.invalidateSelf();
    return project;
  }
}
