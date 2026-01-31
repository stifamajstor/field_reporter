import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions.
abstract class PermissionService {
  /// Checks the current camera permission status.
  Future<PermissionStatus> checkCameraPermission();

  /// Requests camera permission from the user.
  Future<PermissionStatus> requestCameraPermission();

  /// Checks the current microphone permission status.
  Future<PermissionStatus> checkMicrophonePermission();

  /// Requests microphone permission from the user.
  Future<PermissionStatus> requestMicrophonePermission();

  /// Opens the app settings page.
  Future<bool> openAppSettings();
}

/// Default implementation using permission_handler package.
class DefaultPermissionService implements PermissionService {
  @override
  Future<PermissionStatus> checkCameraPermission() async {
    return Permission.camera.status;
  }

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    return Permission.camera.request();
  }

  @override
  Future<PermissionStatus> checkMicrophonePermission() async {
    return Permission.microphone.status;
  }

  @override
  Future<PermissionStatus> requestMicrophonePermission() async {
    return Permission.microphone.request();
  }

  @override
  Future<bool> openAppSettings() async {
    return openAppSettings();
  }
}

/// Provider for the permission service.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return DefaultPermissionService();
});
