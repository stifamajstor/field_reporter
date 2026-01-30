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
  group('Field worker can only see assigned projects', () {
    // Field worker user
    const fieldWorker = User(
      id: 'field-worker-1',
      email: 'fieldworker@test.com',
      firstName: 'Field',
      lastName: 'Worker',
      role: UserRole.fieldWorker,
    );

    // Projects with team assignments
    final assignedProject = Project(
      id: 'proj-assigned',
      name: 'Assigned Project',
      description: 'Project assigned to field worker',
      address: '123 Assigned St',
      status: ProjectStatus.active,
      teamMembers: const [
        TeamMember(id: 'field-worker-1', name: 'Field Worker'),
      ],
      lastActivityAt: DateTime(2026, 1, 30),
    );

    final notAssignedProject = Project(
      id: 'proj-not-assigned',
      name: 'Not Assigned Project',
      description: 'Project not assigned to field worker',
      address: '456 Other St',
      status: ProjectStatus.active,
      teamMembers: const [
        TeamMember(id: 'other-user-1', name: 'Other User'),
      ],
      lastActivityAt: DateTime(2026, 1, 29),
    );

    final anotherAssignedProject = Project(
      id: 'proj-assigned-2',
      name: 'Another Assigned Project',
      description: 'Another project assigned to field worker',
      address: '789 Also Assigned St',
      status: ProjectStatus.completed,
      teamMembers: const [
        TeamMember(id: 'field-worker-1', name: 'Field Worker'),
        TeamMember(id: 'other-user-1', name: 'Other User'),
      ],
      lastActivityAt: DateTime(2026, 1, 28),
    );

    Widget createTestWidget({
      required User currentUser,
      required List<Project> allProjects,
    }) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => currentUser),
          // Override the base provider - the screen should use userVisibleProjectsProvider
          // which will filter based on the currentUser
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: allProjects);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProjectsScreen(),
        ),
      );
    }

    testWidgets('field worker only sees projects they are assigned to',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        currentUser: fieldWorker,
        allProjects: [
          assignedProject,
          notAssignedProject,
          anotherAssignedProject
        ],
      ));
      await tester.pumpAndSettle();

      // Verify assigned projects are visible
      expect(find.text('Assigned Project'), findsOneWidget);
      expect(find.text('Another Assigned Project'), findsOneWidget);

      // Verify not assigned project is NOT visible
      expect(find.text('Not Assigned Project'), findsNothing);

      // Should show exactly 2 project cards (the assigned ones)
      expect(find.byType(ProjectCard), findsNWidgets(2));
    });

    testWidgets('field worker does not see projects they are not assigned to',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        currentUser: fieldWorker,
        allProjects: [notAssignedProject],
      ));
      await tester.pumpAndSettle();

      // Should show empty state since no projects are assigned
      expect(find.text('Not Assigned Project'), findsNothing);
      expect(find.byType(ProjectCard), findsNothing);
    });

    testWidgets('admin can see all projects regardless of assignment',
        (tester) async {
      const admin = User(
        id: 'admin-1',
        email: 'admin@test.com',
        firstName: 'Admin',
        lastName: 'User',
        role: UserRole.admin,
      );

      await tester.pumpWidget(createTestWidget(
        currentUser: admin,
        allProjects: [
          assignedProject,
          notAssignedProject,
          anotherAssignedProject
        ],
      ));
      await tester.pumpAndSettle();

      // Admin should see ALL projects
      expect(find.text('Assigned Project'), findsOneWidget);
      expect(find.text('Not Assigned Project'), findsOneWidget);
      expect(find.text('Another Assigned Project'), findsOneWidget);
      expect(find.byType(ProjectCard), findsNWidgets(3));
    });

    testWidgets('manager can see all projects regardless of assignment',
        (tester) async {
      const manager = User(
        id: 'manager-1',
        email: 'manager@test.com',
        firstName: 'Manager',
        lastName: 'User',
        role: UserRole.manager,
      );

      await tester.pumpWidget(createTestWidget(
        currentUser: manager,
        allProjects: [assignedProject, notAssignedProject],
      ));
      await tester.pumpAndSettle();

      // Manager should see ALL projects
      expect(find.text('Assigned Project'), findsOneWidget);
      expect(find.text('Not Assigned Project'), findsOneWidget);
      expect(find.byType(ProjectCard), findsNWidgets(2));
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
