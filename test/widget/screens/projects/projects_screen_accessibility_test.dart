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
  group('Projects screen is accessible with screen reader', () {
    late List<Project> testProjects;

    const testUser = User(
      id: 'user-1',
      email: 'test@test.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.admin,
    );

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

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(testUser),
          paginatedProjectsNotifierProvider.overrideWith(() {
            return _MockPaginatedNotifier(projects: testProjects);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProjectsScreen(),
        ),
      );
    }

    testWidgets('screen title is announced for screen reader', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify screen title exists and is accessible
      final titleFinder = find.text('Projects');
      expect(titleFinder, findsOneWidget);

      // The title should be in the AppBar which has implicit accessibility
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
    });

    testWidgets('project cards have accessible semantic labels with name',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find all project cards
      final projectCards = find.byType(ProjectCard);
      expect(projectCards, findsNWidgets(3));

      // Check each project card has semantic label with name
      for (var i = 0; i < 3; i++) {
        final semantics = tester.getSemantics(projectCards.at(i));
        expect(
          semantics.label,
          contains(testProjects[i].name),
          reason: 'Project card should include project name in semantics',
        );
      }
    });

    testWidgets('project cards have accessible semantic labels with location',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final projectCards = find.byType(ProjectCard);

      // Check first project card has location in semantic label
      final semantics = tester.getSemantics(projectCards.first);
      expect(
        semantics.label,
        contains('123 Main St'),
        reason: 'Project card should include location in semantics',
      );
    });

    testWidgets('project cards have accessible semantic labels with status',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final projectCards = find.byType(ProjectCard);

      // Check first project card has status in semantic label
      final semantics = tester.getSemantics(projectCards.first);

      // Status should be announced (could be "active", "ACTIVE", or "Active")
      expect(
        semantics.label?.toLowerCase(),
        contains('active'),
        reason: 'Project card should include status in semantics',
      );
    });

    testWidgets('search button has accessible label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find search icon button
      final searchButton = find.byIcon(Icons.search);
      expect(searchButton, findsOneWidget);

      // Verify search button has tooltip (which provides the semantic label)
      final iconButton = tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.search));
      expect(
        iconButton.tooltip?.toLowerCase(),
        contains('search'),
        reason: 'Search button should have descriptive tooltip',
      );
    });

    testWidgets('filter button has accessible label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find filter icon button
      final filterButton = find.byIcon(Icons.filter_list);
      expect(filterButton, findsOneWidget);

      // Verify filter button has tooltip (which provides the semantic label)
      final iconButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.filter_list));
      expect(
        iconButton.tooltip?.toLowerCase(),
        contains('filter'),
        reason: 'Filter button should have descriptive tooltip',
      );
    });

    testWidgets('FAB has accessible label', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // Verify FAB has tooltip (which provides the semantic label)
      final fabWidget = tester.widget<FloatingActionButton>(fab);
      expect(
        fabWidget.tooltip?.toLowerCase(),
        anyOf(
          contains('create'),
          contains('new'),
          contains('project'),
        ),
        reason: 'FAB should have descriptive tooltip for creating projects',
      );
    });

    testWidgets('list view is scrollable with semantic announcements',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify list is present
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Verify list is scrollable (has scroll semantics)
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets);
    });
  });
}

/// Mock PaginatedProjectsNotifier for testing
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
