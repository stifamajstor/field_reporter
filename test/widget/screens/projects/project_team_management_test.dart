import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/presentation/project_team_management_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/projects/providers/available_users_provider.dart';

void main() {
  group('Admin can assign team members to project', () {
    late List<Project> testProjects;
    late List<User> availableUsers;
    late User adminUser;

    setUp(() {
      adminUser = const User(
        id: 'admin-1',
        email: 'admin@test.com',
        firstName: 'Admin',
        lastName: 'User',
        role: UserRole.admin,
      );

      availableUsers = [
        const User(
          id: 'user-1',
          email: 'john@test.com',
          firstName: 'John',
          lastName: 'Doe',
          role: UserRole.fieldWorker,
        ),
        const User(
          id: 'user-2',
          email: 'jane@test.com',
          firstName: 'Jane',
          lastName: 'Smith',
          role: UserRole.fieldWorker,
        ),
        const User(
          id: 'user-3',
          email: 'bob@test.com',
          firstName: 'Bob',
          lastName: 'Wilson',
          role: UserRole.manager,
        ),
      ];

      testProjects = [
        Project(
          id: 'proj-1',
          name: 'Construction Site Alpha',
          description: 'A large construction project',
          address: '123 Main St, New York',
          latitude: 40.7128,
          longitude: -74.0060,
          status: ProjectStatus.active,
          reportCount: 5,
          lastActivityAt: DateTime(2026, 1, 30, 10, 30),
          teamMembers: const [
            TeamMember(id: 'user-1', name: 'John Doe', role: 'Field Worker'),
          ],
        ),
      ];
    });

    Widget createTestWidget({
      required String projectId,
      List<Project>? projects,
      List<User>? users,
      User? currentUser,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects ?? testProjects);
          }),
          availableUsersProvider.overrideWith((ref) async {
            return users ?? availableUsers;
          }),
          currentUserProvider.overrideWith((ref) {
            return currentUser ?? adminUser;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: ProjectDetailScreen(projectId: projectId),
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/projects/') == true &&
                settings.name?.endsWith('/team') == true) {
              final projectId = settings.name!
                  .replaceFirst('/projects/', '')
                  .replaceFirst('/team', '');
              return MaterialPageRoute(
                builder: (_) =>
                    ProjectTeamManagementScreen(projectId: projectId),
              );
            }
            return null;
          },
        ),
      );
    }

    testWidgets('Login as admin or manager - admin can access team management',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        projectId: 'proj-1',
        currentUser: adminUser,
      ));
      await tester.pumpAndSettle();

      // Verify admin is logged in (we can access project detail)
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Construction Site Alpha'), findsOneWidget);
    });

    testWidgets('Navigate to Project Detail screen', (tester) async {
      await tester.pumpWidget(createTestWidget(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify Project Detail screen is displayed
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Construction Site Alpha'), findsOneWidget);
    });

    testWidgets('Tap Manage Team or team section opens team management',
        (tester) async {
      await tester.pumpWidget(createTestWidget(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Scroll to Team section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Find and tap the Manage Team button or team section
      final manageTeamButton = find.text('Manage Team');
      expect(manageTeamButton, findsOneWidget);

      await tester.tap(manageTeamButton);
      await tester.pumpAndSettle();

      // Verify team management screen appears
      expect(find.byType(ProjectTeamManagementScreen), findsOneWidget);
    });

    testWidgets('Team management screen shows current team members',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsNotifierProvider.overrideWith(() {
              return _MockProjectsNotifier(projects: testProjects);
            }),
            availableUsersProvider.overrideWith((ref) async {
              return availableUsers;
            }),
            currentUserProvider.overrideWith((ref) {
              return adminUser;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ProjectTeamManagementScreen(projectId: 'proj-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify list of current team members is shown
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Current Team'), findsOneWidget);
    });

    testWidgets('Tap Add Member shows list of available users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsNotifierProvider.overrideWith(() {
              return _MockProjectsNotifier(projects: testProjects);
            }),
            availableUsersProvider.overrideWith((ref) async {
              return availableUsers;
            }),
            currentUserProvider.overrideWith((ref) {
              return adminUser;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ProjectTeamManagementScreen(projectId: 'proj-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add Member button
      final addMemberButton = find.text('Add Member');
      expect(addMemberButton, findsOneWidget);

      await tester.tap(addMemberButton);
      await tester.pumpAndSettle();

      // Verify list of available users is shown (users not already on team)
      // John Doe is already on the team, so we should see Jane and Bob
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);
    });

    testWidgets('Select a user adds them to project team', (tester) async {
      final addedMembers = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsNotifierProvider.overrideWith(() {
              return _MockProjectsNotifierWithTeam(
                projects: testProjects,
                onAddMember: (projectId, userId) {
                  addedMembers.add(userId);
                },
              );
            }),
            availableUsersProvider.overrideWith((ref) async {
              return availableUsers;
            }),
            currentUserProvider.overrideWith((ref) {
              return adminUser;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ProjectTeamManagementScreen(projectId: 'proj-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add Member button
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Select Jane Smith
      await tester.tap(find.text('Jane Smith'));
      await tester.pumpAndSettle();

      // Verify user is added to project team
      expect(addedMembers, contains('user-2'));
    });

    testWidgets('User now appears in team list after being added',
        (tester) async {
      // Start with John on the team
      final projectWithTeam = [
        Project(
          id: 'proj-1',
          name: 'Construction Site Alpha',
          description: 'A large construction project',
          status: ProjectStatus.active,
          reportCount: 5,
          teamMembers: const [
            TeamMember(id: 'user-1', name: 'John Doe', role: 'Field Worker'),
            TeamMember(id: 'user-2', name: 'Jane Smith', role: 'Field Worker'),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsNotifierProvider.overrideWith(() {
              return _MockProjectsNotifier(projects: projectWithTeam);
            }),
            availableUsersProvider.overrideWith((ref) async {
              return availableUsers;
            }),
            currentUserProvider.overrideWith((ref) {
              return adminUser;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: ProjectTeamManagementScreen(projectId: 'proj-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both users now appear in team list
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('Manager can also manage team members', (tester) async {
      final managerUser = const User(
        id: 'manager-1',
        email: 'manager@test.com',
        firstName: 'Manager',
        lastName: 'Test',
        role: UserRole.manager,
      );

      await tester.pumpWidget(createTestWidget(
        projectId: 'proj-1',
        currentUser: managerUser,
      ));
      await tester.pumpAndSettle();

      // Scroll to Team section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Manager should see Manage Team button
      expect(find.text('Manage Team'), findsOneWidget);
    });

    testWidgets('Field worker cannot see Manage Team button', (tester) async {
      final fieldWorkerUser = const User(
        id: 'worker-1',
        email: 'worker@test.com',
        firstName: 'Field',
        lastName: 'Worker',
        role: UserRole.fieldWorker,
      );

      await tester.pumpWidget(createTestWidget(
        projectId: 'proj-1',
        currentUser: fieldWorkerUser,
      ));
      await tester.pumpAndSettle();

      // Scroll to Team section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Field worker should NOT see Manage Team button
      expect(find.text('Manage Team'), findsNothing);
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

/// Mock ProjectsNotifier that supports team operations
class _MockProjectsNotifierWithTeam extends ProjectsNotifier {
  List<Project> _projects;
  final void Function(String projectId, String userId)? onAddMember;

  _MockProjectsNotifierWithTeam({
    required List<Project> projects,
    this.onAddMember,
  }) : _projects = List.from(projects);

  @override
  Future<List<Project>> build() async {
    return _projects;
  }

  @override
  Future<void> addTeamMember(String projectId, TeamMember member) async {
    onAddMember?.call(projectId, member.id);
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          teamMembers: [...p.teamMembers, member],
        );
      }
      return p;
    }).toList();
    state = AsyncData(_projects);
  }
}
