import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/location_service.dart';

const _kGpsOverlayEnabledKey = 'gps_overlay_enabled';

/// Threshold in seconds after which a cached location is considered stale.
const int kStaleLocationThresholdSeconds = 60;

/// State for GPS overlay display.
@immutable
class GpsOverlayState {
  const GpsOverlayState({
    required this.isEnabled,
    required this.permissionStatus,
    this.currentPosition,
    this.isLoading = false,
    this.isLocationStale = false,
    this.positionTimestamp,
  });

  const GpsOverlayState.initial()
      : isEnabled = true,
        permissionStatus = LocationPermissionStatus.denied,
        currentPosition = null,
        isLoading = true,
        isLocationStale = false,
        positionTimestamp = null;

  final bool isEnabled;
  final LocationPermissionStatus permissionStatus;
  final LocationPosition? currentPosition;
  final bool isLoading;
  final bool isLocationStale;
  final DateTime? positionTimestamp;

  bool get hasPermission =>
      permissionStatus == LocationPermissionStatus.granted;
  bool get hasPosition => currentPosition != null;

  String get formattedLatitude {
    if (currentPosition == null) return '--';
    return currentPosition!.latitude.toStringAsFixed(4);
  }

  String get formattedLongitude {
    if (currentPosition == null) return '--';
    return currentPosition!.longitude.toStringAsFixed(4);
  }

  GpsOverlayState copyWith({
    bool? isEnabled,
    LocationPermissionStatus? permissionStatus,
    LocationPosition? currentPosition,
    bool? isLoading,
    bool? isLocationStale,
    DateTime? positionTimestamp,
    bool clearPosition = false,
  }) {
    return GpsOverlayState(
      isEnabled: isEnabled ?? this.isEnabled,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      currentPosition:
          clearPosition ? null : (currentPosition ?? this.currentPosition),
      isLoading: isLoading ?? this.isLoading,
      isLocationStale: isLocationStale ?? this.isLocationStale,
      positionTimestamp: positionTimestamp ?? this.positionTimestamp,
    );
  }
}

/// Notifier for GPS overlay state management.
class GpsOverlayNotifier extends StateNotifier<GpsOverlayState> {
  GpsOverlayNotifier({
    required this.locationService,
  }) : super(const GpsOverlayState.initial());

  final LocationService locationService;
  StreamSubscription<LocationPosition>? _positionSubscription;

  Future<void> initialize() async {
    // Load saved preference
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kGpsOverlayEnabledKey) ?? true;

    // Check permission
    final permissionStatus = await locationService.checkPermission();

    state = state.copyWith(
      isEnabled: isEnabled,
      permissionStatus: permissionStatus,
      isLoading: false,
    );

    if (permissionStatus == LocationPermissionStatus.granted) {
      await _startLocationUpdates();
    }
  }

  Future<void> _startLocationUpdates() async {
    try {
      final position = await locationService.getCurrentPosition();
      final timestamp = DateTime.now();
      state = state.copyWith(
        currentPosition: position,
        positionTimestamp: timestamp,
        isLocationStale: false,
      );
    } catch (e) {
      // GPS unavailable - try to get cached/last known position
      await _tryGetCachedLocation();
    }
  }

  Future<void> _tryGetCachedLocation() async {
    try {
      final cachedPosition = await locationService.getLastKnownPosition();
      if (cachedPosition != null) {
        final timestamp = await locationService.getLastKnownPositionTimestamp();
        final isStale = _isPositionStale(timestamp);
        state = state.copyWith(
          currentPosition: cachedPosition,
          positionTimestamp: timestamp,
          isLocationStale: isStale,
        );
      }
    } catch (e) {
      // No cached location available
    }
  }

  bool _isPositionStale(DateTime? timestamp) {
    if (timestamp == null) return true;
    final age = DateTime.now().difference(timestamp);
    return age.inSeconds > kStaleLocationThresholdSeconds;
  }

  void updatePosition(LocationPosition position, {bool isStale = false}) {
    state = state.copyWith(
      currentPosition: position,
      positionTimestamp: DateTime.now(),
      isLocationStale: isStale,
    );
  }

  Future<void> toggleOverlay() async {
    final newEnabled = !state.isEnabled;
    state = state.copyWith(isEnabled: newEnabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGpsOverlayEnabledKey, newEnabled);
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGpsOverlayEnabledKey, enabled);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for GPS overlay state.
final gpsOverlayProvider =
    StateNotifierProvider<GpsOverlayNotifier, GpsOverlayState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return GpsOverlayNotifier(locationService: locationService);
});
