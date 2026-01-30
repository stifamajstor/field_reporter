import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
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
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(
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
          projectsNotifierProvider.overrideWith(() {
            return _LoadingProjectsNotifier();
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
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  final List<Project> projects;
  final String? errorMessage;

  _MockProjectsNotifier({
    required this.projects,
    this.errorMessage,
  });

  @override
  Future<List<Project>> build() async {
    if (errorMessage != null) {
      throw Exception(errorMessage);
    }
    return projects;
  }
}

/// Loading state notifier that stays in loading state
class _LoadingProjectsNotifier extends ProjectsNotifier {
  @override
  Future<List<Project>> build() async {
    // Use a short delay that will show loading state on first pump
    // but complete quickly to avoid timer issues
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }
}
