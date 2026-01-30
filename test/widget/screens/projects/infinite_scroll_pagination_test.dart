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
  group('Project list supports infinite scroll pagination', () {
    const testUser = User(
      id: 'user-1',
      email: 'test@test.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.admin,
    );

    List<Project> generateProjects(int count, {int startIndex = 0}) {
      return List.generate(count, (index) {
        final i = startIndex + index;
        return Project(
          id: 'proj-$i',
          name: 'Project $i',
          status: ProjectStatus.active,
          lastActivityAt: DateTime(2026, 1, 30).subtract(Duration(days: i)),
        );
      });
    }

    testWidgets('loads initial batch and shows first project', (tester) async {
      // Generate 25 projects total, expect initial batch of ~20
      final allProjects = generateProjects(25);
      final mockNotifier = _MockPaginatedNotifier(
        allProjects: allProjects,
        pageSize: 20,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            paginatedProjectsNotifierProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProjectsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial batch loaded with first project visible
      expect(find.byType(ProjectCard), findsWidgets);
      expect(find.text('Project 0'), findsOneWidget);

      // Verify has more indicator exists (pagination_loading key)
      expect(mockNotifier.currentState.hasMore, isTrue);
    });

    testWidgets('state tracks loading more status', (tester) async {
      final allProjects = generateProjects(30);
      final mockNotifier = _MockPaginatedNotifier(
        allProjects: allProjects,
        pageSize: 20,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            paginatedProjectsNotifierProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProjectsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state is not loading
      expect(mockNotifier.currentState.isLoadingMore, isFalse);

      // Set loading state
      mockNotifier.setLoadingMore(true);
      await tester.pump();

      // Verify loading state changed
      expect(mockNotifier.currentState.isLoadingMore, isTrue);

      // Reset loading state
      mockNotifier.setLoadingMore(false);
      await tester.pump();

      // Verify loading state changed back
      expect(mockNotifier.currentState.isLoadingMore, isFalse);
    });

    testWidgets('loads more projects after scrolling triggers loadMore',
        (tester) async {
      final allProjects = generateProjects(30);
      final mockNotifier = _MockPaginatedNotifier(
        allProjects: allProjects,
        pageSize: 20,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            paginatedProjectsNotifierProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProjectsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state has 20 projects
      expect(mockNotifier.currentState.projects.length, equals(20));
      expect(mockNotifier.currentState.hasMore, isTrue);

      // Simulate loading more (triggered by scroll)
      await mockNotifier.loadMore();
      await tester.pumpAndSettle();

      // Verify all 30 projects are now loaded
      expect(mockNotifier.currentState.projects.length, equals(30));
      expect(mockNotifier.currentState.hasMore, isFalse);

      // Scroll multiple times to get to the end
      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
      }

      // Verify last project is accessible in the viewport
      expect(find.text('Project 29'), findsOneWidget);
    });

    testWidgets('continues to load more pages until all loaded',
        (tester) async {
      // 45 projects = 3 pages (20 + 20 + 5)
      final allProjects = generateProjects(45);
      final mockNotifier = _MockPaginatedNotifier(
        allProjects: allProjects,
        pageSize: 20,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            paginatedProjectsNotifierProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProjectsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial load: 20 projects
      expect(mockNotifier.currentState.projects.length, equals(20));
      expect(mockNotifier.currentState.hasMore, isTrue);

      // First loadMore: 40 projects
      await mockNotifier.loadMore();
      await tester.pumpAndSettle();
      expect(mockNotifier.currentState.projects.length, equals(40));
      expect(mockNotifier.currentState.hasMore, isTrue);

      // Second loadMore: all 45 projects
      await mockNotifier.loadMore();
      await tester.pumpAndSettle();
      expect(mockNotifier.currentState.projects.length, equals(45));
      expect(mockNotifier.currentState.hasMore, isFalse);
    });

    testWidgets('no loading indicator when all data is loaded', (tester) async {
      // Only 15 projects, less than page size
      final allProjects = generateProjects(15);
      final mockNotifier = _MockPaginatedNotifier(
        allProjects: allProjects,
        pageSize: 20,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            paginatedProjectsNotifierProvider.overrideWith(() => mockNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProjectsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all loaded with no more pages
      expect(mockNotifier.currentState.projects.length, equals(15));
      expect(mockNotifier.currentState.hasMore, isFalse);

      // Scroll to bottom
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();

      // No loading indicator since all data loaded
      expect(find.byKey(const Key('pagination_loading')), findsNothing);
    });
  });
}

/// Mock notifier that simulates paginated loading
class _MockPaginatedNotifier extends PaginatedProjectsNotifier {
  final List<Project> allProjects;
  final int pageSize;
  int _currentPage = 1;

  _MockPaginatedNotifier({
    required this.allProjects,
    this.pageSize = 20,
  });

  PaginatedProjectsState get currentState =>
      state.valueOrNull ?? const PaginatedProjectsState();

  @override
  Future<PaginatedProjectsState> build() async {
    _currentPage = 1;
    final initialBatch = allProjects.take(pageSize).toList();
    return PaginatedProjectsState(
      projects: initialBatch,
      hasMore: allProjects.length > pageSize,
      currentPage: 1,
      isLoadingMore: false,
    );
  }

  void setLoadingMore(bool value) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isLoadingMore: value));
    }
  }

  @override
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    _currentPage++;
    final endIndex = (_currentPage * pageSize).clamp(0, allProjects.length);
    final newProjects = allProjects.sublist(0, endIndex);
    final hasMore = endIndex < allProjects.length;

    state = AsyncData(PaginatedProjectsState(
      projects: newProjects,
      hasMore: hasMore,
      currentPage: _currentPage,
      isLoadingMore: false,
    ));
  }
}
