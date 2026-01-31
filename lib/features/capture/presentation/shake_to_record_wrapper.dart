import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/accelerometer_service.dart';
import '../../../services/audio_recorder_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/shake_detector_service.dart';
import '../../reports/domain/report.dart';

/// A wrapper widget that enables shake-to-record functionality.
///
/// Wraps a child widget (typically a report editor screen) and listens for
/// shake gestures to automatically start/stop voice recording.
class ShakeToRecordWrapper extends ConsumerStatefulWidget {
  const ShakeToRecordWrapper({
    super.key,
    required this.child,
    required this.report,
    required this.isEditing,
    required this.onRecordingComplete,
  });

  /// The child widget to wrap.
  final Widget child;

  /// The report being edited.
  final Report report;

  /// Whether the report is in editing mode.
  final bool isEditing;

  /// Callback when a recording is completed.
  final void Function(AudioRecordingResult result) onRecordingComplete;

  @override
  ConsumerState<ShakeToRecordWrapper> createState() =>
      _ShakeToRecordWrapperState();
}

class _ShakeToRecordWrapperState extends ConsumerState<ShakeToRecordWrapper> {
  ShakeDetectorService? _shakeDetectorService;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initShakeDetector();
    });
  }

  @override
  void didUpdateWidget(covariant ShakeToRecordWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEditing != widget.isEditing) {
      _shakeDetectorService?.setEnabled(widget.isEditing);
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _shakeDetectorService?.setEnabled(false);
    super.dispose();
  }

  void _initShakeDetector() {
    // Create shake detector service with injected dependencies
    final accelerometerService = ref.read(accelerometerServiceProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final audioRecorderService = ref.read(audioRecorderServiceProvider);

    _shakeDetectorService = ShakeDetectorService(
      accelerometerService: accelerometerService,
      permissionService: permissionService,
      audioRecorderService: audioRecorderService,
    );

    // Override haptic feedback to use our callback (avoids platform channel in tests)
    _shakeDetectorService!.hapticFeedbackOverride = _onHapticFeedback;

    _shakeDetectorService!.onShakeDetected = _onShakeDetected;
    _shakeDetectorService!.onHapticFeedback = _onHapticFeedback;
    _shakeDetectorService!.onRecordingComplete = _onRecordingComplete;

    _shakeDetectorService!.setEnabled(widget.isEditing);
  }

  void _onShakeDetected() {
    // Toggle recording state
    if (!_isRecording) {
      // Check if we actually started recording (after permission check in service)
      // We need to wait a bit for the async recording to start
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && (_shakeDetectorService?.isRecording ?? false)) {
          _startRecordingUI();
        }
      });
    }
    // Note: stop is handled via onRecordingComplete callback
  }

  void _onHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  void _onRecordingComplete(AudioRecordingResult result) {
    _stopRecordingUI();
    widget.onRecordingComplete(result);
  }

  void _startRecordingUI() {
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

  void _stopRecordingUI() {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isRecording) _buildRecordingOverlay(),
      ],
    );
  }

  Widget _buildRecordingOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          key: const Key('shake_recording_indicator'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.rose500,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording dot
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rose500,
                ),
              ),
              const SizedBox(width: 12),
              // Timer
              Text(
                _formatTime(_recordingSeconds),
                style: AppTypography.body1.copyWith(
                  color: Colors.white,
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              // Shake to stop hint
              Text(
                'Shake to stop',
                style: AppTypography.caption.copyWith(
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
