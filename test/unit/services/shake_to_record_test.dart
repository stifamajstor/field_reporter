import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/services/accelerometer_service.dart';
import 'package:field_reporter/services/audio_recorder_service.dart';
import 'package:field_reporter/services/permission_service.dart';
import 'package:field_reporter/services/shake_detector_service.dart';

/// Mock accelerometer service for shake detection testing.
class MockAccelerometerService implements AccelerometerService {
  final _controller = StreamController<AccelerometerData>.broadcast();
  AccelerometerData _currentData = const AccelerometerData(x: 0, y: 0, z: 9.8);

  @override
  Stream<AccelerometerData> get accelerometerStream => _controller.stream;

  @override
  AccelerometerData get currentData => _currentData;

  @override
  void startListening() {}

  @override
  void stopListening() {}

  /// Simulate accelerometer data for testing.
  void simulateData(AccelerometerData data) {
    _currentData = data;
    _controller.add(data);
  }

  /// Simulate a firm shake gesture.
  void simulateShake() {
    // Simulate rapid acceleration changes that would constitute a shake
    simulateData(const AccelerometerData(x: 15, y: 0, z: 9.8));
    simulateData(const AccelerometerData(x: -15, y: 0, z: 9.8));
    simulateData(const AccelerometerData(x: 15, y: 0, z: 9.8));
  }

  void dispose() {
    _controller.close();
  }
}

/// Mock permission service for testing.
class MockPermissionService implements PermissionService {
  PermissionStatus _microphoneStatus = PermissionStatus.granted;

  void setMicrophoneStatus(PermissionStatus status) {
    _microphoneStatus = status;
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestCameraPermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> checkMicrophonePermission() async =>
      _microphoneStatus;

  @override
  Future<PermissionStatus> requestMicrophonePermission() async =>
      _microphoneStatus;

  @override
  Future<bool> openAppSettings() async => true;
}

/// Mock audio recorder service for testing.
class MockAudioRecorderService implements AudioRecorderService {
  bool _isRecording = false;
  bool startRecordingCalled = false;
  bool stopRecordingCalled = false;
  int _recordedDurationSeconds = 5;
  String? recordedFilePath;
  List<double> _recordedWaveform = [];

  bool get isRecording => _isRecording;

  void setRecordedDuration(int seconds) {
    _recordedDurationSeconds = seconds;
  }

  @override
  Future<void> startRecording() async {
    startRecordingCalled = true;
    _isRecording = true;
  }

  @override
  Future<AudioRecordingResult?> stopRecording() async {
    stopRecordingCalled = true;
    _isRecording = false;
    recordedFilePath = '/path/to/shake_recording.m4a';
    return AudioRecordingResult(
      path: recordedFilePath!,
      durationSeconds: _recordedDurationSeconds,
    );
  }

  @override
  Future<void> startPlayback(String path) async {}

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> pausePlayback() async {}

  @override
  Future<void> resumePlayback() async {}

  @override
  void setPositionListener(void Function(Duration)? listener) {}

  @override
  void setCompletionListener(void Function()? listener) {}

  @override
  void setAmplitudeListener(void Function(List<double>)? listener) {}

  @override
  void setPlaybackWaveformListener(void Function(List<double>)? listener) {}

  @override
  List<double> get recordedWaveform => _recordedWaveform;

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Future<void> dispose() async {}
}

void main() {
  group('Shake-to-record service', () {
    late MockAccelerometerService mockAccelerometerService;
    late MockPermissionService mockPermissionService;
    late MockAudioRecorderService mockAudioRecorderService;
    late ShakeDetectorService shakeDetectorService;

    setUp(() {
      mockAccelerometerService = MockAccelerometerService();
      mockPermissionService = MockPermissionService();
      mockAudioRecorderService = MockAudioRecorderService();
      shakeDetectorService = ShakeDetectorService(
        accelerometerService: mockAccelerometerService,
        permissionService: mockPermissionService,
        audioRecorderService: mockAudioRecorderService,
      );
      // Override haptic feedback to avoid platform channel issues in tests
      shakeDetectorService.hapticFeedbackOverride = () {};
    });

    tearDown(() {
      shakeDetectorService.dispose();
      mockAccelerometerService.dispose();
    });

    test('detects shake gesture from accelerometer data', () async {
      // Step 1: Report is in editing mode (service is enabled)
      shakeDetectorService.setEnabled(true);

      bool shakeDetected = false;
      shakeDetectorService.onShakeDetected = () {
        shakeDetected = true;
      };

      // Step 2: Shake device firmly
      // Simulate high acceleration values indicating a shake
      mockAccelerometerService.simulateShake();

      // Allow time for shake detection
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify shake was detected
      expect(shakeDetected, isTrue);
    });

    test('shake starts voice recording automatically', () async {
      // Step 1: Report is in editing mode
      shakeDetectorService.setEnabled(true);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      // Step 2: Shake device firmly
      mockAccelerometerService.simulateShake();

      await Future.delayed(const Duration(milliseconds: 100));

      // Step 3: Verify voice recording starts automatically
      expect(mockAudioRecorderService.startRecordingCalled, isTrue);
      expect(shakeDetectorService.isRecording, isTrue);
    });

    test('provides haptic confirmation when recording starts', () async {
      shakeDetectorService.setEnabled(true);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      bool hapticTriggered = false;
      shakeDetectorService.onHapticFeedback = () {
        hapticTriggered = true;
      };

      // Step 2: Shake device firmly
      mockAccelerometerService.simulateShake();

      await Future.delayed(const Duration(milliseconds: 100));

      // Step 4: Verify haptic confirmation
      expect(hapticTriggered, isTrue);
    });

    test('second shake stops recording', () async {
      shakeDetectorService.setEnabled(true);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      // First shake - start recording
      mockAccelerometerService.simulateShake();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(shakeDetectorService.isRecording, isTrue);

      // Wait for cooldown period to pass
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 5: Shake again to stop
      mockAccelerometerService.simulateShake();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 6: Verify recording stops
      expect(mockAudioRecorderService.stopRecordingCalled, isTrue);
      expect(shakeDetectorService.isRecording, isFalse);
    });

    test('completed recording is returned via callback', () async {
      shakeDetectorService.setEnabled(true);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(10);

      AudioRecordingResult? completedRecording;
      shakeDetectorService.onRecordingComplete = (result) {
        completedRecording = result;
      };

      // First shake - start recording
      mockAccelerometerService.simulateShake();
      await Future.delayed(const Duration(milliseconds: 100));

      // Wait for cooldown period to pass
      await Future.delayed(const Duration(milliseconds: 600));

      // Second shake - stop recording
      mockAccelerometerService.simulateShake();
      await Future.delayed(const Duration(milliseconds: 100));

      // Step 7: Verify recording is available to be added to report
      expect(completedRecording, isNotNull);
      expect(completedRecording!.path, '/path/to/shake_recording.m4a');
      expect(completedRecording!.durationSeconds, 10);
    });

    test('does not trigger when disabled', () async {
      // Service is disabled (not in editing mode)
      shakeDetectorService.setEnabled(false);

      bool shakeDetected = false;
      shakeDetectorService.onShakeDetected = () {
        shakeDetected = true;
      };

      mockAccelerometerService.simulateShake();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(shakeDetected, isFalse);
      expect(mockAudioRecorderService.startRecordingCalled, isFalse);
    });

    test('does not start recording without microphone permission', () async {
      shakeDetectorService.setEnabled(true);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      mockAccelerometerService.simulateShake();
      await Future.delayed(const Duration(milliseconds: 100));

      // Recording should not start without permission
      expect(mockAudioRecorderService.startRecordingCalled, isFalse);
    });

    test('shake threshold requires firm shake', () async {
      shakeDetectorService.setEnabled(true);

      bool shakeDetected = false;
      shakeDetectorService.onShakeDetected = () {
        shakeDetected = true;
      };

      // Light movement should not trigger shake
      mockAccelerometerService
          .simulateData(const AccelerometerData(x: 2, y: 1, z: 9.8));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(shakeDetected, isFalse);

      // Only firm shake should trigger
      mockAccelerometerService.simulateShake();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(shakeDetected, isTrue);
    });

    test('debounces rapid shakes', () async {
      shakeDetectorService.setEnabled(true);
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      int shakeCount = 0;
      shakeDetectorService.onShakeDetected = () {
        shakeCount++;
      };

      // Rapid successive shakes should be debounced
      mockAccelerometerService.simulateShake();
      mockAccelerometerService.simulateShake();
      mockAccelerometerService.simulateShake();

      await Future.delayed(const Duration(milliseconds: 100));

      // Should only register as one shake action
      expect(shakeCount, 1);
    });
  });
}
