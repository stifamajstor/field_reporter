import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/audio_recorder_service.dart';
import '../../../services/permission_service.dart';

/// Result type for voice memo screen.
enum VoiceMemoResult {
  accept,
  cancel,
}

/// Screen for recording voice memos.
class VoiceMemoScreen extends ConsumerStatefulWidget {
  const VoiceMemoScreen({super.key});

  @override
  ConsumerState<VoiceMemoScreen> createState() => _VoiceMemoScreenState();
}

class _VoiceMemoScreenState extends ConsumerState<VoiceMemoScreen> {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isRecording = false;
  bool _hasRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _recordedPath;
  int _recordedDuration = 0;
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndInitialize();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.checkMicrophonePermission();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.requestMicrophonePermission();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isPermanentlyDenied) {
      await permissionService.openAppSettings();
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.lightImpact();

    final audioService = ref.read(audioRecorderServiceProvider);
    await audioService.startRecording();

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    HapticFeedback.lightImpact();

    _recordingTimer?.cancel();
    _recordingTimer = null;

    final audioService = ref.read(audioRecorderServiceProvider);
    final result = await audioService.stopRecording();

    if (result != null) {
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _recordedPath = result.path;
        _recordedDuration = result.durationSeconds;
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recordedPath == null) return;

    HapticFeedback.lightImpact();

    final audioService = ref.read(audioRecorderServiceProvider);

    // Set up listeners before starting playback
    audioService.setPositionListener((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });

    audioService.setCompletionListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isPaused = false;
          _playbackPosition = Duration.zero;
        });
      }
    });

    await audioService.startPlayback(_recordedPath!);

    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _playbackPosition = Duration.zero;
    });
  }

  Future<void> _pausePlayback() async {
    HapticFeedback.lightImpact();

    final audioService = ref.read(audioRecorderServiceProvider);
    await audioService.pausePlayback();

    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  Future<void> _resumePlayback() async {
    HapticFeedback.lightImpact();

    final audioService = ref.read(audioRecorderServiceProvider);
    await audioService.resumePlayback();

    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else if (_isPaused) {
      _resumePlayback();
    } else {
      _playRecording();
    }
  }

  void _acceptRecording() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(_recordedPath);
  }

  Future<void> _retakeRecording() async {
    HapticFeedback.lightImpact();

    // Show confirmation dialog before discarding
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceHigh,
        title: Text(
          'Discard Recording?',
          style: AppTypography.headline3.copyWith(color: Colors.white),
        ),
        content: Text(
          'Your current recording will be lost. Do you want to continue?',
          style:
              AppTypography.body1.copyWith(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(color: AppColors.slate400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: AppTypography.button.copyWith(color: AppColors.rose500),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _hasRecording = false;
        _recordedPath = null;
        _recordedDuration = 0;
        _isPlaying = false;
        _isPaused = false;
        _playbackPosition = Duration.zero;
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    return Scaffold(
      key: const Key('voice_memo_screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          'Voice Memo',
          style: AppTypography.headline3.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _hasRecording ? _buildPlaybackUI() : _buildRecordingUI(),
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic_outlined,
                size: 64,
                color: AppColors.slate400,
              ),
              const SizedBox(height: 24),
              Text(
                'Microphone Permission Required',
                style: AppTypography.headline2.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To record voice memos, please allow microphone access.',
                style: AppTypography.body1.copyWith(
                  color: AppColors.slate400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Grant Permission',
                    style: AppTypography.button,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.button.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Recording indicator and timer
        if (_isRecording) ...[
          Container(
            key: const Key('recording_indicator'),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.rose500.withOpacity(0.2),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rose500.withOpacity(0.4),
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.rose500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            key: const Key('recording_timer'),
            _formatTime(_recordingSeconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w300,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ] else ...[
          const Icon(
            Icons.mic,
            size: 80,
            color: AppColors.slate400,
          ),
          const SizedBox(height: 24),
          Text(
            'Tap to record',
            style: AppTypography.body1.copyWith(
              color: AppColors.slate400,
            ),
          ),
        ],
        const Spacer(),
        // Record/Stop button
        Padding(
          padding: const EdgeInsets.all(48),
          child: GestureDetector(
            key: _isRecording
                ? const Key('stop_button')
                : const Key('record_button'),
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius:
                        _isRecording ? BorderRadius.circular(8) : null,
                    color: AppColors.rose500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackUI() {
    final totalDuration = Duration(seconds: _recordedDuration);
    final progress = _recordedDuration > 0
        ? _playbackPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Column(
      key: const Key('playback_controls'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Waveform placeholder
        Container(
          width: 200,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.slate700.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.graphic_eq,
              size: 48,
              color: AppColors.orange500,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            key: const Key('playback_progress'),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.slate700,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.orange500),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatTime(_playbackPosition.inSeconds)} / ${_formatTime(_recordedDuration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Play/Pause button
        GestureDetector(
          key: const Key('play_button'),
          onTap: _togglePlayback,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orange500,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const Spacer(),
        // Accept/Retake buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const Key('retake_button'),
                  onTap: _retakeRecording,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.slate400,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Retake',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  key: const Key('accept_button'),
                  onTap: _acceptRecording,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.orange500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Use Recording',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
