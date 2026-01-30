import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('Project cards show visual status indicators', () {
    const testUser = User(
      id: 'user-1',
      email: 'test@test.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.admin,
    );

    Widget createTestWidget({required List<Project> projects}) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(testUser),
          paginatedProjectsNotifierProvider.overrideWith(() {
            return _MockPaginatedNotifier(projects: projects);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProjectsScreen(),
        ),
      );
    }

    testWidgets('active projects show ACTIVE status badge', (tester) async {
      await tester.pumpWidget(createTestWidget(
        projects: [
          Project(
            id: 'proj-1',
            name: 'Active Project',
            status: ProjectStatus.active,
            lastActivityAt: DateTime(2026, 1, 30),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify active status badge is shown
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('completed projects show COMPLETED status badge',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        projects: [
          Project(
            id: 'proj-1',
            name: 'Completed Project',
            status: ProjectStatus.completed,
            lastActivityAt: DateTime(2026, 1, 30),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify completed status badge is shown
      expect(find.text('COMPLETED'), findsOneWidget);
    });

    testWidgets('archived projects show ARCHIVED status badge', (tester) async {
      await tester.pumpWidget(createTestWidget(
        projects: [
          Project(
            id: 'proj-1',
            name: 'Archived Project',
            status: ProjectStatus.archived,
            lastActivityAt: DateTime(2026, 1, 30),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify archived status badge is shown
      expect(find.text('ARCHIVED'), findsOneWidget);
    });

    testWidgets('projects with pending sync show sync indicator',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        projects: [
          Project(
            id: 'proj-1',
            name: 'Pending Sync Project',
            status: ProjectStatus.active,
            syncPending: true,
            lastActivityAt: DateTime(2026, 1, 30),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify sync indicator is visible
      expect(find.text('Pending sync'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      expect(find.byKey(const Key('pending_sync_indicator')), findsOneWidget);
    });

    testWidgets('multiple projects show their respective status indicators',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        projects: [
          Project(
            id: 'proj-1',
            name: 'Active Project',
            status: ProjectStatus.active,
            lastActivityAt: DateTime(2026, 1, 30),
          ),
          Project(
            id: 'proj-2',
            name: 'Completed Project',
            status: ProjectStatus.completed,
            lastActivityAt: DateTime(2026, 1, 29),
          ),
          Project(
            id: 'proj-3',
            name: 'Archived Project',
            status: ProjectStatus.archived,
            lastActivityAt: DateTime(2026, 1, 28),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify all status badges are shown
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('ARCHIVED'), findsOneWidget);
    });
  });
}

/// Mock notifier
class _MockPaginatedNotifier extends PaginatedProjectsNotifier {
  final List<Project> projects;

  _MockPaginatedNotifier({required this.projects});

  @override
  Future<PaginatedProjectsState> build() async {
    return PaginatedProjectsState(
      projects: projects,
      hasMore: false,
      currentPage: 1,
      isLoadingMore: false,
    );
  }
}
