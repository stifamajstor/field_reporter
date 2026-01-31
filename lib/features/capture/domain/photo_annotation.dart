import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Type of annotation tool.
enum AnnotationToolType {
  /// Freehand drawing tool.
  draw,

  /// Text label tool.
  text,

  /// Arrow/pointer tool.
  arrow,
}

/// A single annotation element on a photo.
@immutable
sealed class PhotoAnnotationElement {
  const PhotoAnnotationElement({
    required this.color,
  });

  /// Color of the annotation.
  final Color color;
}

/// Freehand drawing annotation.
@immutable
class DrawAnnotation extends PhotoAnnotationElement {
  const DrawAnnotation({
    required super.color,
    required this.points,
    required this.strokeWidth,
  });

  /// Points along the drawing path.
  final List<Offset> points;

  /// Width of the stroke.
  final double strokeWidth;
}

/// Text label annotation.
@immutable
class TextAnnotation extends PhotoAnnotationElement {
  const TextAnnotation({
    required super.color,
    required this.text,
    required this.position,
    required this.fontSize,
  });

  /// Text content.
  final String text;

  /// Position of the text.
  final Offset position;

  /// Font size of the text.
  final double fontSize;
}

/// Arrow annotation.
@immutable
class ArrowAnnotation extends PhotoAnnotationElement {
  const ArrowAnnotation({
    required super.color,
    required this.start,
    required this.end,
    required this.strokeWidth,
  });

  /// Start point of the arrow.
  final Offset start;

  /// End point of the arrow (where the arrowhead is).
  final Offset end;

  /// Width of the arrow stroke.
  final double strokeWidth;
}

/// State of the annotation editor.
@immutable
class PhotoAnnotationState {
  const PhotoAnnotationState({
    this.selectedTool = AnnotationToolType.draw,
    this.selectedColor = const Color(0xFFF43F5E), // AppColors.rose500
    this.annotations = const [],
    this.strokeWidth = 4.0,
    this.fontSize = 18.0,
    this.isShowingColorPicker = false,
    this.pendingTextPosition,
    this.currentDrawingPoints = const [],
    this.currentArrowStart,
  });

  /// Currently selected annotation tool.
  final AnnotationToolType selectedTool;

  /// Currently selected color.
  final Color selectedColor;

  /// List of completed annotations.
  final List<PhotoAnnotationElement> annotations;

  /// Current stroke width for drawing.
  final double strokeWidth;

  /// Current font size for text.
  final double fontSize;

  /// Whether the color picker is showing.
  final bool isShowingColorPicker;

  /// Position where user tapped to add text (if in text mode).
  final Offset? pendingTextPosition;

  /// Points being drawn in current stroke (not yet committed).
  final List<Offset> currentDrawingPoints;

  /// Start point of arrow being drawn.
  final Offset? currentArrowStart;

  /// Whether there are annotations that can be undone.
  bool get canUndo => annotations.isNotEmpty;

  /// Whether there are any annotations (including current drawing).
  bool get hasAnnotations =>
      annotations.isNotEmpty || currentDrawingPoints.isNotEmpty;

  PhotoAnnotationState copyWith({
    AnnotationToolType? selectedTool,
    Color? selectedColor,
    List<PhotoAnnotationElement>? annotations,
    double? strokeWidth,
    double? fontSize,
    bool? isShowingColorPicker,
    Offset? pendingTextPosition,
    bool clearPendingTextPosition = false,
    List<Offset>? currentDrawingPoints,
    Offset? currentArrowStart,
    bool clearCurrentArrowStart = false,
  }) {
    return PhotoAnnotationState(
      selectedTool: selectedTool ?? this.selectedTool,
      selectedColor: selectedColor ?? this.selectedColor,
      annotations: annotations ?? this.annotations,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fontSize: fontSize ?? this.fontSize,
      isShowingColorPicker: isShowingColorPicker ?? this.isShowingColorPicker,
      pendingTextPosition: clearPendingTextPosition
          ? null
          : (pendingTextPosition ?? this.pendingTextPosition),
      currentDrawingPoints: currentDrawingPoints ?? this.currentDrawingPoints,
      currentArrowStart: clearCurrentArrowStart
          ? null
          : (currentArrowStart ?? this.currentArrowStart),
    );
  }
}

/// Result from the annotation screen.
@immutable
class PhotoAnnotationResult {
  const PhotoAnnotationResult({
    required this.originalPhotoPath,
    required this.annotatedPhotoPath,
    required this.annotations,
  });

  /// Path to the original, unmodified photo.
  final String originalPhotoPath;

  /// Path to the photo with annotations rendered on top.
  final String annotatedPhotoPath;

  /// List of annotation elements applied.
  final List<PhotoAnnotationElement> annotations;

  /// Whether any annotations were added.
  bool get hasAnnotations => annotations.isNotEmpty;
}

/// Available colors for annotations.
class AnnotationColors {
  AnnotationColors._();

  static const red = Color(0xFFF43F5E); // rose500
  static const blue = Color(0xFF3B82F6);
  static const yellow = Color(0xFFFBBF24);
  static const green = Color(0xFF10B981); // emerald500
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  static const List<Color> all = [red, blue, yellow, green, white, black];
}
