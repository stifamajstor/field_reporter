import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Represents accelerometer sensor data.
class AccelerometerData {
  final double x;
  final double y;
  final double z;

  const AccelerometerData({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  String toString() => 'AccelerometerData(x: $x, y: $y, z: $z)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccelerometerData &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}

/// Service for handling accelerometer sensor data.
abstract class AccelerometerService {
  /// Stream of accelerometer data updates.
  Stream<AccelerometerData> get accelerometerStream;

  /// Current accelerometer data.
  AccelerometerData get currentData;

  /// Start listening to accelerometer events.
  void startListening();

  /// Stop listening to accelerometer events.
  void stopListening();
}

/// Default implementation of AccelerometerService using sensors_plus.
class DefaultAccelerometerService implements AccelerometerService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _controller = StreamController<AccelerometerData>.broadcast();
  AccelerometerData _currentData = const AccelerometerData(x: 0, y: 0, z: 9.8);

  @override
  Stream<AccelerometerData> get accelerometerStream => _controller.stream;

  @override
  AccelerometerData get currentData => _currentData;

  @override
  void startListening() {
    _subscription?.cancel();
    _subscription = accelerometerEventStream().listen((event) {
      _currentData = AccelerometerData(
        x: event.x,
        y: event.y,
        z: event.z,
      );
      _controller.add(_currentData);
    });
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

/// Provider for AccelerometerService.
final accelerometerServiceProvider = Provider<AccelerometerService>((ref) {
  final service = DefaultAccelerometerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
