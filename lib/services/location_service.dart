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

/// Address suggestion for autocomplete.
class AddressSuggestion {
  final String address;
  final double latitude;
  final double longitude;

  const AddressSuggestion({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() =>
      'AddressSuggestion(address: $address, latitude: $latitude, longitude: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressSuggestion &&
          runtimeType == other.runtimeType &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => address.hashCode ^ latitude.hashCode ^ longitude.hashCode;
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

  /// Searches for addresses matching the query and returns suggestions.
  Future<List<AddressSuggestion>> searchAddress(String query);

  /// Geocodes an address string to coordinates.
  Future<LocationPosition> geocodeAddress(String address);
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

  @override
  Future<List<AddressSuggestion>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final locations = await geocoding.locationFromAddress(query);
      final suggestions = <AddressSuggestion>[];

      for (final location in locations.take(5)) {
        final placemarks = await geocoding.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[
            if (place.name?.isNotEmpty == true &&
                place.name != place.street &&
                place.name != place.locality)
              place.name!,
            if (place.street?.isNotEmpty == true) place.street!,
            if (place.locality?.isNotEmpty == true) place.locality!,
            if (place.administrativeArea?.isNotEmpty == true)
              place.administrativeArea!,
          ];
          final address =
              parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
          suggestions.add(AddressSuggestion(
            address: address,
            latitude: location.latitude,
            longitude: location.longitude,
          ));
        }
      }

      return suggestions;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<LocationPosition> geocodeAddress(String address) async {
    try {
      final locations = await geocoding.locationFromAddress(address);
      if (locations.isEmpty) {
        throw const LocationServiceException('Address not found');
      }
      final location = locations.first;
      return LocationPosition(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (e) {
      throw LocationServiceException('Failed to geocode address: $e');
    }
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
