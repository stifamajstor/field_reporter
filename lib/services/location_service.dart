import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

/// Permission status for location services.
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  serviceDisabled,
}

/// Represents a geographic position.
class LocationPosition {
  final double latitude;
  final double longitude;

  const LocationPosition({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() =>
      'LocationPosition(latitude: $latitude, longitude: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPosition &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Exception thrown by LocationService.
class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

/// Service for handling location-related operations.
abstract class LocationService {
  /// Checks the current location permission status.
  Future<LocationPermissionStatus> checkPermission();

  /// Requests location permission from the user.
  Future<LocationPermissionStatus> requestPermission();

  /// Gets the current GPS position.
  Future<LocationPosition> getCurrentPosition();

  /// Reverse geocodes coordinates to an address string.
  Future<String> reverseGeocode(double latitude, double longitude);

  /// Opens the app settings for the user to grant permissions.
  Future<void> openAppSettings();
}

/// Default implementation of LocationService using geolocator and geocoding.
class DefaultLocationService implements LocationService {
  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationPosition> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LocationPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      throw const LocationServiceException('Location services are disabled');
    } on PermissionDeniedException {
      throw const LocationServiceException('Location permission denied');
    } catch (e) {
      throw LocationServiceException('Failed to get location: $e');
    }
  }

  @override
  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) {
        return 'Unknown location';
      }

      final place = placemarks.first;
      final parts = <String>[
        if (place.street?.isNotEmpty == true) place.street!,
        if (place.locality?.isNotEmpty == true) place.locality!,
        if (place.administrativeArea?.isNotEmpty == true)
          place.administrativeArea!,
      ];

      return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
    } catch (e) {
      return 'Unknown location';
    }
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }
}

/// Provider for LocationService.
@riverpod
LocationService locationService(Ref ref) {
  return DefaultLocationService();
}
