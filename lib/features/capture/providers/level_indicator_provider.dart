import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/accelerometer_service.dart';

const _kLevelIndicatorEnabledKey = 'level_indicator_enabled';
const _kLevelThresholdDegrees =
    2.0; // Degrees within which device is considered level

/// State for level indicator display.
@immutable
class LevelIndicatorState {
  const LevelIndicatorState({
    required this.isEnabled,
    required this.tiltAngle,
    required this.isLevel,
    this.wasLevelPreviously = false,
  });

  const LevelIndicatorState.initial()
      : isEnabled = true,
        tiltAngle = 0.0,
        isLevel = true,
        wasLevelPreviously = false;

  final bool isEnabled;
  final double
      tiltAngle; // In degrees, negative = left tilt, positive = right tilt
  final bool isLevel;
  final bool wasLevelPreviously;

  LevelIndicatorState copyWith({
    bool? isEnabled,
    double? tiltAngle,
    bool? isLevel,
    bool? wasLevelPreviously,
  }) {
    return LevelIndicatorState(
      isEnabled: isEnabled ?? this.isEnabled,
      tiltAngle: tiltAngle ?? this.tiltAngle,
      isLevel: isLevel ?? this.isLevel,
      wasLevelPreviously: wasLevelPreviously ?? this.wasLevelPreviously,
    );
  }
}

/// Notifier for level indicator state management.
class LevelIndicatorNotifier extends StateNotifier<LevelIndicatorState> {
  LevelIndicatorNotifier({
    required this.accelerometerService,
  }) : super(const LevelIndicatorState.initial());

  final AccelerometerService accelerometerService;
  StreamSubscription<AccelerometerData>? _subscription;

  Future<void> initialize() async {
    // Load saved preference
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kLevelIndicatorEnabledKey) ?? true;

    state = state.copyWith(isEnabled: isEnabled);

    if (isEnabled) {
      _startListening();
    }
  }

  void _startListening() {
    accelerometerService.startListening();
    _subscription?.cancel();
    _subscription =
        accelerometerService.accelerometerStream.listen(_onAccelerometerData);
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    accelerometerService.stopListening();
  }

  void _onAccelerometerData(AccelerometerData data) {
    // Calculate tilt angle from accelerometer x-axis
    // When device is level, x should be 0
    // When tilted left, x is negative; when tilted right, x is positive
    // Using atan2 for more accurate angle calculation
    final tiltRadians = math.atan2(data.x, data.z);
    final tiltDegrees = tiltRadians * (180 / math.pi);

    final isLevel = tiltDegrees.abs() <= _kLevelThresholdDegrees;
    final wasLevelPreviously = state.isLevel;

    // Trigger haptic feedback when transitioning to level state
    if (isLevel && !wasLevelPreviously) {
      HapticFeedback.lightImpact();
    }

    state = state.copyWith(
      tiltAngle: tiltDegrees,
      isLevel: isLevel,
      wasLevelPreviously: wasLevelPreviously,
    );
  }

  void updateFromData(AccelerometerData data) {
    _onAccelerometerData(data);
  }

  Future<void> toggleOverlay() async {
    final newEnabled = !state.isEnabled;
    state = state.copyWith(isEnabled: newEnabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLevelIndicatorEnabledKey, newEnabled);

    if (newEnabled) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLevelIndicatorEnabledKey, enabled);

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

/// Provider for level indicator state.
final levelIndicatorProvider =
    StateNotifierProvider<LevelIndicatorNotifier, LevelIndicatorState>((ref) {
  final accelerometerService = ref.watch(accelerometerServiceProvider);
  return LevelIndicatorNotifier(accelerometerService: accelerometerService);
});
