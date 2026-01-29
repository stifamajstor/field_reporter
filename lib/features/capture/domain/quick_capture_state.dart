import 'package:flutter/foundation.dart';

import '../../projects/domain/project.dart';

/// State for the quick capture flow.
@immutable
sealed class QuickCaptureState {
  const QuickCaptureState();

  /// Initial state, no capture in progress.
  const factory QuickCaptureState.initial() = QuickCaptureInitial;

  /// Camera is active and ready to capture.
  const factory QuickCaptureState.capturing({
    required CaptureType type,
  }) = QuickCaptureCapturing;

  /// Photo has been captured, waiting for project selection.
  const factory QuickCaptureState.photoCaptured({
    required String photoPath,
  }) = QuickCapturePhotoCaptured;

  /// Project has been selected, waiting for report selection.
  const factory QuickCaptureState.projectSelected({
    required String photoPath,
    required Project project,
  }) = QuickCaptureProjectSelected;

  /// Photo has been added to report successfully.
  const factory QuickCaptureState.completed({
    required String photoPath,
    required Project project,
    required String reportId,
  }) = QuickCaptureCompleted;

  /// An error occurred during the capture flow.
  const factory QuickCaptureState.error({
    required String message,
  }) = QuickCaptureError;
}

/// Initial state, no capture in progress.
class QuickCaptureInitial extends QuickCaptureState {
  const QuickCaptureInitial();
}

/// Camera is active and ready to capture.
class QuickCaptureCapturing extends QuickCaptureState {
  const QuickCaptureCapturing({required this.type});

  final CaptureType type;
}

/// Photo has been captured, waiting for project selection.
class QuickCapturePhotoCaptured extends QuickCaptureState {
  const QuickCapturePhotoCaptured({required this.photoPath});

  final String photoPath;
}

/// Project has been selected, waiting for report selection.
class QuickCaptureProjectSelected extends QuickCaptureState {
  const QuickCaptureProjectSelected({
    required this.photoPath,
    required this.project,
  });

  final String photoPath;
  final Project project;
}

/// Photo has been added to report successfully.
class QuickCaptureCompleted extends QuickCaptureState {
  const QuickCaptureCompleted({
    required this.photoPath,
    required this.project,
    required this.reportId,
  });

  final String photoPath;
  final Project project;
  final String reportId;
}

/// An error occurred during the capture flow.
class QuickCaptureError extends QuickCaptureState {
  const QuickCaptureError({required this.message});

  final String message;
}

/// Type of capture.
enum CaptureType {
  photo,
  video,
  audio,
  note,
}
