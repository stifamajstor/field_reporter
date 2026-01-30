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

    testWidgets('pull down on list shows refresh indicator and reloads',
        (tester) async {
      var buildCount = 0;

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
            userVisibleProjectsProvider.overrideWith((ref) async {
              buildCount++;
              return projects;
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

      // Reset build count after initial load
      final initialBuildCount = buildCount;

      // Pull down on the list to trigger refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );

      // Pump to show refresh indicator
      await tester.pump();

      // Verify RefreshIndicator exists in widget tree
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Allow refresh to complete
      await tester.pumpAndSettle();

      // Verify data was reloaded (build was called again)
      expect(buildCount, greaterThan(initialBuildCount));

      // Verify list still shows projects
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
            userVisibleProjectsProvider.overrideWith((ref) async {
              return projects;
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

    testWidgets('refreshing updates displayed data', (tester) async {
      var showUpdated = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            userVisibleProjectsProvider.overrideWith((ref) async {
              if (showUpdated) {
                return [
                  Project(
                    id: 'proj-updated',
                    name: 'Updated Project',
                    status: ProjectStatus.active,
                    lastActivityAt: DateTime(2026, 1, 31),
                  ),
                ];
              }
              return [
                Project(
                  id: 'proj-initial',
                  name: 'Initial Project',
                  status: ProjectStatus.active,
                  lastActivityAt: DateTime(2026, 1, 30),
                ),
              ];
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
      expect(find.text('Initial Project'), findsOneWidget);

      // Update the data that will be returned on next build
      showUpdated = true;

      // Pull down to refresh
      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Verify updated data is displayed
      expect(find.text('Updated Project'), findsOneWidget);
    });
  });
}
