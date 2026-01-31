import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/camera_service.dart';

/// Represents the camera focus state.
@immutable
class CameraFocusState {
  const CameraFocusState({
    required this.focusPoint,
    required this.isFocusing,
    required this.showIndicator,
  });

  const CameraFocusState.initial()
      : focusPoint = null,
        isFocusing = false,
        showIndicator = false;

  /// The current focus point in screen coordinates (pixels).
  final Offset? focusPoint;

  /// Whether the camera is currently focusing.
  final bool isFocusing;

  /// Whether to show the focus indicator animation.
  final bool showIndicator;

  CameraFocusState copyWith({
    Offset? focusPoint,
    bool? isFocusing,
    bool? showIndicator,
    bool clearFocusPoint = false,
  }) {
    return CameraFocusState(
      focusPoint: clearFocusPoint ? null : (focusPoint ?? this.focusPoint),
      isFocusing: isFocusing ?? this.isFocusing,
      showIndicator: showIndicator ?? this.showIndicator,
    );
  }
}

/// Notifier for managing camera focus state.
class CameraFocusNotifier extends StateNotifier<CameraFocusState> {
  CameraFocusNotifier({
    required this.cameraService,
  }) : super(const CameraFocusState.initial());

  final CameraService cameraService;
  Timer? _hideIndicatorTimer;

  /// Duration to show the focus indicator before hiding it.
  static const indicatorDuration = Duration(milliseconds: 1200);

  /// Handles a tap on the camera preview to set focus point.
  /// [tapPosition] is the tap position in screen coordinates.
  /// [previewSize] is the size of the camera preview widget.
  Future<void> onTapToFocus(Offset tapPosition, Size previewSize) async {
    // Cancel any existing timer
    _hideIndicatorTimer?.cancel();

    // Show focus indicator at tap position
    state = CameraFocusState(
      focusPoint: tapPosition,
      isFocusing: true,
      showIndicator: true,
    );

    // Convert screen coordinates to normalized coordinates (0.0 to 1.0)
    final normalizedX = tapPosition.dx / previewSize.width;
    final normalizedY = tapPosition.dy / previewSize.height;

    // Set focus on camera
    await cameraService.setFocusPoint(normalizedX, normalizedY);

    // Mark focusing as complete
    state = state.copyWith(isFocusing: false);

    // Start timer to hide indicator
    _hideIndicatorTimer = Timer(indicatorDuration, () {
      if (mounted) {
        state = state.copyWith(
          showIndicator: false,
          clearFocusPoint: true,
        );
      }
    });
  }

  /// Clears the focus indicator.
  void clearFocus() {
    _hideIndicatorTimer?.cancel();
    state = const CameraFocusState.initial();
  }

  @override
  void dispose() {
    _hideIndicatorTimer?.cancel();
    super.dispose();
  }
}

/// Provider for camera focus state.
final cameraFocusProvider =
    StateNotifierProvider<CameraFocusNotifier, CameraFocusState>((ref) {
  return CameraFocusNotifier(
    cameraService: ref.watch(cameraServiceProvider),
  );
});
