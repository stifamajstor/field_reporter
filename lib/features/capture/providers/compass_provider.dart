import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/compass_service.dart';

const _kCompassEnabledKey = 'compass_enabled';

/// State for compass display.
@immutable
class CompassState {
  const CompassState({
    required this.isEnabled,
    required this.heading,
    required this.accuracy,
  });

  const CompassState.initial()
      : isEnabled = true,
        heading = 0.0,
        accuracy = 0.0;

  final bool isEnabled;
  final double heading; // In degrees, 0-360
  final double accuracy;

  /// Get cardinal direction from heading.
  String get cardinalDirection {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return 'N';
  }

  /// Get formatted heading string.
  String get formattedHeading => '${heading.round()}°';

  CompassState copyWith({
    bool? isEnabled,
    double? heading,
    double? accuracy,
  }) {
    return CompassState(
      isEnabled: isEnabled ?? this.isEnabled,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}

/// Notifier for compass state management.
class CompassNotifier extends StateNotifier<CompassState> {
  CompassNotifier({
    required this.compassService,
  }) : super(const CompassState.initial());

  final CompassService compassService;
  StreamSubscription<CompassData>? _subscription;

  Future<void> initialize() async {
    // Load saved preference
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kCompassEnabledKey) ?? true;

    state = state.copyWith(isEnabled: isEnabled);

    if (isEnabled) {
      _startListening();
    }
  }

  void _startListening() {
    compassService.startListening();
    _subscription?.cancel();
    _subscription = compassService.compassStream.listen(_onCompassData);
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    compassService.stopListening();
  }

  void _onCompassData(CompassData data) {
    state = state.copyWith(
      heading: data.heading,
      accuracy: data.accuracy,
    );
  }

  void updateFromData(CompassData data) {
    _onCompassData(data);
  }

  Future<void> toggleOverlay() async {
    final newEnabled = !state.isEnabled;
    state = state.copyWith(isEnabled: newEnabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompassEnabledKey, newEnabled);

    if (newEnabled) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompassEnabledKey, enabled);

    if (enabled) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}

/// Provider for compass state.
final compassProvider =
    StateNotifierProvider<CompassNotifier, CompassState>((ref) {
  final compassService = ref.watch(compassServiceProvider);
  return CompassNotifier(compassService: compassService);
});
