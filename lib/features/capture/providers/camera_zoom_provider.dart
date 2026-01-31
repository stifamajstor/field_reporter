import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/camera_service.dart';

/// Represents the camera zoom state.
@immutable
class CameraZoomState {
  const CameraZoomState({
    required this.zoomLevel,
    required this.minZoom,
    required this.maxZoom,
    required this.isZooming,
  });

  const CameraZoomState.initial()
      : zoomLevel = 1.0,
        minZoom = 1.0,
        maxZoom = 10.0,
        isZooming = false;

  final double zoomLevel;
  final double minZoom;
  final double maxZoom;
  final bool isZooming;

  bool get isZoomed => zoomLevel > 1.0;

  String get formattedZoomLevel {
    if (zoomLevel >= 10.0) {
      return '${zoomLevel.toStringAsFixed(0)}x';
    }
    return '${zoomLevel.toStringAsFixed(1)}x';
  }

  CameraZoomState copyWith({
    double? zoomLevel,
    double? minZoom,
    double? maxZoom,
    bool? isZooming,
  }) {
    return CameraZoomState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      isZooming: isZooming ?? this.isZooming,
    );
  }
}

/// Notifier for managing camera zoom state.
class CameraZoomNotifier extends StateNotifier<CameraZoomState> {
  CameraZoomNotifier({
    required this.cameraService,
  }) : super(const CameraZoomState.initial());

  final CameraService cameraService;
  double _baseZoomLevel = 1.0;

  void initialize() {
    state = CameraZoomState(
      zoomLevel: cameraService.currentZoomLevel,
      minZoom: cameraService.minZoomLevel,
      maxZoom: cameraService.maxZoomLevel,
      isZooming: false,
    );
  }

  void onScaleStart() {
    _baseZoomLevel = state.zoomLevel;
    state = state.copyWith(isZooming: true);
  }

  Future<void> onScaleUpdate(double scale) async {
    final newZoom =
        (_baseZoomLevel * scale).clamp(state.minZoom, state.maxZoom);
    await cameraService.setZoomLevel(newZoom);
    state = state.copyWith(zoomLevel: newZoom);
  }

  void onScaleEnd() {
    state = state.copyWith(isZooming: false);
  }

  Future<void> setZoomLevel(double zoom) async {
    final clampedZoom = zoom.clamp(state.minZoom, state.maxZoom);
    await cameraService.setZoomLevel(clampedZoom);
    state = state.copyWith(zoomLevel: clampedZoom);
  }

  void reset() {
    _baseZoomLevel = 1.0;
    state = const CameraZoomState.initial();
  }
}

/// Provider for camera zoom state.
final cameraZoomProvider =
    StateNotifierProvider<CameraZoomNotifier, CameraZoomState>((ref) {
  return CameraZoomNotifier(
    cameraService: ref.watch(cameraServiceProvider),
  );
});
