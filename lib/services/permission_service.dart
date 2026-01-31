import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions.
abstract class PermissionService {
  /// Checks the current camera permission status.
  Future<PermissionStatus> checkCameraPermission();

  /// Requests camera permission from the user.
  Future<PermissionStatus> requestCameraPermission();

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
  Future<bool> openAppSettings() async {
    return openAppSettings();
  }
}

/// Provider for the permission service.
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return DefaultPermissionService();
});
