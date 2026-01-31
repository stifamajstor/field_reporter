import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

// Re-export PermissionStatus for consumers of this service
export 'package:permission_handler/permission_handler.dart'
    show PermissionStatus;

/// Service for handling app permissions.
abstract class PermissionService {
  /// Checks the current camera permission status.
  Future<ph.PermissionStatus> checkCameraPermission();

  /// Requests camera permission from the user.
  Future<ph.PermissionStatus> requestCameraPermission();

  /// Checks the current microphone permission status.
  Future<ph.PermissionStatus> checkMicrophonePermission();

  /// Requests microphone permission from the user.
  Future<ph.PermissionStatus> requestMicrophonePermission();

  /// Opens the app settings page.
  Future<bool> openAppSettings();
}

/// Default implementation using permission_handler package.
class DefaultPermissionService implements PermissionService {
  @override
  Future<ph.PermissionStatus> checkCameraPermission() async {
    return ph.Permission.camera.status;
  }

  @override
  Future<ph.PermissionStatus> requestCameraPermission() async {
    return ph.Permission.camera.request();
  }

  @override
  Future<ph.PermissionStatus> checkMicrophonePermission() async {
    return ph.Permission.microphone.status;
  }

  @override
  Future<ph.PermissionStatus> requestMicrophonePermission() async {
    return ph.Permission.microphone.request();
  }

  @override
  Future<bool> openAppSettings() async {
    return ph.openAppSettings();
  }
}

/// Provider for the permission service.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return DefaultPermissionService();
});
