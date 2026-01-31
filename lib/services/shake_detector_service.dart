import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'accelerometer_service.dart';
import 'audio_recorder_service.dart';
import 'permission_service.dart';

/// Service for detecting shake gestures and triggering voice recording.
class ShakeDetectorService {
  ShakeDetectorService({
    required AccelerometerService accelerometerService,
    required PermissionService permissionService,
    required AudioRecorderService audioRecorderService,
  })  : _accelerometerService = accelerometerService,
        _permissionService = permissionService,
        _audioRecorderService = audioRecorderService;

  final AccelerometerService _accelerometerService;
  final PermissionService _permissionService;
  final AudioRecorderService _audioRecorderService;

  StreamSubscription<AccelerometerData>? _subscription;

  bool _isEnabled = false;
  bool _isRecording = false;
  DateTime? _lastShakeTime;

  /// Threshold for shake detection (acceleration magnitude).
  static const double shakeThreshold = 12.0;

  /// Minimum time between shake detections (debounce).
  static const Duration shakeCooldown = Duration(milliseconds: 500);

  /// Whether the service is currently recording.
  bool get isRecording => _isRecording;

  /// Callback when a shake gesture is detected.
  void Function()? onShakeDetected;

  /// Callback for haptic feedback.
  void Function()? onHapticFeedback;

  /// Callback when a recording is completed.
  void Function(AudioRecordingResult result)? onRecordingComplete;

  /// Enable or disable shake detection.
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  void _startListening() {
    _subscription?.cancel();
    _accelerometerService.startListening();
    _subscription = _accelerometerService.accelerometerStream.listen(
      _onAccelerometerData,
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _accelerometerService.stopListening();
  }

  void _onAccelerometerData(AccelerometerData data) {
    if (!_isEnabled) return;

    // Calculate acceleration magnitude
    final magnitude = sqrt(data.x * data.x + data.y * data.y + data.z * data.z);

    // Check if this exceeds shake threshold (excluding gravity ~9.8)
    // A firm shake will produce acceleration well above normal gravity
    if (magnitude > shakeThreshold) {
      _handleShake();
    }
  }

  Future<void> _handleShake() async {
    // Debounce rapid shakes
    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!) < shakeCooldown) {
      return;
    }
    _lastShakeTime = now;

    // Notify shake detected
    onShakeDetected?.call();

    if (_isRecording) {
      // Stop recording
      await _stopRecording();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Check microphone permission
    final status = await _permissionService.checkMicrophonePermission();
    if (!status.isGranted) {
      return;
    }

    // Trigger haptic feedback
    onHapticFeedback?.call();
    _triggerHaptic();

    // Start recording
    await _audioRecorderService.startRecording();
    _isRecording = true;
  }

  Future<void> _stopRecording() async {
    // Trigger haptic feedback
    onHapticFeedback?.call();
    _triggerHaptic();

    // Stop recording and get result
    final result = await _audioRecorderService.stopRecording();
    _isRecording = false;

    if (result != null) {
      onRecordingComplete?.call(result);
    }
  }

  /// Override this in tests to avoid HapticFeedback platform calls.
  void Function()? hapticFeedbackOverride;

  void _triggerHaptic() {
    if (hapticFeedbackOverride != null) {
      hapticFeedbackOverride!();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Dispose of resources.
  void dispose() {
    _stopListening();
  }
}

/// Provider for the shake detector service.
final shakeDetectorServiceProvider = Provider<ShakeDetectorService>((ref) {
  final accelerometerService = ref.watch(accelerometerServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final audioRecorderService = ref.watch(audioRecorderServiceProvider);

  final service = ShakeDetectorService(
    accelerometerService: accelerometerService,
    permissionService: permissionService,
    audioRecorderService: audioRecorderService,
  );

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
