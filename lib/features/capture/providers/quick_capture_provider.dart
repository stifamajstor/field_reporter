import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../projects/domain/project.dart';
import '../domain/quick_capture_state.dart';

part 'quick_capture_provider.g.dart';

/// Provider for managing quick capture state and flow.
@riverpod
class QuickCaptureNotifier extends _$QuickCaptureNotifier {
  @override
  QuickCaptureState build() {
    return const QuickCaptureState.initial();
  }

  /// Starts the capture flow with the specified type.
  void startCapture(CaptureType type) {
    state = QuickCaptureState.capturing(type: type);
  }

  /// Called when a photo has been captured.
  void capturePhoto(String photoPath) {
    state = QuickCaptureState.photoCaptured(photoPath: photoPath);
  }

  /// Called when a project has been selected.
  void selectProject(Project project) {
    final currentState = state;
    if (currentState is QuickCapturePhotoCaptured) {
      state = QuickCaptureState.projectSelected(
        photoPath: currentState.photoPath,
        project: project,
      );
    }
  }

  /// Called when an existing report is selected and photo should be added.
  void selectReportAndAddPhoto(String reportId) {
    final currentState = state;
    if (currentState is QuickCaptureProjectSelected) {
      // In a real implementation, this would save the photo to the report
      state = QuickCaptureState.completed(
        photoPath: currentState.photoPath,
        project: currentState.project,
        reportId: reportId,
      );
    }
  }

  /// Called when a new report should be created and photo added to it.
  void createReportAndAddPhoto(String reportTitle) {
    final currentState = state;
    if (currentState is QuickCaptureProjectSelected) {
      // In a real implementation, this would create the report first
      // then add the photo to it
      final newReportId = 'new-report-${DateTime.now().millisecondsSinceEpoch}';
      state = QuickCaptureState.completed(
        photoPath: currentState.photoPath,
        project: currentState.project,
        reportId: newReportId,
      );
    }
  }

  /// Resets the capture state to initial.
  void reset() {
    state = const QuickCaptureState.initial();
  }
}
