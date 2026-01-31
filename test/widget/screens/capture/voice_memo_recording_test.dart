import 'dart:async';

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
  bool startRecordingCalled = false;
  bool stopRecordingCalled = false;
  bool startPlaybackCalled = false;
  bool stopPlaybackCalled = false;
  String? lastPlaybackPath;
  int _recordedDurationSeconds = 5;

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
    return AudioRecordingResult(
      path: '/path/to/voice_memo.m4a',
      durationSeconds: _recordedDurationSeconds,
    );
  }

  @override
  Future<void> startPlayback(String path) async {
    startPlaybackCalled = true;
    lastPlaybackPath = path;
  }

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalled = true;
  }

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

    testWidgets('allows retaking recording', (tester) async {
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

      // Verify back to recording UI
      expect(find.byKey(const Key('record_button')), findsOneWidget);
      expect(find.byKey(const Key('playback_controls')), findsNothing);
    });
  });
}
