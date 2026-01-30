import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/presentation/widgets/project_card.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/providers/reports_provider.dart';
import 'package:field_reporter/features/reports/domain/report.dart';
import 'package:field_reporter/services/connectivity_service.dart';

void main() {
  group('User can view cached projects when offline', () {
    /// Cached projects to display when offline.
    final cachedProjects = [
      Project(
        id: 'cached-proj-1',
        name: 'Cached Construction Site',
        description: 'Main building project',
        address: '123 Main St, New York',
        latitude: 40.7128,
        longitude: -74.0060,
        status: ProjectStatus.active,
        reportCount: 5,
        lastActivityAt: DateTime(2026, 1, 30, 10, 30),
      ),
      Project(
        id: 'cached-proj-2',
        name: 'Cached Office Building',
        description: 'Renovation project',
        address: '456 Oak Ave, Boston',
        latitude: 42.3601,
        longitude: -71.0589,
        status: ProjectStatus.completed,
        reportCount: 12,
        lastActivityAt: DateTime(2026, 1, 29, 15, 45),
      ),
      Project(
        id: 'cached-proj-3',
        name: 'Cached Warehouse',
        description: 'Inspection project',
        address: '789 Industrial Blvd',
        latitude: 41.8781,
        longitude: -87.6298,
        status: ProjectStatus.archived,
        reportCount: 3,
        lastActivityAt: DateTime(2026, 1, 28, 8, 0),
      ),
    ];

    const testUser = User(
      id: 'test-user-1',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.admin,
    );

    Widget buildTestWidget({
      required bool isOnline,
      List<Project>? projects,
    }) {
      final testProjects = projects ?? cachedProjects;
      final connectivityService = ConnectivityService()..setOnline(isOnline);

      return ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivityService),
          currentUserProvider.overrideWithValue(testUser),
          projectsNotifierProvider.overrideWith(() {
            return _TestProjectsNotifier(testProjects);
          }),
          userVisibleProjectsProvider.overrideWith((ref) async {
            return testProjects;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const ProjectsScreen(),
        ),
      );
    }

    Widget buildDetailTestWidget({
      required bool isOnline,
      required String projectId,
      List<Project>? projects,
    }) {
      final testProjects = projects ?? cachedProjects;
      final connectivityService = ConnectivityService()..setOnline(isOnline);

      return ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivityService),
          currentUserProvider.overrideWithValue(testUser),
          projectsNotifierProvider.overrideWith(() {
            return _TestProjectsNotifier(testProjects);
          }),
          projectReportsNotifierProvider(projectId).overrideWith(
            () => _TestProjectReportsNotifier([
              Report(
                id: 'report-1',
                projectId: projectId,
                title: 'Cached Report',
                status: ReportStatus.complete,
                createdAt: DateTime(2026, 1, 30),
                updatedAt: DateTime(2026, 1, 30),
              ),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ProjectDetailScreen(projectId: projectId),
        ),
      );
    }

    // Step 1 & 2: Navigate to Projects screen while online, view several projects
    testWidgets('Online: projects list is displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Verify projects are displayed
      expect(find.byType(ProjectCard), findsNWidgets(3));
      expect(find.text('Cached Construction Site'), findsOneWidget);
      expect(find.text('Cached Office Building'), findsOneWidget);
      expect(find.text('Cached Warehouse'), findsOneWidget);
    });

    // Step 3 & 4: Enable airplane mode, navigate to Projects screen
    testWidgets('Offline: cached projects are displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Step 5: Verify cached projects are displayed
      expect(find.byType(ProjectCard), findsNWidgets(3));
      expect(find.text('Cached Construction Site'), findsOneWidget);
      expect(find.text('Cached Office Building'), findsOneWidget);
      expect(find.text('Cached Warehouse'), findsOneWidget);
    });

    testWidgets('Offline: project details are shown correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify project addresses are shown
      expect(find.text('123 Main St, New York'), findsOneWidget);
      expect(find.text('456 Oak Ave, Boston'), findsOneWidget);

      // Verify report counts are shown
      expect(find.text('5 reports'), findsOneWidget);
      expect(find.text('12 reports'), findsOneWidget);

      // Verify status badges are shown
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);
    });

    // Step 6 & 7: Tap on cached project, verify Project Detail shows cached data
    testWidgets('Offline: tapping a project shows cached project detail',
        (tester) async {
      await tester.pumpWidget(buildDetailTestWidget(
        isOnline: false,
        projectId: 'cached-proj-1',
      ));
      await tester.pumpAndSettle();

      // Verify project name is displayed
      expect(find.text('Cached Construction Site'), findsOneWidget);

      // Verify project description is displayed
      expect(find.text('Main building project'), findsOneWidget);

      // Verify project address is displayed
      expect(find.text('123 Main St, New York'), findsOneWidget);
    });

    // Step 8: Verify offline indicator is visible
    testWidgets('Offline: offline indicator is visible on projects screen',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify offline indicator is shown
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('Offline: offline indicator is visible on project detail',
        (tester) async {
      await tester.pumpWidget(buildDetailTestWidget(
        isOnline: false,
        projectId: 'cached-proj-1',
      ));
      await tester.pumpAndSettle();

      // Verify offline indicator is shown
      expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('Online: offline indicator is NOT visible', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // Offline indicator should NOT be shown when online
      expect(find.byKey(const Key('offline_indicator')), findsNothing);
    });

    testWidgets('Offline: project cards remain interactive', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Verify project cards are still tappable
      final projectCard = find.byType(ProjectCard).first;
      final gestureDetector = find.descendant(
        of: projectCard,
        matching: find.byType(GestureDetector),
      );

      expect(
        gestureDetector.evaluate().isNotEmpty,
        isTrue,
        reason: 'Project cards should remain tappable when offline',
      );
    });

    testWidgets('Offline: search and filter still work', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Type search query
      await tester.enterText(
          find.byKey(const Key('project_search_field')), 'Construction');
      await tester.pumpAndSettle();

      // Verify filtering works offline
      expect(find.text('Cached Construction Site'), findsOneWidget);
      expect(find.text('Cached Office Building'), findsNothing);
    });
  });
}

/// Test notifier that returns preset projects (simulating cached data).
class _TestProjectsNotifier extends ProjectsNotifier {
  _TestProjectsNotifier(this._projects);

  final List<Project> _projects;

  @override
  Future<List<Project>> build() async {
    return _projects;
  }
}

/// Test notifier that returns preset project reports (simulating cached data).
class _TestProjectReportsNotifier extends ProjectReportsNotifier {
  _TestProjectReportsNotifier(this._reports);

  final List<Report> _reports;

  @override
  Future<List<Report>> build(String projectId) async {
    return _reports;
  }
}
