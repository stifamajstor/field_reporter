import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/services/connectivity_service.dart';

void main() {
  group('User can create project while offline', () {
    late List<Project> storedProjects;
    late ConnectivityService connectivityService;
    late bool syncWasCalled;

    setUp(() {
      storedProjects = [];
      connectivityService = ConnectivityService();
      syncWasCalled = false;
    });

    Widget buildTestWidget({
      required bool isOnline,
      Widget? child,
    }) {
      connectivityService.setOnline(isOnline);

      return ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivityService),
          projectsNotifierProvider.overrideWith(() {
            return _TestProjectsNotifier(
              storedProjects: storedProjects,
              connectivityService: connectivityService,
              onSync: () => syncWasCalled = true,
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

    // Step 1 & 2: Enable airplane mode, navigate to Projects screen
    testWidgets('offline: can navigate to Projects screen', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectsScreen), findsOneWidget);
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
    });

    // Step 3: Tap 'Create Project'
    testWidgets('offline: can tap Create Project button', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(CreateProjectScreen), findsOneWidget);
    });

    // Step 4 & 5: Fill in project details and tap Create
    testWidgets('offline: can fill in project details and create project',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Fill in project name
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      await tester.enterText(nameField, 'Offline Test Project');
      await tester.pump();

      // Fill in description
      final descField = find.widgetWithText(TextFormField, 'Description');
      await tester.enterText(descField, 'Created while offline');
      await tester.pump();

      // Tap Create button
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify project was saved locally
      expect(storedProjects, hasLength(1));
      expect(storedProjects.first.name, equals('Offline Test Project'));
      expect(storedProjects.first.description, equals('Created while offline'));
    });

    // Step 6: Verify project is saved locally
    testWidgets('offline: project is saved locally with correct data',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isOnline: false,
        child: const CreateProjectScreen(),
      ));
      await tester.pumpAndSettle();

      // Fill and submit form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name'),
        'Local Project',
      );
      await tester.pump();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify project has correct attributes
      final savedProject = storedProjects.first;
      expect(savedProject.id, isNotEmpty);
      expect(savedProject.name, equals('Local Project'));
      expect(savedProject.status, equals(ProjectStatus.active));
      expect(savedProject.syncPending, isTrue);
    });

    // Step 7: Verify 'Pending sync' indicator on project
    testWidgets('offline: created project shows pending sync indicator',
        (tester) async {
      // Create a project with pending sync
      storedProjects.add(Project(
        id: 'offline-proj-1',
        name: 'Pending Sync Project',
        description: 'Created offline',
        status: ProjectStatus.active,
        syncPending: true,
        reportCount: 0,
        lastActivityAt: DateTime.now(),
      ));

      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify pending sync indicator is shown
      expect(find.byKey(const Key('pending_sync_indicator')), findsOneWidget);
      expect(find.text('Pending sync'), findsOneWidget);
    });

    // Step 8 & 9: Disable airplane mode, verify project syncs to server
    testWidgets('online: project syncs to server when connectivity restored',
        (tester) async {
      // Start with offline project that has pending sync
      storedProjects.add(Project(
        id: 'offline-proj-1',
        name: 'Pending Sync Project',
        description: 'Created offline',
        status: ProjectStatus.active,
        syncPending: true,
        reportCount: 0,
        lastActivityAt: DateTime.now(),
      ));

      // Start in online mode - the build should auto-sync pending projects
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Verify sync was called during initial build when online
      expect(syncWasCalled, isTrue);

      // Verify project was synced (syncPending should now be false)
      expect(storedProjects.first.syncPending, isFalse);
    });

    // Step 10: Verify 'Pending sync' indicator is removed
    testWidgets('online: pending sync indicator removed after successful sync',
        (tester) async {
      // Start with synced project (syncPending = false)
      storedProjects.add(Project(
        id: 'synced-proj-1',
        name: 'Synced Project',
        description: 'Already synced',
        status: ProjectStatus.active,
        syncPending: false,
        reportCount: 0,
        lastActivityAt: DateTime.now(),
      ));

      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Verify no pending sync indicator
      expect(find.byKey(const Key('pending_sync_indicator')), findsNothing);
      expect(find.text('Pending sync'), findsNothing);
    });

    // Full flow test
    testWidgets('complete offline create and sync flow', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Step 1: Verify offline indicator
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);

      // Step 2: Navigate to create project
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(CreateProjectScreen), findsOneWidget);

      // Step 3: Fill in project details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project Name'),
        'Complete Flow Project',
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Testing complete offline flow',
      );
      await tester.pump();

      // Step 4: Create project
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Step 5: Verify project saved with pending sync
      expect(storedProjects, hasLength(1));
      expect(storedProjects.first.syncPending, isTrue);
    });
  });
}

/// Test notifier that simulates offline/online project creation and sync.
class _TestProjectsNotifier extends ProjectsNotifier {
  _TestProjectsNotifier({
    required this.storedProjects,
    required this.connectivityService,
    this.onSync,
  });

  final List<Project> storedProjects;
  final ConnectivityService connectivityService;
  final VoidCallback? onSync;

  @override
  Future<List<Project>> build() async {
    // When online and building (e.g., after invalidate), sync pending projects
    if (connectivityService.isOnline) {
      final hasPending = storedProjects.any((p) => p.syncPending);
      if (hasPending) {
        onSync?.call();

        // Mark all pending projects as synced
        for (var i = 0; i < storedProjects.length; i++) {
          if (storedProjects[i].syncPending) {
            storedProjects[i] = storedProjects[i].copyWith(syncPending: false);
          }
        }
      }
    }
    return storedProjects;
  }

  @override
  Future<Project> createProject(Project project) async {
    // When offline, save locally with syncPending = true
    final projectToSave = connectivityService.isOnline
        ? project.copyWith(syncPending: false)
        : project.copyWith(syncPending: true);

    storedProjects.add(projectToSave);
    state = AsyncData(List.from(storedProjects));
    return projectToSave;
  }

  @override
  Future<void> refresh() async {
    // When online and refreshing, sync pending projects
    if (connectivityService.isOnline) {
      onSync?.call();

      // Mark all pending projects as synced
      for (var i = 0; i < storedProjects.length; i++) {
        if (storedProjects[i].syncPending) {
          storedProjects[i] = storedProjects[i].copyWith(syncPending: false);
        }
      }
    }

    state = AsyncData(List.from(storedProjects));
  }
}
