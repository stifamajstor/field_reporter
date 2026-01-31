import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kTimestampOverlayEnabledKey = 'timestamp_overlay_enabled';

/// State for timestamp overlay display.
@immutable
class TimestampOverlayState {
  const TimestampOverlayState({
    required this.isEnabled,
    required this.currentTime,
  });

  const TimestampOverlayState.initial()
      : isEnabled = true,
        currentTime = null;

  final bool isEnabled;
  final DateTime? currentTime;

  /// Returns formatted timestamp string: "YYYY-MM-DD HH:MM:SS"
  String get formattedTimestamp {
    final time = currentTime ?? DateTime.now();
    return '${time.year.toString().padLeft(4, '0')}-'
        '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  TimestampOverlayState copyWith({
    bool? isEnabled,
    DateTime? currentTime,
  }) {
    return TimestampOverlayState(
      isEnabled: isEnabled ?? this.isEnabled,
      currentTime: currentTime ?? this.currentTime,
    );
  }
}

/// Notifier for timestamp overlay state management.
class TimestampOverlayNotifier extends StateNotifier<TimestampOverlayState> {
  TimestampOverlayNotifier() : super(const TimestampOverlayState.initial());

  Timer? _timer;

  Future<void> initialize() async {
    // Load saved preference
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kTimestampOverlayEnabledKey) ?? true;

    state = state.copyWith(
      isEnabled: isEnabled,
      currentTime: DateTime.now(),
    );

    // Start real-time updates
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(currentTime: DateTime.now());
    });
  }

  Future<void> toggleOverlay() async {
    final newEnabled = !state.isEnabled;
    state = state.copyWith(isEnabled: newEnabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTimestampOverlayEnabledKey, newEnabled);
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTimestampOverlayEnabledKey, enabled);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for timestamp overlay state.
final timestampOverlayProvider =
    StateNotifierProvider<TimestampOverlayNotifier, TimestampOverlayState>(
        (ref) {
  return TimestampOverlayNotifier();
});
