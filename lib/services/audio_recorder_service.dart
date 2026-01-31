import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of an audio recording.
@immutable
class AudioRecordingResult {
  const AudioRecordingResult({
    required this.path,
    required this.durationSeconds,
  });

  /// Path to the recorded audio file.
  final String path;

  /// Duration of the audio in seconds.
  final int durationSeconds;
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

  /// Gets the current playback position.
  Duration get currentPosition;

  /// Disposes resources.
  Future<void> dispose();
}

/// Default implementation of AudioRecorderService.
/// In production, this would use the record package.
class DefaultAudioRecorderService implements AudioRecorderService {
  Duration _currentPosition = Duration.zero;
  // ignore: unused_field - will be used by actual audio player implementation
  void Function(Duration)? _positionListener;
  // ignore: unused_field - will be used by actual audio player implementation
  void Function()? _completionListener;

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
  Duration get currentPosition => _currentPosition;

  @override
  Future<void> dispose() async {
    // Clean up resources
    _positionListener = null;
    _completionListener = null;
  }
}

/// Provider for the audio recorder service.
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return DefaultAudioRecorderService();
});
