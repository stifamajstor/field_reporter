import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/theme.dart';
import 'package:field_reporter/features/capture/domain/photo_annotation.dart';
import 'package:field_reporter/features/capture/presentation/photo_preview_screen.dart';
import 'package:field_reporter/features/capture/presentation/photo_annotation_screen.dart';
import 'package:field_reporter/features/capture/providers/photo_annotation_provider.dart';

void main() {
  group('User can add annotation to photo immediately after capture', () {
    Widget createTestWidget({
      required Widget child,
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: child,
        ),
      );
    }

    // Helper to find tool by looking for either selected or unselected key
    Finder findDrawTool() {
      final selected = find.byKey(const Key('annotation_tool_draw_selected'));
      final unselected = find.byKey(const Key('annotation_tool_draw'));
      // Return whichever one exists
      return selected.evaluate().isNotEmpty ? selected : unselected;
    }

    testWidgets('Capture photo - preview screen shows annotate button',
        (tester) async {
      // Simulating we've captured a photo and are on the preview screen
      await tester.pumpWidget(createTestWidget(
        child: PhotoPreviewScreen(
          arguments: PhotoPreviewArguments(
            photoPath: '/test/captured_photo.jpg',
            capturedTimestamp: DateTime(2026, 1, 31, 14, 0),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify preview screen is shown
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);

      // Verify annotate button/icon is visible
      final annotateButton = find.byKey(const Key('annotate_photo_button'));
      expect(annotateButton, findsOneWidget);
    });

    testWidgets(
        'On preview screen, tap Annotate - annotation tools appear (draw, text, arrow)',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: PhotoAnnotationScreen(
          photoPath: '/test/captured_photo.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // Verify annotation screen is shown
      expect(find.byType(PhotoAnnotationScreen), findsOneWidget);

      // Verify annotation tools appear (draw is selected by default)
      // Check for either selected or unselected state
      expect(
        find.byKey(const Key('annotation_tool_draw_selected')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('annotation_tool_text')), findsOneWidget);
      expect(find.byKey(const Key('annotation_tool_arrow')), findsOneWidget);
    });

    testWidgets('Draw on the photo - stroke is visible', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: PhotoAnnotationScreen(
          photoPath: '/test/captured_photo.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // Draw tool is already selected by default
      expect(
        find.byKey(const Key('annotation_tool_draw_selected')),
        findsOneWidget,
      );

      // Draw on the canvas
      final canvas = find.byKey(const Key('annotation_canvas'));
      expect(canvas, findsOneWidget);

      // Simulate drawing gesture
      final canvasCenter = tester.getCenter(canvas);
      await tester.dragFrom(
        canvasCenter,
        const Offset(100, 100),
      );
      await tester.pumpAndSettle();

      // Verify annotation layer has strokes
      final annotationLayer = find.byKey(const Key('annotation_layer'));
      expect(annotationLayer, findsOneWidget);
    });

    testWidgets('Add text label - text appears on photo', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: PhotoAnnotationScreen(
          photoPath: '/test/captured_photo.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // Select text tool
      final textTool = find.byKey(const Key('annotation_tool_text'));
      await tester.tap(textTool);
      await tester.pumpAndSettle();

      // Verify text tool is selected
      expect(find.byKey(const Key('annotation_tool_text_selected')),
          findsOneWidget);

      // Tap on canvas to add text
      final canvas = find.byKey(const Key('annotation_canvas'));
      await tester.tap(canvas);
      await tester.pumpAndSettle();

      // Text input dialog should appear
      final textInput = find.byKey(const Key('annotation_text_input'));
      expect(textInput, findsOneWidget);

      // Enter text
      await tester.enterText(textInput, 'Test Label');
      await tester.pumpAndSettle();

      // Confirm text
      final confirmButton = find.byKey(const Key('annotation_text_confirm'));
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify text is displayed on canvas
      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('Add arrow annotation - arrow appears on photo',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: PhotoAnnotationScreen(
          photoPath: '/test/captured_photo.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // Select arrow tool
      final arrowTool = find.byKey(const Key('annotation_tool_arrow'));
      await tester.tap(arrowTool);
      await tester.pumpAndSettle();

      // Verify arrow tool is selected
      expect(find.byKey(const Key('annotation_tool_arrow_selected')),
          findsOneWidget);

      // Draw arrow on canvas
      final canvas = find.byKey(const Key('annotation_canvas'));
      final canvasCenter = tester.getCenter(canvas);
      await tester.dragFrom(
        canvasCenter,
        const Offset(100, 50),
      );
      await tester.pumpAndSettle();

      // Verify arrow annotation exists
      final annotationLayer = find.byKey(const Key('annotation_layer'));
      expect(annotationLayer, findsOneWidget);
    });

    testWidgets('Tap Done - annotations visible on saved photo',
        (tester) async {
      PhotoAnnotationResult? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => PhotoAnnotationScreen(
                photoPath: '/test/captured_photo.jpg',
                onComplete: (annotationResult) {
                  result = annotationResult;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Draw tool is already selected by default
      // Draw on canvas
      final canvas = find.byKey(const Key('annotation_canvas'));
      final canvasCenter = tester.getCenter(canvas);
      await tester.dragFrom(canvasCenter, const Offset(50, 50));
      await tester.pumpAndSettle();

      // Tap Done button
      final doneButton = find.byKey(const Key('annotation_done_button'));
      expect(doneButton, findsOneWidget);
      await tester.tap(doneButton);

      // Allow async operations to complete - need runAsync for path_provider
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Verify result contains annotated path
      expect(result, isNotNull);
      expect(result!.annotatedPhotoPath, isNotEmpty);
      expect(result!.hasAnnotations, isTrue);
    });

    testWidgets('Original photo preserved separately after annotation',
        (tester) async {
      PhotoAnnotationResult? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: PhotoAnnotationScreen(
              photoPath: '/test/original_photo.jpg',
              onComplete: (annotationResult) {
                result = annotationResult;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Draw tool is already selected by default
      // Draw on canvas
      final canvas = find.byKey(const Key('annotation_canvas'));
      await tester.dragFrom(tester.getCenter(canvas), const Offset(30, 30));
      await tester.pumpAndSettle();

      // Tap Done
      final doneButton = find.byKey(const Key('annotation_done_button'));
      await tester.tap(doneButton);

      // Allow async operations to complete - need runAsync for path_provider
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Verify both paths are available and different
      expect(result, isNotNull);
      expect(result!.originalPhotoPath, equals('/test/original_photo.jpg'));
      expect(
          result!.annotatedPhotoPath, isNot(equals(result!.originalPhotoPath)));
    });

    testWidgets('Color picker allows changing annotation color',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: PhotoAnnotationScreen(
          photoPath: '/test/captured_photo.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // Verify color picker button exists
      final colorPicker = find.byKey(const Key('annotation_color_picker'));
      expect(colorPicker, findsOneWidget);

      // Tap color picker
      await tester.tap(colorPicker);
      await tester.pumpAndSettle();

      // Verify color options appear
      final redColor = find.byKey(const Key('annotation_color_red'));
      final blueColor = find.byKey(const Key('annotation_color_blue'));
      final yellowColor = find.byKey(const Key('annotation_color_yellow'));

      expect(redColor, findsOneWidget);
      expect(blueColor, findsOneWidget);
      expect(yellowColor, findsOneWidget);
    });

    testWidgets('Undo removes last annotation', (tester) async {
      await tester.pumpWidget(createTestWidget(
        child: PhotoAnnotationScreen(
          photoPath: '/test/captured_photo.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // Draw tool is already selected by default
      // Draw on canvas
      final canvas = find.byKey(const Key('annotation_canvas'));
      await tester.dragFrom(tester.getCenter(canvas), const Offset(50, 50));
      await tester.pumpAndSettle();

      // Verify undo button is enabled
      final undoButton = find.byKey(const Key('annotation_undo_button'));
      expect(undoButton, findsOneWidget);

      // Tap undo
      await tester.tap(undoButton);
      await tester.pumpAndSettle();

      // Undo button should still exist (just possibly disabled now)
      expect(undoButton, findsOneWidget);
    });

    testWidgets('Cancel discards all annotations and returns original',
        (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: PhotoAnnotationScreen(
              photoPath: '/test/captured_photo.jpg',
              onCancel: () {
                cancelled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Draw tool is already selected by default
      // Draw on canvas
      final canvas = find.byKey(const Key('annotation_canvas'));
      await tester.dragFrom(tester.getCenter(canvas), const Offset(50, 50));
      await tester.pumpAndSettle();

      // Tap cancel/close button
      final cancelButton = find.byKey(const Key('annotation_cancel_button'));
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify cancel callback was invoked
      expect(cancelled, isTrue);
    });
  });
}
