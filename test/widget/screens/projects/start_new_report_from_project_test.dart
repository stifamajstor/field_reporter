import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/project_detail_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';
import 'package:field_reporter/features/reports/presentation/report_editor_screen.dart';

void main() {
  group('Start New Report from Project Detail', () {
    late Project testProject;

    setUp(() {
      testProject = Project(
        id: 'proj-1',
        name: 'Construction Site Alpha',
        description: 'A large construction project',
        address: '123 Main St, New York',
        latitude: 40.7128,
        longitude: -74.0060,
        status: ProjectStatus.active,
        reportCount: 2,
        lastActivityAt: DateTime(2026, 1, 30, 10, 30),
      );
    });

    Widget createTestApp({
      required String projectId,
      List<Project>? projects,
    }) {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier(projects: projects ?? [testProject]);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          onGenerateRoute: (settings) {
            if (settings.name == '/reports/new') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => ReportEditorScreen(
                  projectId: args?['projectId'] as String?,
                ),
              );
            }
            return null;
          },
          home: ProjectDetailScreen(projectId: projectId),
        ),
      );
    }

    testWidgets('displays New Report button on project detail screen',
        (tester) async {
      await tester.pumpWidget(createTestApp(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Verify 'New Report' button is visible
      expect(find.text('New Report'), findsOneWidget);
    });

    testWidgets('tapping New Report button navigates to Report Editor',
        (tester) async {
      await tester.pumpWidget(createTestApp(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Tap 'New Report' button
      await tester.tap(find.text('New Report'));
      await tester.pumpAndSettle();

      // Verify Report Editor screen opens
      expect(find.byType(ReportEditorScreen), findsOneWidget);
    });

    testWidgets('Report Editor has project pre-selected', (tester) async {
      await tester.pumpWidget(createTestApp(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Tap 'New Report' button
      await tester.tap(find.text('New Report'));
      await tester.pumpAndSettle();

      // Verify project name is displayed in Report Editor
      expect(find.text('Construction Site Alpha'), findsOneWidget);
    });

    testWidgets('Report is created in draft status', (tester) async {
      await tester.pumpWidget(createTestApp(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Tap 'New Report' button
      await tester.tap(find.text('New Report'));
      await tester.pumpAndSettle();

      // Verify draft status indicator
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('can add an entry to confirm report is linked', (tester) async {
      await tester.pumpWidget(createTestApp(projectId: 'proj-1'));
      await tester.pumpAndSettle();

      // Tap 'New Report' button
      await tester.tap(find.text('New Report'));
      await tester.pumpAndSettle();

      // Verify 'Add Entry' button exists
      expect(find.text('Add Entry'), findsOneWidget);
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
