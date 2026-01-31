import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Represents compass sensor data.
class CompassData {
  final double heading;
  final double accuracy;

  const CompassData({
    required this.heading,
    required this.accuracy,
  });

  @override
  String toString() => 'CompassData(heading: $heading, accuracy: $accuracy)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompassData &&
          runtimeType == other.runtimeType &&
          heading == other.heading &&
          accuracy == other.accuracy;

  @override
  int get hashCode => heading.hashCode ^ accuracy.hashCode;
}

/// Service for handling compass sensor data.
abstract class CompassService {
  /// Stream of compass data updates.
  Stream<CompassData> get compassStream;

  /// Current compass data.
  CompassData get currentData;

  /// Start listening to compass events.
  void startListening();

  /// Stop listening to compass events.
  void stopListening();
}

/// Default implementation of CompassService using sensors_plus magnetometer.
class DefaultCompassService implements CompassService {
  StreamSubscription<MagnetometerEvent>? _subscription;
  final _controller = StreamController<CompassData>.broadcast();
  CompassData _currentData = const CompassData(heading: 0, accuracy: 1);

  @override
  Stream<CompassData> get compassStream => _controller.stream;

  @override
  CompassData get currentData => _currentData;

  @override
  void startListening() {
    _subscription?.cancel();
    _subscription = magnetometerEventStream().listen((event) {
      // Calculate heading from magnetometer data
      // This is a simplified calculation - real apps would use more sophisticated algorithms
      final heading = _calculateHeading(event.x, event.y);
      _currentData = CompassData(
        heading: heading,
        accuracy: 1.0, // sensors_plus doesn't provide accuracy
      );
      _controller.add(_currentData);
    });
  }

  double _calculateHeading(double x, double y) {
    // Calculate heading using atan2
    // This gives us the angle in radians, which we convert to degrees
    var heading = (180 / 3.14159265359) *
        (3.14159265359 +
            (y.sign * 3.14159265359 / 2 -
                y.sign * (x.sign) * (3.14159265359 / 2 - (x / y).abs())));

    // Normalize to 0-360 range
    if (heading < 0) {
      heading += 360;
    }
    heading = heading % 360;

    return heading;
  }

  @override
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _controller.close();
  }
}

/// Provider for CompassService.
final compassServiceProvider = Provider<CompassService>((ref) {
  final service = DefaultCompassService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
