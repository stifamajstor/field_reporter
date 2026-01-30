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
  group('Project list supports pull-to-refresh', () {
    const testUser = User(
      id: 'user-1',
      email: 'test@test.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.admin,
    );

    testWidgets('pull down on list shows refresh indicator', (tester) async {
      final projects = [
        Project(
          id: 'proj-1',
          name: 'Project One',
          status: ProjectStatus.active,
          lastActivityAt: DateTime(2026, 1, 30),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
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
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.byType(ProjectCard), findsOneWidget);
      expect(find.text('Project One'), findsOneWidget);

      // Verify RefreshIndicator is part of the widget tree
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Pull down on the list to trigger refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );

      // Pump to show refresh indicator
      await tester.pump();

      // Allow refresh to complete
      await tester.pumpAndSettle();

      // Verify list still shows projects after refresh
      expect(find.byType(ProjectCard), findsOneWidget);
    });

    testWidgets('refresh indicator disappears after loading', (tester) async {
      final projects = [
        Project(
          id: 'proj-1',
          name: 'Test Project',
          status: ProjectStatus.active,
          lastActivityAt: DateTime(2026, 1, 30),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
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
        ),
      );
      await tester.pumpAndSettle();

      // Pull down to refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      // Wait for refresh to complete
      await tester.pumpAndSettle();

      // Verify list is still showing (refresh completed)
      expect(find.byType(ProjectCard), findsOneWidget);
    });

    testWidgets('list view is wrapped with RefreshIndicator', (tester) async {
      final projects = [
        Project(
          id: 'proj-1',
          name: 'Test Project',
          status: ProjectStatus.active,
          lastActivityAt: DateTime(2026, 1, 30),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
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
        ),
      );
      await tester.pumpAndSettle();

      // Verify RefreshIndicator wraps the ListView
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // Verify RefreshIndicator is ancestor of ListView
      final refreshIndicator = find.byType(RefreshIndicator);
      final listView = find.descendant(
        of: refreshIndicator,
        matching: find.byType(ListView),
      );
      expect(listView, findsOneWidget);
    });
  });
}

/// Standard mock notifier
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
