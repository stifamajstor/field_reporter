import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:field_reporter/features/capture/presentation/voice_memo_screen.dart';
import 'package:field_reporter/services/audio_recorder_service.dart';
import 'package:field_reporter/services/permission_service.dart';

/// Mock permission service for voice memo testing.
class MockPermissionService implements PermissionService {
  PermissionStatus _microphoneStatus = PermissionStatus.granted;
  bool microphonePermissionChecked = false;
  bool microphonePermissionRequested = false;

  void setMicrophoneStatus(PermissionStatus status) {
    _microphoneStatus = status;
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async {
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> checkMicrophonePermission() async {
    microphonePermissionChecked = true;
    return _microphoneStatus;
  }

  @override
  Future<PermissionStatus> requestMicrophonePermission() async {
    microphonePermissionRequested = true;
    return _microphoneStatus;
  }

  @override
  Future<bool> openAppSettings() async {
    return true;
  }
}

/// Mock audio recorder service for testing.
class MockAudioRecorderService implements AudioRecorderService {
  bool _isRecording = false;
  bool _isPlaying = false;
  bool startRecordingCalled = false;
  bool stopRecordingCalled = false;
  bool startPlaybackCalled = false;
  bool stopPlaybackCalled = false;
  bool pausePlaybackCalled = false;
  bool resumePlaybackCalled = false;
  String? lastPlaybackPath;
  int _recordedDurationSeconds = 5;
  Duration _playbackPosition = Duration.zero;
  void Function(Duration)? onPositionChanged;
  void Function()? onPlaybackComplete;
  void Function(List<double>)? _amplitudeListener;
  void Function(List<double>)? _playbackWaveformListener;
  List<double> _recordedWaveform = [];

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  void setRecordedDuration(int seconds) {
    _recordedDurationSeconds = seconds;
  }

  /// Simulate playback progress for testing.
  void simulatePlaybackProgress(Duration position) {
    _playbackPosition = position;
    onPositionChanged?.call(position);
  }

  /// Simulate playback completion.
  void simulatePlaybackComplete() {
    _isPlaying = false;
    onPlaybackComplete?.call();
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
    return AudioRecordingResult(
      path: '/path/to/voice_memo.m4a',
      durationSeconds: _recordedDurationSeconds,
      waveformData: _recordedWaveform,
    );
  }

  @override
  Future<void> startPlayback(String path) async {
    startPlaybackCalled = true;
    lastPlaybackPath = path;
    _isPlaying = true;
    _playbackPosition = Duration.zero;
  }

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalled = true;
    _isPlaying = false;
  }

  @override
  Future<void> pausePlayback() async {
    pausePlaybackCalled = true;
    _isPlaying = false;
  }

  @override
  Future<void> resumePlayback() async {
    resumePlaybackCalled = true;
    _isPlaying = true;
  }

  @override
  void setPositionListener(void Function(Duration)? listener) {
    onPositionChanged = listener;
  }

  @override
  void setCompletionListener(void Function()? listener) {
    onPlaybackComplete = listener;
  }

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

  @override
  Duration get currentPosition => _playbackPosition;

  @override
  Future<void> dispose() async {}
}

void main() {
  group('Voice memo recording', () {
    late MockPermissionService mockPermissionService;
    late MockAudioRecorderService mockAudioRecorderService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockAudioRecorderService = MockAudioRecorderService();
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

    testWidgets('navigates to voice memo flow and shows permission prompt',
        (tester) async {
      // Step 1: Navigate to add voice memo flow
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 2: Verify microphone permission prompt if needed
      expect(find.text('Microphone Permission Required'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);
    });

    testWidgets('grants permission and shows audio recording UI',
        (tester) async {
      // Step 1: Navigate to add voice memo flow
      // Step 3: Grant permission (simulate granted)
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 4: Verify audio recording UI appears
      expect(find.byKey(const Key('voice_memo_screen')), findsOneWidget);
      expect(find.byKey(const Key('record_button')), findsOneWidget);
    });

    testWidgets('taps record button and shows recording indicator',
        (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 5: Tap record button
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify recording started
      expect(mockAudioRecorderService.startRecordingCalled, isTrue);

      // Step 6: Verify recording indicator (waveform/pulse)
      expect(find.byKey(const Key('recording_indicator')), findsOneWidget);

      // Step 7: Verify timer counting up
      expect(find.byKey(const Key('recording_timer')), findsOneWidget);
    });

    testWidgets('timer counts up during recording', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Verify initial timer shows 00:00
      expect(find.text('00:00'), findsOneWidget);

      // Step 8: Speak for several seconds (simulate time passing)
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:01'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:02'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:03'), findsOneWidget);
    });

    testWidgets('taps stop button and shows playback controls', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start recording
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Step 9: Tap stop button
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Step 10: Verify recording stops
      expect(mockAudioRecorderService.stopRecordingCalled, isTrue);

      // Step 11: Verify playback controls appear
      expect(find.byKey(const Key('playback_controls')), findsOneWidget);
      expect(find.byKey(const Key('play_button')), findsOneWidget);
      expect(find.byKey(const Key('accept_button')), findsOneWidget);
      expect(find.byKey(const Key('retake_button')), findsOneWidget);
    });

    testWidgets('requests permission when initially denied', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.denied);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify permission was checked
      expect(mockPermissionService.microphonePermissionChecked, isTrue);

      // Tap grant permission button
      await tester.tap(find.text('Grant Permission'));
      await tester.pumpAndSettle();

      // Verify permission was requested
      expect(mockPermissionService.microphonePermissionRequested, isTrue);
    });

    testWidgets('plays back recorded audio when play button tapped',
        (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Record and stop
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Tap play button
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Verify playback started
      expect(mockAudioRecorderService.startPlaybackCalled, isTrue);
      expect(
        mockAudioRecorderService.lastPlaybackPath,
        '/path/to/voice_memo.m4a',
      );
    });

    testWidgets('returns result when accept button tapped', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      String? resultPath;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            audioRecorderServiceProvider
                .overrideWithValue(mockAudioRecorderService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (context) => const VoiceMemoScreen(),
                      ),
                    );
                    resultPath = result;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open voice memo screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Record and stop
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Tap accept
      await tester.tap(find.byKey(const Key('accept_button')));
      await tester.pumpAndSettle();

      // Verify result returned
      expect(resultPath, '/path/to/voice_memo.m4a');
    });

    testWidgets('allows retaking recording with confirmation', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Record and stop
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Tap retake
      await tester.tap(find.byKey(const Key('retake_button')));
      await tester.pumpAndSettle();

      // Confirm discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Verify back to recording UI
      expect(find.byKey(const Key('record_button')), findsOneWidget);
      expect(find.byKey(const Key('playback_controls')), findsNothing);
    });
  });

  group('Voice memo re-record', () {
    late MockPermissionService mockPermissionService;
    late MockAudioRecorderService mockAudioRecorderService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockAudioRecorderService = MockAudioRecorderService();
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

    Future<void> recordAndStopMemo(WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Record
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Stop
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('re-record flow shows confirmation and allows re-recording',
        (tester) async {
      // Step 1: Record a voice memo
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      await recordAndStopMemo(tester);

      // Step 2: Preview the recording (playback controls visible)
      expect(find.byKey(const Key('playback_controls')), findsOneWidget);

      // Step 3: Tap 'Re-record' or 'Discard' button
      await tester.tap(find.byKey(const Key('retake_button')));
      await tester.pumpAndSettle();

      // Step 4: Verify confirmation if recording will be lost
      expect(find.text('Discard Recording?'), findsOneWidget);
      expect(
        find.text(
            'Your current recording will be lost. Do you want to continue?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Step 5: Confirm re-record
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Step 6: Verify recording UI resets
      expect(find.byKey(const Key('record_button')), findsOneWidget);
      expect(find.byKey(const Key('playback_controls')), findsNothing);

      // Step 7: Record new audio
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      expect(mockAudioRecorderService.startRecordingCalled, isTrue);
      expect(find.byKey(const Key('recording_indicator')), findsOneWidget);

      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();

      // Step 8: Verify new recording replaces old
      expect(find.byKey(const Key('playback_controls')), findsOneWidget);
    });

    testWidgets('cancel confirmation keeps existing recording', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      await recordAndStopMemo(tester);

      // Tap retake
      await tester.tap(find.byKey(const Key('retake_button')));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Discard Recording?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify still in playback UI (recording kept)
      expect(find.byKey(const Key('playback_controls')), findsOneWidget);
      expect(find.byKey(const Key('record_button')), findsNothing);
    });

    testWidgets('discard button also shows confirmation', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      await recordAndStopMemo(tester);

      // Both buttons should trigger confirmation
      // Retake button exists
      expect(find.byKey(const Key('retake_button')), findsOneWidget);

      // Tap retake
      await tester.tap(find.byKey(const Key('retake_button')));
      await tester.pumpAndSettle();

      // Verify confirmation appears
      expect(find.text('Discard Recording?'), findsOneWidget);
    });
  });

  group('Voice memo playback', () {
    late MockPermissionService mockPermissionService;
    late MockAudioRecorderService mockAudioRecorderService;

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockAudioRecorderService = MockAudioRecorderService();
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

    Future<void> recordAndStopMemo(WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Record
      await tester.tap(find.byKey(const Key('record_button')));
      await tester.pump();

      // Stop
      await tester.tap(find.byKey(const Key('stop_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('plays audio through speaker when play tapped', (tester) async {
      // Step 1: Record a voice memo
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(10);

      await recordAndStopMemo(tester);

      // Step 2: Tap play button in preview
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Step 3: Verify audio plays through speaker
      expect(mockAudioRecorderService.startPlaybackCalled, isTrue);
      expect(
        mockAudioRecorderService.lastPlaybackPath,
        '/path/to/voice_memo.m4a',
      );
    });

    testWidgets('progress indicator updates during playback', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(10);

      await recordAndStopMemo(tester);

      // Tap play button
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Step 4: Verify progress indicator updates
      expect(find.byKey(const Key('playback_progress')), findsOneWidget);

      // Initial position should be 0
      expect(find.text('00:00 / 00:10'), findsOneWidget);

      // Simulate playback progress
      mockAudioRecorderService.simulatePlaybackProgress(
        const Duration(seconds: 3),
      );
      await tester.pump();

      expect(find.text('00:03 / 00:10'), findsOneWidget);

      // More progress
      mockAudioRecorderService.simulatePlaybackProgress(
        const Duration(seconds: 7),
      );
      await tester.pump();

      expect(find.text('00:07 / 00:10'), findsOneWidget);
    });

    testWidgets('pause button pauses playback', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(10);

      await recordAndStopMemo(tester);

      // Tap play button
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Simulate some progress
      mockAudioRecorderService.simulatePlaybackProgress(
        const Duration(seconds: 3),
      );
      await tester.pump();

      // Step 5: Tap pause button (same button toggles play/pause)
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Step 6: Verify playback pauses
      expect(mockAudioRecorderService.pausePlaybackCalled, isTrue);

      // Verify button shows play icon (not pause)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('play button resumes from pause point', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(10);

      await recordAndStopMemo(tester);

      // Tap play
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Simulate progress to 5 seconds
      mockAudioRecorderService.simulatePlaybackProgress(
        const Duration(seconds: 5),
      );
      await tester.pump();

      // Pause
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Verify paused at 5 seconds (position preserved)
      expect(find.text('00:05 / 00:10'), findsOneWidget);

      // Step 7: Tap play again
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Step 8: Verify playback resumes from pause point
      expect(mockAudioRecorderService.resumePlaybackCalled, isTrue);

      // Button should show pause icon (playing)
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('playback completes and resets to beginning', (tester) async {
      mockPermissionService.setMicrophoneStatus(PermissionStatus.granted);
      mockAudioRecorderService.setRecordedDuration(5);

      await recordAndStopMemo(tester);

      // Tap play
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pump();

      // Simulate complete playback
      mockAudioRecorderService.simulatePlaybackProgress(
        const Duration(seconds: 5),
      );
      await tester.pump();

      mockAudioRecorderService.simulatePlaybackComplete();
      await tester.pump();

      // Verify button shows play icon (ready to play again)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Position should reset to beginning
      expect(find.text('00:00 / 00:05'), findsOneWidget);
    });
  });
}
