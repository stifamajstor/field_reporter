import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/photo_annotation.dart';

/// Provider for photo annotation state.
final photoAnnotationProvider =
    NotifierProvider<PhotoAnnotationNotifier, PhotoAnnotationState>(
  PhotoAnnotationNotifier.new,
);

/// Notifier for managing photo annotation state.
class PhotoAnnotationNotifier extends Notifier<PhotoAnnotationState> {
  @override
  PhotoAnnotationState build() {
    return const PhotoAnnotationState();
  }

  /// Select an annotation tool.
  void selectTool(AnnotationToolType tool) {
    state = state.copyWith(
      selectedTool: tool,
      isShowingColorPicker: false,
      clearPendingTextPosition: true,
    );
  }

  /// Select a color for annotations.
  void selectColor(Color color) {
    state = state.copyWith(
      selectedColor: color,
      isShowingColorPicker: false,
    );
  }

  /// Toggle the color picker visibility.
  void toggleColorPicker() {
    state = state.copyWith(isShowingColorPicker: !state.isShowingColorPicker);
  }

  /// Hide the color picker.
  void hideColorPicker() {
    state = state.copyWith(isShowingColorPicker: false);
  }

  /// Start a new drawing stroke at the given point.
  void startDrawing(Offset point) {
    if (state.selectedTool != AnnotationToolType.draw) return;
    state = state.copyWith(currentDrawingPoints: [point]);
  }

  /// Continue drawing at the given point.
  void continueDrawing(Offset point) {
    if (state.selectedTool != AnnotationToolType.draw) return;
    if (state.currentDrawingPoints.isEmpty) return;
    state = state.copyWith(
      currentDrawingPoints: [...state.currentDrawingPoints, point],
    );
  }

  /// End the current drawing stroke and commit it.
  void endDrawing() {
    if (state.selectedTool != AnnotationToolType.draw) return;
    if (state.currentDrawingPoints.length < 2) {
      state = state.copyWith(currentDrawingPoints: []);
      return;
    }

    final annotation = DrawAnnotation(
      color: state.selectedColor,
      points: List.unmodifiable(state.currentDrawingPoints),
      strokeWidth: state.strokeWidth,
    );

    state = state.copyWith(
      annotations: [...state.annotations, annotation],
      currentDrawingPoints: [],
    );
  }

  /// Start drawing an arrow at the given point.
  void startArrow(Offset point) {
    if (state.selectedTool != AnnotationToolType.arrow) return;
    state = state.copyWith(currentArrowStart: point);
  }

  /// End arrow and commit it.
  void endArrow(Offset endPoint) {
    if (state.selectedTool != AnnotationToolType.arrow) return;
    final start = state.currentArrowStart;
    if (start == null) return;

    // Only create arrow if there's meaningful distance
    if ((endPoint - start).distance < 10) {
      state = state.copyWith(clearCurrentArrowStart: true);
      return;
    }

    final annotation = ArrowAnnotation(
      color: state.selectedColor,
      start: start,
      end: endPoint,
      strokeWidth: state.strokeWidth,
    );

    state = state.copyWith(
      annotations: [...state.annotations, annotation],
      clearCurrentArrowStart: true,
    );
  }

  /// Set pending text position when tapping in text mode.
  void setTextPosition(Offset position) {
    if (state.selectedTool != AnnotationToolType.text) return;
    state = state.copyWith(pendingTextPosition: position);
  }

  /// Add a text annotation at the pending position.
  void addText(String text) {
    final position = state.pendingTextPosition;
    if (position == null || text.isEmpty) {
      state = state.copyWith(clearPendingTextPosition: true);
      return;
    }

    final annotation = TextAnnotation(
      color: state.selectedColor,
      text: text,
      position: position,
      fontSize: state.fontSize,
    );

    state = state.copyWith(
      annotations: [...state.annotations, annotation],
      clearPendingTextPosition: true,
    );
  }

  /// Cancel pending text input.
  void cancelTextInput() {
    state = state.copyWith(clearPendingTextPosition: true);
  }

  /// Undo the last annotation.
  void undo() {
    if (!state.canUndo) return;
    final newAnnotations = List<PhotoAnnotationElement>.from(state.annotations)
      ..removeLast();
    state = state.copyWith(annotations: newAnnotations);
  }

  /// Clear all annotations.
  void clearAll() {
    state = const PhotoAnnotationState();
  }

  /// Reset state for a new annotation session.
  void reset() {
    state = const PhotoAnnotationState();
  }
}
