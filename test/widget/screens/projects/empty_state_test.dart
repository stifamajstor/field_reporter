import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/projects_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/widgets/layout/empty_state.dart';

void main() {
  group('Empty state shown when no projects exist', () {
    const testUser = User(
      id: 'user-1',
      email: 'test@test.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.admin,
    );

    Widget createTestWidget({List<Project>? projects}) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(testUser),
          paginatedProjectsNotifierProvider.overrideWith(() {
            return _MockPaginatedNotifier(projects: projects ?? []);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProjectsScreen(),
        ),
      );
    }

    testWidgets('displays empty state illustration when no projects',
        (tester) async {
      await tester.pumpWidget(createTestWidget(projects: []));
      await tester.pumpAndSettle();

      // Verify empty state widget is displayed
      expect(find.byType(EmptyState), findsOneWidget);

      // Verify icon/illustration is displayed
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('displays message explaining no projects exist',
        (tester) async {
      await tester.pumpWidget(createTestWidget(projects: []));
      await tester.pumpAndSettle();

      // Verify title message
      expect(find.text('No projects yet'), findsOneWidget);

      // Verify description
      expect(
        find.text('Create your first project to start capturing reports.'),
        findsOneWidget,
      );
    });

    testWidgets('displays prominent Create First Project button',
        (tester) async {
      await tester.pumpWidget(createTestWidget(projects: []));
      await tester.pumpAndSettle();

      // Verify Create Project action button exists
      expect(find.text('Create Project'), findsOneWidget);

      // Verify it has an icon
      expect(find.byIcon(Icons.add), findsAtLeast(1));
    });

    testWidgets('Create Project button is tappable and prominent',
        (tester) async {
      await tester.pumpWidget(createTestWidget(projects: []));
      await tester.pumpAndSettle();

      // Verify it's in the empty state section
      final emptyState = find.byType(EmptyState);
      expect(emptyState, findsOneWidget);

      final buttonInEmptyState = find.descendant(
        of: emptyState,
        matching: find.text('Create Project'),
      );
      expect(buttonInEmptyState, findsOneWidget);

      // Button should be tappable (verify by tapping without error)
      await tester.tap(buttonInEmptyState);
      await tester.pumpAndSettle();
    });

    testWidgets('empty state not shown when projects exist', (tester) async {
      await tester.pumpWidget(createTestWidget(
        projects: [
          Project(
            id: 'proj-1',
            name: 'Test Project',
            status: ProjectStatus.active,
            lastActivityAt: DateTime(2026, 1, 30),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify empty state is NOT shown
      expect(find.text('No projects yet'), findsNothing);
      expect(find.byType(EmptyState), findsNothing);

      // Verify project is displayed
      expect(find.text('Test Project'), findsOneWidget);
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
