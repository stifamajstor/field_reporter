import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of an audio recording.
@immutable
class AudioRecordingResult {
  const AudioRecordingResult({
    required this.path,
    required this.durationSeconds,
    this.waveformData = const [],
  });

  /// Path to the recorded audio file.
  final String path;

  /// Duration of the audio in seconds.
  final int durationSeconds;

  /// Waveform amplitude data captured during recording.
  final List<double> waveformData;
}

/// Service for audio recording operations.
abstract class AudioRecorderService {
  /// Starts audio recording.
  Future<void> startRecording();

  /// Stops audio recording and returns the result.
  /// Returns null if recording was cancelled or failed.
  Future<AudioRecordingResult?> stopRecording();

  /// Starts playback of a recorded audio file.
  Future<void> startPlayback(String path);

  /// Stops audio playback.
  Future<void> stopPlayback();

  /// Pauses audio playback.
  Future<void> pausePlayback();

  /// Resumes paused audio playback.
  Future<void> resumePlayback();

  /// Sets a listener for playback position updates.
  void setPositionListener(void Function(Duration)? listener);

  /// Sets a listener for playback completion.
  void setCompletionListener(void Function()? listener);

  /// Sets a listener for amplitude updates during recording.
  void setAmplitudeListener(void Function(List<double>)? listener);

  /// Sets a listener for playback waveform updates.
  void setPlaybackWaveformListener(void Function(List<double>)? listener);

  /// Gets the waveform data recorded during the last recording session.
  List<double> get recordedWaveform;

  /// Gets the current playback position.
  Duration get currentPosition;

  /// Disposes resources.
  Future<void> dispose();
}

/// Default implementation of AudioRecorderService.
/// In production, this would use the record package.
class DefaultAudioRecorderService implements AudioRecorderService {
  Duration _currentPosition = Duration.zero;
  List<double> _recordedWaveform = [];
  // ignore: unused_field - will be used by actual audio player implementation
  void Function(Duration)? _positionListener;
  // ignore: unused_field - will be used by actual audio player implementation
  void Function()? _completionListener;
  // ignore: unused_field - will be used by actual audio player implementation
  void Function(List<double>)? _amplitudeListener;
  // ignore: unused_field - will be used by actual audio player implementation
  void Function(List<double>)? _playbackWaveformListener;

  @override
  Future<void> startRecording() async {
    // Implementation will use record package
  }

  @override
  Future<AudioRecordingResult?> stopRecording() async {
    // Implementation will use record package
    return null;
  }

  @override
  Future<void> startPlayback(String path) async {
    // Implementation will use audio player package
    _currentPosition = Duration.zero;
  }

  @override
  Future<void> stopPlayback() async {
    // Implementation will use audio player package
    _currentPosition = Duration.zero;
  }

  @override
  Future<void> pausePlayback() async {
    // Implementation will use audio player package
  }

  @override
  Future<void> resumePlayback() async {
    // Implementation will use audio player package
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
  Duration get currentPosition => _currentPosition;

  @override
  Future<void> dispose() async {
    // Clean up resources
    _positionListener = null;
    _completionListener = null;
    _amplitudeListener = null;
    _playbackWaveformListener = null;
  }
}

/// Provider for the audio recorder service.
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return DefaultAudioRecorderService();
});
