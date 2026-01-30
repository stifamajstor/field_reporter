import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/presentation/create_project_screen.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('Project name has maximum length limit', () {
    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          projectsNotifierProvider.overrideWith(() {
            return _MockProjectsNotifier();
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const CreateProjectScreen(),
        ),
      );
    }

    testWidgets('project name field enforces 100 character limit',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the project name field
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      expect(nameField, findsOneWidget);

      // Enter text exceeding 100 characters
      final longText = 'A' * 150;
      await tester.enterText(nameField, longText);
      await tester.pump();

      // Verify input is limited to 100 characters
      final textField = tester.widget<TextFormField>(nameField);
      expect(textField.controller!.text.length, equals(100));
    });

    testWidgets('character counter shows limit', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the project name field
      final nameField = find.widgetWithText(TextFormField, 'Project Name');
      expect(nameField, findsOneWidget);

      // Enter some text
      await tester.enterText(nameField, 'Test Project');
      await tester.pump();

      // Verify character counter is visible showing current/max
      expect(find.text('12/100'), findsOneWidget);
    });

    testWidgets('character counter updates as user types', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Project Name');

      // Enter text
      await tester.enterText(nameField, 'Hello');
      await tester.pump();

      expect(find.text('5/100'), findsOneWidget);

      // Enter more text
      await tester.enterText(nameField, 'Hello World');
      await tester.pump();

      expect(find.text('11/100'), findsOneWidget);
    });

    testWidgets('counter shows at max when reaching limit', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Project Name');

      // Enter exactly 100 characters
      final exactText = 'A' * 100;
      await tester.enterText(nameField, exactText);
      await tester.pump();

      expect(find.text('100/100'), findsOneWidget);

      // Verify text is exactly 100 chars
      final textField = tester.widget<TextFormField>(nameField);
      expect(textField.controller!.text.length, equals(100));
    });
  });
}

/// Mock ProjectsNotifier for testing
class _MockProjectsNotifier extends ProjectsNotifier {
  @override
  Future<List<Project>> build() async {
    return [];
  }

  @override
  Future<Project> createProject(Project project) async {
    return project;
  }
}
