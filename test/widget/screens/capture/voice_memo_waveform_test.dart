import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/voice_memo_screen.dart';
import 'package:field_reporter/features/capture/presentation/widgets/audio_waveform_widget.dart';
import 'package:field_reporter/services/audio_recorder_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for waveform testing.
class MockPermissionService implements PermissionService {
  @override
  Future<PermissionStatus> checkCameraPermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestCameraPermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> checkMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestMicrophonePermission() async =>
      PermissionStatus.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

/// Mock audio recorder service with waveform amplitude support.
class MockAudioRecorderServiceWithWaveform implements AudioRecorderService {
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  void Function(Duration)? _positionListener;
  void Function()? _completionListener;
  void Function(List<double>)? _amplitudeListener;
  void Function(List<double>)? _playbackWaveformListener;

  List<double> _recordedWaveform = [];
  int _recordedDurationSeconds = 5;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  void setRecordedDuration(int seconds) {
    _recordedDurationSeconds = seconds;
  }

  /// Simulate amplitude change during recording.
  void simulateAmplitude(List<double> amplitudes) {
    _amplitudeListener?.call(amplitudes);
  }

  /// Set the recorded waveform data for playback.
  void setRecordedWaveform(List<double> waveform) {
    _recordedWaveform = waveform;
  }

  /// Simulate playback progress.
  void simulatePlaybackProgress(Duration position) {
    _currentPosition = position;
    _positionListener?.call(position);
  }

  /// Simulate playback with waveform data.
  void simulatePlaybackWaveform(List<double> waveform) {
    _playbackWaveformListener?.call(waveform);
  }

  /// Simulate playback completion.
  void simulatePlaybackComplete() {
    _isPlaying = false;
    _completionListener?.call();
  }

  @override
  Future<void> startRecording() async {
    _isRecording = true;
  }

  @override
  Future<AudioRecordingResult?> stopRecording() async {
    _isRecording = false;
    return AudioRecordingResult(
      path: '/path/to/voice_memo.m4a',
      durationSeconds: _recordedDurationSeconds,
      waveformData: _recordedWaveform,
    );
  }

  @override
  Future<void> startPlayback(String path) async {
    _isPlaying = true;
    _currentPosition = Duration.zero;
  }

  @override
  Future<void> stopPlayback() async {
    _isPlaying = false;
  }

  @override
  Future<void> pausePlayback() async {
    _isPlaying = false;
  }

  @override
  Future<void> resumePlayback() async {
    _isPlaying = true;
  }

  @override
  void setPositionListener(void Function(Duration)? listener) {
    _positionListener = listener;
  }

  @override
  void setCompletionListener(void Function()? listener) {
    _completionListener = listener;
  }

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Future<void> dispose() async {}

  @override
  void setAmplitudeListener(void Function(List<double>)? listener) {
    _amplitudeListener = listener;
  }

  @override
  void setPlaybackWaveformListener(void Function(List<double>)? listener) {
    _playbackWaveformListener = listener;
  }

  @override
  List<double> get recordedWaveform => _recordedWaveform;
}

void main() {
  group('Voice memo audio waveform visualization', () {
    late MockPermissionService mockPermissionService;
    late MockAudioRecorderServiceWithWaveform mockAudioRecorderService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockAudioRecorderService = MockAudioRecorderServiceWithWaveform();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          audioRecorderServiceProvider
              .overrideWithValue(mockAudioRecorderService),
        ],
        child: const MaterialApp(
          home: VoiceMemoScreen(),
        ),
      );
    }

    testWidgets('waveform responds to voice during recording', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Start voice recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify waveform widget is visible during recording
      expect(find.byKey(const Key('recording_waveform')), findsOneWidget);

      // Step 2: Speak into microphone (simulate amplitude)
      // Step 3: Verify waveform responds to voice
      mockAudioRecorderService.simulateAmplitude([0.3, 0.5, 0.7, 0.4, 0.6]);
      await tester.pump();

      // Waveform should show active bars
      final waveformWidget = tester.widget<AudioWaveformWidget>(
        find.byKey(const Key('recording_waveform')),
      );
      expect(waveformWidget.amplitudes.isNotEmpty, isTrue);
      expect(waveformWidget.amplitudes.any((a) => a > 0.2), isTrue);
    });

    testWidgets('waveform peaks with loud sounds', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Step 4: Verify waveform peaks with loud sounds
      // Simulate loud sound (high amplitude values)
      mockAudioRecorderService.simulateAmplitude([0.8, 0.9, 1.0, 0.95, 0.85]);
      await tester.pump();

      final waveformWidget = tester.widget<AudioWaveformWidget>(
        find.byKey(const Key('recording_waveform')),
      );
      // At least one amplitude should be high (peak)
      expect(waveformWidget.amplitudes.any((a) => a >= 0.8), isTrue);
    });

    testWidgets('waveform flattens when silent', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // First show some activity
      mockAudioRecorderService.simulateAmplitude([0.5, 0.6, 0.7, 0.5, 0.4]);
      await tester.pump();

      // Step 5: Stop speaking
      // Step 6: Verify waveform flattens
      // Simulate silence (low amplitude values)
      mockAudioRecorderService
          .simulateAmplitude([0.05, 0.02, 0.03, 0.01, 0.02]);
      await tester.pump();

      final waveformWidget = tester.widget<AudioWaveformWidget>(
        find.byKey(const Key('recording_waveform')),
      );
      // All amplitudes should be low (flattened)
      expect(waveformWidget.amplitudes.every((a) => a < 0.1), isTrue);
    });

    testWidgets('waveform displays during playback', (tester) async {
      // Pre-set recorded waveform data
      final recordedWaveform = List.generate(50, (i) => (i % 10) / 10.0);
      mockAudioRecorderService.setRecordedWaveform(recordedWaveform);
      mockAudioRecorderService.setRecordedDuration(5);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Record and stop
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Step 7: Play back recording
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Step 8: Verify waveform displays during playback
      expect(find.byKey(const Key('playback_waveform')), findsOneWidget);

      final waveformWidget = tester.widget<AudioWaveformWidget>(
        find.byKey(const Key('playback_waveform')),
      );
      expect(waveformWidget.amplitudes.isNotEmpty, isTrue);
    });

    testWidgets('playback waveform shows progress indicator', (tester) async {
      final recordedWaveform = List.generate(50, (i) => (i % 10) / 10.0);
      mockAudioRecorderService.setRecordedWaveform(recordedWaveform);
      mockAudioRecorderService.setRecordedDuration(10);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Record and stop
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Play back
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Simulate progress at 50%
      mockAudioRecorderService.simulatePlaybackProgress(
        const Duration(seconds: 5),
      );
      await tester.pump();

      // Waveform should show progress (half highlighted)
      final waveformWidget = tester.widget<AudioWaveformWidget>(
        find.byKey(const Key('playback_waveform')),
      );
      expect(waveformWidget.progress, closeTo(0.5, 0.1));
    });

    testWidgets('recording waveform has animation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify waveform widget is in recording mode (animated)
      final waveformWidget = tester.widget<AudioWaveformWidget>(
        find.byKey(const Key('recording_waveform')),
      );
      expect(waveformWidget.isRecording, isTrue);
    });
  });
}
