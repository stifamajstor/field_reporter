import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/camera_service.dart';
import '../../../services/permission_service.dart';

/// Represents the state of the camera.
@immutable
class CameraState {
  const CameraState({
    required this.permissionStatus,
    required this.isInitialized,
    required this.isPreviewActive,
    this.errorMessage,
  });

  const CameraState.initial()
      : permissionStatus = PermissionStatus.denied,
        isInitialized = false,
        isPreviewActive = false,
        errorMessage = null;

  final PermissionStatus permissionStatus;
  final bool isInitialized;
  final bool isPreviewActive;
  final String? errorMessage;

  bool get hasPermission => permissionStatus.isGranted;
  bool get hasError => errorMessage != null;

  CameraState copyWith({
    PermissionStatus? permissionStatus,
    bool? isInitialized,
    bool? isPreviewActive,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CameraState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isInitialized: isInitialized ?? this.isInitialized,
      isPreviewActive: isPreviewActive ?? this.isPreviewActive,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier for managing camera state.
class CameraStateNotifier extends StateNotifier<CameraState> {
  CameraStateNotifier({
    required this.permissionService,
    required this.cameraService,
  }) : super(const CameraState.initial());

  final PermissionService permissionService;
  final CameraService cameraService;

  Future<void> checkPermission() async {
    final status = await permissionService.checkCameraPermission();
    state = state.copyWith(permissionStatus: status);

    if (status.isGranted) {
      await initializeCamera();
    }
  }

  Future<void> requestPermission() async {
    final status = await permissionService.requestCameraPermission();
    state = state.copyWith(permissionStatus: status);

    if (status.isGranted) {
      await initializeCamera();
    } else if (status.isPermanentlyDenied) {
      await permissionService.openAppSettings();
    }
  }

  Future<void> initializeCamera() async {
    try {
      await cameraService.openCamera();
      state = state.copyWith(
        isInitialized: true,
        isPreviewActive: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to initialize camera',
        isInitialized: false,
        isPreviewActive: false,
      );
    }
  }

  Future<void> closeCamera() async {
    await cameraService.closeCamera();
    state = state.copyWith(
      isInitialized: false,
      isPreviewActive: false,
    );
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for camera state.
final cameraStateProvider =
    StateNotifierProvider<CameraStateNotifier, CameraState>((ref) {
  return CameraStateNotifier(
    permissionService: ref.watch(permissionServiceProvider),
    cameraService: ref.watch(cameraServiceProvider),
  );
});
