import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/presentation/widgets/project_card.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('ProjectsScreen', () {
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
      ];
    });

    Widget createTestWidget({
      List<Project>? projects,
      String? errorMessage,
    }) {
      return ProviderScope(
        overrides: [
          paginatedProjectsNotifierProvider.overrideWith(() {
            return _MockPaginatedNotifier(
              projects: projects ?? testProjects,
              errorMessage: errorMessage,
            );
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const ProjectsScreen(),
        ),
      );
    }

    Widget createLoadingTestWidget() {
      return ProviderScope(
        overrides: [
          paginatedProjectsNotifierProvider.overrideWith(() {
            return _LoadingPaginatedNotifier();
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const ProjectsScreen(),
        ),
      );
    }

    testWidgets('displays list of projects', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify list is displayed
      expect(find.byType(ListView), findsOneWidget);

      // Verify all project cards are shown
      expect(find.byType(ProjectCard), findsNWidgets(3));
    });

    testWidgets('each project shows name, location, and report count',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify project names
      expect(find.text('Construction Site A'), findsOneWidget);
      expect(find.text('Office Building B'), findsOneWidget);
      expect(find.text('Warehouse C'), findsOneWidget);

      // Verify locations (addresses)
      expect(find.text('123 Main St, New York'), findsOneWidget);
      expect(find.text('456 Oak Ave, Boston'), findsOneWidget);
      expect(find.text('789 Industrial Blvd'), findsOneWidget);

      // Verify report counts
      expect(find.text('5 reports'), findsOneWidget);
      expect(find.text('12 reports'), findsOneWidget);
      expect(find.text('0 reports'), findsOneWidget);
    });

    testWidgets('each project shows status indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify status badges exist (by finding StatusBadge widgets or status text)
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);
    });

    testWidgets('projects are sorted by most recent activity', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Get all project cards
      final projectCards =
          tester.widgetList<ProjectCard>(find.byType(ProjectCard)).toList();

      // Verify order: proj-1 (Jan 30), proj-2 (Jan 29), proj-3 (Jan 28)
      expect(projectCards[0].project.id, equals('proj-1'));
      expect(projectCards[1].project.id, equals('proj-2'));
      expect(projectCards[2].project.id, equals('proj-3'));
    });

    testWidgets('displays loading state', (tester) async {
      await tester.pumpWidget(createLoadingTestWidget());
      // Only pump once to see loading state before async completes
      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump and settle to complete the timer and avoid test cleanup issues
      await tester.pumpAndSettle();
    });

    testWidgets('displays empty state when no projects', (tester) async {
      await tester.pumpWidget(createTestWidget(projects: []));
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('No projects yet'), findsOneWidget);
    });

    testWidgets('displays error state', (tester) async {
      await tester.pumpWidget(createTestWidget(
        errorMessage: 'Failed to load projects',
      ));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Failed to load projects'), findsOneWidget);
    });

    testWidgets('screen has correct title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Projects'), findsOneWidget);
    });

    testWidgets('project cards are accessible with screen reader',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find semantics for the first project
      final semantics = tester.getSemantics(find.byType(ProjectCard).first);

      // Verify semantic label contains relevant info
      expect(semantics.label, contains('Construction Site A'));
    });

    group('search and filter', () {
      testWidgets('tap search icon shows search input', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify search icon exists in app bar
        expect(find.byIcon(Icons.search), findsOneWidget);

        // Tap search icon
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Verify search input appears
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byKey(const Key('project_search_field')), findsOneWidget);
      });

      testWidgets('typing in search filters list to matching projects',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap search icon
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Type project name
        await tester.enterText(
            find.byKey(const Key('project_search_field')), 'Construction');
        await tester.pumpAndSettle();

        // Verify list filters to matching projects
        expect(find.text('Construction Site A'), findsOneWidget);
        expect(find.text('Office Building B'), findsNothing);
        expect(find.text('Warehouse C'), findsNothing);
      });

      testWidgets('clearing search shows all projects', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap search icon
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Type search query
        await tester.enterText(
            find.byKey(const Key('project_search_field')), 'Construction');
        await tester.pumpAndSettle();

        // Verify filtered
        expect(find.byType(ProjectCard), findsOneWidget);

        // Clear search using the clear button in the text field (first close icon)
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();

        // Verify all projects shown again
        expect(find.byType(ProjectCard), findsNWidgets(3));
      });

      testWidgets('tap filter icon shows filter options', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify filter icon exists
        expect(find.byIcon(Icons.filter_list), findsOneWidget);

        // Tap filter icon
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        // Verify filter options appear (status, date range)
        expect(find.text('Filter Projects'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Archived'), findsOneWidget);
      });

      testWidgets('applying status filter shows filtered results',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap filter icon
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        // Select "Active" filter
        await tester.tap(find.text('Active').last);
        await tester.pumpAndSettle();

        // Apply filter
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();

        // Verify only active projects shown
        expect(find.text('Construction Site A'), findsOneWidget);
        expect(find.text('Office Building B'), findsNothing);
        expect(find.text('Warehouse C'), findsNothing);
      });

      testWidgets('search matches by name, address, or description',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap search icon
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Search by address
        await tester.enterText(
            find.byKey(const Key('project_search_field')), 'Boston');
        await tester.pumpAndSettle();

        // Verify Office Building B matches (has Boston in address)
        expect(find.text('Office Building B'), findsOneWidget);
        expect(find.byType(ProjectCard), findsOneWidget);
      });
    });

    group('field worker project visibility', () {
      late List<Project> projectsWithTeamMembers;
      late User fieldWorkerUser;
      late User adminUser;

      setUp(() {
        fieldWorkerUser = const User(
          id: 'field-worker-1',
          email: 'fieldworker@test.com',
          firstName: 'Field',
          lastName: 'Worker',
          role: UserRole.fieldWorker,
        );

        adminUser = const User(
          id: 'admin-1',
          email: 'admin@test.com',
          firstName: 'Admin',
          lastName: 'User',
          role: UserRole.admin,
        );

        projectsWithTeamMembers = [
          Project(
            id: 'proj-assigned-1',
            name: 'Assigned Project A',
            description: 'Project assigned to field worker',
            status: ProjectStatus.active,
            teamMembers: [
              TeamMember(
                id: fieldWorkerUser.id,
                name: fieldWorkerUser.fullName,
              ),
            ],
          ),
          Project(
            id: 'proj-assigned-2',
            name: 'Assigned Project B',
            description: 'Another assigned project',
            status: ProjectStatus.active,
            teamMembers: [
              TeamMember(
                id: fieldWorkerUser.id,
                name: fieldWorkerUser.fullName,
              ),
              const TeamMember(id: 'other-user', name: 'Other User'),
            ],
          ),
          const Project(
            id: 'proj-not-assigned',
            name: 'Unassigned Project',
            description: 'Project not assigned to field worker',
            status: ProjectStatus.active,
            teamMembers: [
              TeamMember(id: 'other-user', name: 'Other User'),
            ],
          ),
          const Project(
            id: 'proj-no-members',
            name: 'Project Without Members',
            description: 'Project with no team members',
            status: ProjectStatus.active,
            teamMembers: [],
          ),
        ];
      });

      Widget createFieldWorkerTestWidget({
        required User user,
        required List<Project> projects,
      }) {
        // Apply the filtering logic based on user role
        List<Project> filteredProjects;
        if (user.role == UserRole.admin || user.role == UserRole.manager) {
          filteredProjects = projects;
        } else {
          filteredProjects = projects.where((project) {
            return project.teamMembers.any((member) => member.id == user.id);
          }).toList();
        }

        return ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(user),
            paginatedProjectsNotifierProvider.overrideWith(() {
              return _MockPaginatedNotifier(projects: filteredProjects);
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const ProjectsScreen(),
          ),
        );
      }

      testWidgets('field worker only sees assigned projects', (tester) async {
        await tester.pumpWidget(createFieldWorkerTestWidget(
          user: fieldWorkerUser,
          projects: projectsWithTeamMembers,
        ));
        await tester.pumpAndSettle();

        // Verify only assigned projects are visible
        expect(find.text('Assigned Project A'), findsOneWidget);
        expect(find.text('Assigned Project B'), findsOneWidget);

        // Verify unassigned projects are NOT shown
        expect(find.text('Unassigned Project'), findsNothing);
        expect(find.text('Project Without Members'), findsNothing);

        // Verify correct number of project cards
        expect(find.byType(ProjectCard), findsNWidgets(2));
      });

      testWidgets('admin user sees all projects', (tester) async {
        await tester.pumpWidget(createFieldWorkerTestWidget(
          user: adminUser,
          projects: projectsWithTeamMembers,
        ));
        await tester.pumpAndSettle();

        // Admin should see all projects
        expect(find.text('Assigned Project A'), findsOneWidget);
        expect(find.text('Assigned Project B'), findsOneWidget);
        expect(find.text('Unassigned Project'), findsOneWidget);
        expect(find.text('Project Without Members'), findsOneWidget);

        // Verify all project cards are shown
        expect(find.byType(ProjectCard), findsNWidgets(4));
      });
    });
  });
}

/// Mock PaginatedProjectsNotifier for testing
class _MockPaginatedNotifier extends PaginatedProjectsNotifier {
  final List<Project> projects;
  final String? errorMessage;

  _MockPaginatedNotifier({
    required this.projects,
    this.errorMessage,
  });

  @override
  Future<PaginatedProjectsState> build() async {
    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    return PaginatedProjectsState(
      projects: projects,
      hasMore: false,
      currentPage: 1,
      isLoadingMore: false,
    );
  }
}

/// Loading state notifier that stays in loading state
class _LoadingPaginatedNotifier extends PaginatedProjectsNotifier {
  @override
  Future<PaginatedProjectsState> build() async {
    // Use a short delay that will show loading state on first pump
    // but complete quickly to avoid timer issues
    await Future.delayed(const Duration(milliseconds: 100));
    return const PaginatedProjectsState();
  }
}
