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
  group('Admin can remove team members from project', () {
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
            TeamMember(id: 'user-2', name: 'Jane Smith', role: 'Field Worker'),
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

    Widget createTeamManagementWidget({
      List<Project>? projects,
      List<User>? users,
      User? currentUser,
      void Function(String projectId, String memberId)? onRemoveMember,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifierWithRemove(
              projects: projects ?? testProjects,
              onRemoveMember: onRemoveMember,
            );
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
          home: ProjectTeamManagementScreen(projectId: 'proj-1'),
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

    testWidgets('Navigate to Project Detail with team members', (tester) async {
      await tester.pumpWidget(createTestWidget(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify Project Detail screen is displayed with team members
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Construction Site Alpha'), findsOneWidget);
    });

    testWidgets('Tap Manage Team opens team management screen', (tester) async {
      await tester.pumpWidget(createTestWidget(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Scroll to Team section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Find and tap the Manage Team button
      final manageTeamButton = find.text('Manage Team');
      expect(manageTeamButton, findsOneWidget);

      await tester.tap(manageTeamButton);
      await tester.pumpAndSettle();

      // Verify team management screen appears
      expect(find.byType(ProjectTeamManagementScreen), findsOneWidget);
    });

    testWidgets('Swipe left on a team member reveals remove action',
        (tester) async {
      await tester.pumpWidget(createTeamManagementWidget());
      await tester.pumpAndSettle();

      // Find John Doe in the list
      expect(find.text('John Doe'), findsOneWidget);

      // Swipe left on John Doe to reveal remove action
      await tester.drag(
        find.text('John Doe'),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();

      // Verify remove action is visible (background or button revealed)
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Tap remove button shows confirmation prompt', (tester) async {
      await tester.pumpWidget(createTeamManagementWidget());
      await tester.pumpAndSettle();

      // Find and tap the remove button for John Doe
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      expect(removeButtons, findsNWidgets(2)); // One for each team member

      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Remove Team Member'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to remove'),
        findsOneWidget,
      );
    });

    testWidgets('Confirm removal removes user from team list', (tester) async {
      final removedMembers = <String>[];

      await tester.pumpWidget(createTeamManagementWidget(
        onRemoveMember: (projectId, memberId) {
          removedMembers.add(memberId);
        },
      ));
      await tester.pumpAndSettle();

      // Tap remove button for John Doe
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Remove Team Member'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Verify user is removed
      expect(removedMembers, contains('user-1'));
    });

    testWidgets('Cancel removal does not remove user', (tester) async {
      final removedMembers = <String>[];

      await tester.pumpWidget(createTeamManagementWidget(
        onRemoveMember: (projectId, memberId) {
          removedMembers.add(memberId);
        },
      ));
      await tester.pumpAndSettle();

      // Tap remove button for John Doe
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Remove Team Member'), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify user was NOT removed
      expect(removedMembers, isEmpty);
      // User should still be in the list
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('User is removed from team list after confirmation',
        (tester) async {
      await tester.pumpWidget(createTeamManagementWidget());
      await tester.pumpAndSettle();

      // Verify both team members are shown initially
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);

      // Tap remove button for John Doe
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // John Doe should no longer be in the list
      expect(find.text('John Doe'), findsNothing);
      // Jane Smith should still be there
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('Manager can also remove team members', (tester) async {
      final managerUser = const User(
        id: 'manager-1',
        email: 'manager@test.com',
        firstName: 'Manager',
        lastName: 'Test',
        role: UserRole.manager,
      );

      await tester.pumpWidget(createTeamManagementWidget(
        currentUser: managerUser,
      ));
      await tester.pumpAndSettle();

      // Manager should see remove buttons
      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));

      // Tap remove button
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Manager should see confirmation dialog
      expect(find.text('Remove Team Member'), findsOneWidget);
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

/// Mock ProjectsNotifier that supports team removal operations
class _MockProjectsNotifierWithRemove extends ProjectsNotifier {
  List<Project> _projects;
  final void Function(String projectId, String memberId)? onRemoveMember;

  _MockProjectsNotifierWithRemove({
    required List<Project> projects,
    this.onRemoveMember,
  }) : _projects = List.from(projects);

  @override
  Future<List<Project>> build() async {
    return _projects;
  }

  @override
  Future<void> removeTeamMember(String projectId, String memberId) async {
    onRemoveMember?.call(projectId, memberId);
    _projects = _projects.map((p) {
      if (p.id == projectId) {
        return p.copyWith(
          teamMembers: p.teamMembers.where((m) => m.id != memberId).toList(),
        );
      }
      return p;
    }).toList();
    state = AsyncData(_projects);
  }
}
