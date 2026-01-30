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
  group('Project creation handles network error', () {
    late List<Project> createdProjects;
    late bool isOnline;

    setUp(() {
      createdProjects = [];
      isOnline = false; // Start offline
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
          connectivityServiceProvider.overrideWithValue(
            _MockConnectivityService(() => isOnline),
          ),
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

    testWidgets('creates project with pending sync status when offline',
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

      // Step 2: Fill in required fields
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'Offline Project');
      await tester.pump();

      // Step 3: Network is already disconnected (isOnline = false)

      // Step 4: Tap 'Create' button
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Step 5-7: Verify project is created with pending sync status
      expect(createdProject, isNotNull);
      expect(createdProject!.name, equals('Offline Project'));
      expect(createdProject!.syncPending, isTrue);
    });

    testWidgets('creates project without pending sync status when online',
        (tester) async {
      isOnline = true; // Set online
      Project? createdProject;

      await tester.pumpWidget(createTestWidget(
        onCreateProject: (project) {
          createdProject = project;
          createdProjects.add(project);
        },
      ));
      await tester.pumpAndSettle();

      // Fill in required fields
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'Online Project');
      await tester.pump();

      // Tap 'Create' button
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify project is created without pending sync status
      expect(createdProject, isNotNull);
      expect(createdProject!.name, equals('Online Project'));
      expect(createdProject!.syncPending, isFalse);
    });

    testWidgets('offline project creation navigates to detail', (tester) async {
      await tester.pumpWidget(createTestWidget(
        onCreateProject: (project) {
          createdProjects.add(project);
        },
      ));
      await tester.pumpAndSettle();

      // Fill in project name
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'New Offline Project');
      await tester.pump();

      // Tap 'Create' button
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify navigation to project detail
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
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

/// Mock ConnectivityService for testing
class _MockConnectivityService extends ConnectivityService {
  final bool Function() _isOnline;

  _MockConnectivityService(this._isOnline);

  @override
  bool get isOnline => _isOnline();

  Stream<bool> get onConnectivityChanged => Stream.value(isOnline);
}
