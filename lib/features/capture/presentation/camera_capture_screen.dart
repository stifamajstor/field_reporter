import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/camera_service.dart';
import '../../../services/location_service.dart';
import '../../../services/permission_service.dart';
import '../providers/camera_focus_provider.dart';
import '../providers/camera_zoom_provider.dart';
import '../providers/compass_provider.dart';
import '../providers/gps_overlay_provider.dart';
import '../providers/level_indicator_provider.dart';
import '../providers/timestamp_overlay_provider.dart';
import 'photo_preview_screen.dart';
import 'video_preview_screen.dart';

/// Camera mode enum.
enum CameraMode {
  photo,
  video,
}

/// Maximum video recording duration in seconds (5 minutes).
const int kMaxRecordingDurationSeconds = 300;

/// Warning threshold in seconds before max duration (30 seconds).
const int kWarningThresholdSeconds = 30;

/// Screen for capturing photos/videos with the camera.
class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isPermissionPermanentlyDenied = false;
  String? _errorMessage;
  bool _showShutterAnimation = false;
  bool _showSwitchAnimation = false;
  FlashMode _flashMode = FlashMode.auto;
  late AnimationController _switchAnimationController;
  late Animation<double> _switchAnimation;

  // Video recording state
  CameraMode _cameraMode = CameraMode.photo;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  bool _hasMicrophonePermission = false;
  bool _showNoAudioWarning = false;
  bool _userDismissedAudioWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _switchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _switchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _switchAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraService = ref.read(cameraServiceProvider);
      _checkPermissionAndInitialize();
      ref.read(gpsOverlayProvider.notifier).initialize();
      ref.read(timestampOverlayProvider.notifier).initialize();
      ref.read(levelIndicatorProvider.notifier).initialize();
      ref.read(compassProvider.notifier).initialize();
      ref.read(cameraZoomProvider.notifier).initialize();
    });
  }

  CameraService? _cameraService;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _switchAnimationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _cameraService?.closeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      ref.read(cameraServiceProvider).closeCamera();
    } else if (state == AppLifecycleState.resumed && _hasPermission) {
      _initializeCamera();
    }
  }

  Future<void> _checkPermissionAndInitialize() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.checkCameraPermission();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
        _isPermissionPermanentlyDenied = false;
      });
      await _initializeCamera();
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
        _isPermissionPermanentlyDenied = status.isPermanentlyDenied;
      });
    }
  }

  Future<void> _requestPermission() async {
    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.requestCameraPermission();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isPermissionPermanentlyDenied = false;
      });
      await _initializeCamera();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isPermissionPermanentlyDenied = true;
      });
    }
  }

  Future<void> _openAppSettings() async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.openAppSettings();
  }

  Future<void> _initializeCamera() async {
    try {
      // Notify camera service that camera is open
      // The service handles actual camera initialization in production
      final cameraService = ref.read(cameraServiceProvider);
      await cameraService.openCamera();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera';
      });
    }
  }

  Future<void> _switchCamera() async {
    setState(() {
      _showSwitchAnimation = true;
    });

    _switchAnimationController.forward(from: 0.0);

    final cameraService = ref.read(cameraServiceProvider);
    await cameraService.switchCamera();

    // Reset zoom when switching cameras
    ref.read(cameraZoomProvider.notifier).reset();

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _showSwitchAnimation = false;
      });
    }
  }

  Future<void> _toggleFlashMode() async {
    final cameraService = ref.read(cameraServiceProvider);
    final nextMode = switch (_flashMode) {
      FlashMode.auto => FlashMode.on,
      FlashMode.on => FlashMode.off,
      FlashMode.off => FlashMode.auto,
    };

    await cameraService.setFlashMode(nextMode);

    if (mounted) {
      setState(() {
        _flashMode = nextMode;
      });
    }
  }

  IconData _getFlashIcon() {
    return switch (_flashMode) {
      FlashMode.auto => Icons.flash_auto,
      FlashMode.on => Icons.flash_on,
      FlashMode.off => Icons.flash_off,
    };
  }

  String _getFlashLabel() {
    return switch (_flashMode) {
      FlashMode.auto => 'Flash: Auto',
      FlashMode.on => 'Flash: On',
      FlashMode.off => 'Flash: Off',
    };
  }

  Future<void> _capturePhoto() async {
    try {
      // Trigger haptic feedback
      HapticFeedback.lightImpact();

      // Capture timestamp at moment of capture
      final capturedTimestamp = DateTime.now();

      // Capture compass heading at moment of capture
      final compassState = ref.read(compassProvider);
      final compassHeading = compassState.heading;

      // Capture GPS location at moment of capture
      final gpsState = ref.read(gpsOverlayProvider);
      final capturedLocation = gpsState.currentPosition;
      final isLocationStale = gpsState.isLocationStale;

      // Show shutter animation
      setState(() {
        _showShutterAnimation = true;
      });

      final cameraService = ref.read(cameraServiceProvider);
      final photoPath = await cameraService.capturePhoto(
        compassHeading: compassHeading,
        location: capturedLocation,
        isLocationStale: isLocationStale,
      );

      // Hide shutter animation after brief delay
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _showShutterAnimation = false;
        });
      }

      if (mounted && photoPath != null) {
        // Navigate to photo preview screen
        final result = await Navigator.of(context).push<PhotoPreviewResult>(
          MaterialPageRoute(
            builder: (context) => PhotoPreviewScreen(
              arguments: PhotoPreviewArguments(
                photoPath: photoPath,
                capturedTimestamp: capturedTimestamp,
                compassHeading: compassHeading,
              ),
            ),
          ),
        );

        if (!mounted) return;

        if (result == PhotoPreviewResult.accept) {
          // Return the photo path to the caller
          Navigator.of(context).pop(photoPath);
        }
        // If retake, stay on camera screen (do nothing)
      }
    } catch (e) {
      setState(() {
        _showShutterAnimation = false;
      });
    }
  }

  Future<void> _switchToVideoMode() async {
    // Check and request microphone permission for audio recording
    final permissionService = ref.read(permissionServiceProvider);
    var micStatus = await permissionService.checkMicrophonePermission();

    if (!micStatus.isGranted) {
      micStatus = await permissionService.requestMicrophonePermission();
    }

    final hasMic = micStatus.isGranted;

    setState(() {
      _hasMicrophonePermission = hasMic;
      _cameraMode = CameraMode.video;
      // Show warning if microphone denied and user hasn't dismissed it yet
      _showNoAudioWarning = !hasMic && !_userDismissedAudioWarning;
    });
  }

  void _dismissNoAudioWarning() {
    setState(() {
      _showNoAudioWarning = false;
      _userDismissedAudioWarning = true;
    });
  }

  Future<void> _openMicrophoneSettings() async {
    final permissionService = ref.read(permissionServiceProvider);
    await permissionService.openAppSettings();
  }

  void _switchToPhotoMode() {
    setState(() {
      _cameraMode = CameraMode.photo;
    });
  }

  Future<void> _startRecording() async {
    HapticFeedback.lightImpact();

    final cameraService = ref.read(cameraServiceProvider);
    await cameraService.startRecording(enableAudio: _hasMicrophonePermission);

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    // Start the recording timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });

        // Auto-stop at max duration
        if (_recordingSeconds >= kMaxRecordingDurationSeconds) {
          _stopRecording();
        }
      }
    });
  }

  /// Returns true if recording is near max duration and should show warning.
  bool get _shouldShowDurationWarning {
    if (!_isRecording) return false;
    final timeRemaining = kMaxRecordingDurationSeconds - _recordingSeconds;
    return timeRemaining <= kWarningThresholdSeconds && timeRemaining > 0;
  }

  /// Returns the time remaining in seconds.
  int get _timeRemainingSeconds {
    return kMaxRecordingDurationSeconds - _recordingSeconds;
  }

  Future<void> _stopRecording() async {
    HapticFeedback.lightImpact();

    _recordingTimer?.cancel();
    _recordingTimer = null;

    final cameraService = ref.read(cameraServiceProvider);
    final result = await cameraService.stopRecording();

    setState(() {
      _isRecording = false;
    });

    if (mounted && result != null) {
      // Navigate to video preview screen
      final previewResult =
          await Navigator.of(context).push<VideoPreviewResult>(
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(
            arguments: VideoPreviewArguments(
              videoPath: result.path,
              durationSeconds: result.durationSeconds,
              hasAudio: result.hasAudio,
            ),
          ),
        ),
      );

      if (!mounted) return;

      if (previewResult == VideoPreviewResult.accept) {
        Navigator.of(context).pop(result.path);
      }
      // If retake, stay on camera screen
    }
  }

  String _formatRecordingTime(int seconds) {
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

    if (_errorMessage != null) {
      return _buildError();
    }

    return _buildCameraPreview();
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
                Icons.camera_alt_outlined,
                size: 64,
                color: AppColors.slate400,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Permission Required',
                style: AppTypography.headline2.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To capture photos and videos, please allow camera access.',
                style: AppTypography.body1.copyWith(
                  color: AppColors.slate400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_isPermissionPermanentlyDenied)
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
              if (_isPermissionPermanentlyDenied)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('open_settings_button'),
                    onPressed: _openAppSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Open Settings',
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

  Widget _buildError() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.rose500,
              ),
              const SizedBox(height: 24),
              Text(
                'Camera Error',
                style: AppTypography.headline2.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'An unknown error occurred',
                style: AppTypography.body1.copyWith(
                  color: AppColors.slate400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _initializeCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_isInitialized)
            const CameraPreviewWidget()
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // Shutter animation overlay
          if (_showShutterAnimation)
            Container(
              key: const Key('shutter_animation'),
              color: Colors.white.withOpacity(0.15),
            ),

          // Camera switch animation overlay
          if (_showSwitchAnimation)
            AnimatedBuilder(
              animation: _switchAnimation,
              builder: (context, child) {
                return Container(
                  key: const Key('camera_switch_animation'),
                  color: Colors.black.withOpacity(_switchAnimation.value * 0.5),
                );
              },
            ),

          // No audio warning overlay (when microphone permission denied in video mode)
          if (_showNoAudioWarning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          key: const Key('no_audio_warning'),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurfaceHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.mic_off,
                                size: 48,
                                color: AppColors.orange500,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Audio Permission',
                                style: AppTypography.headline3.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Video will be recorded with no audio. Grant microphone permission to record audio with your videos.',
                                style: AppTypography.body1.copyWith(
                                  color: AppColors.slate400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  key:
                                      const Key('proceed_without_audio_button'),
                                  onPressed: _dismissNoAudioWarning,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.orange500,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Continue Without Audio',
                                    style: AppTypography.button,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  key: const Key('fix_permissions_button'),
                                  onPressed: _openMicrophoneSettings,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.slate400,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Fix Permissions',
                                    style: AppTypography.button,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls - positioned to ensure capture button is in bottom third and centered
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Duration warning (when near max duration)
                    if (_shouldShowDurationWarning) ...[
                      Container(
                        key: const Key('duration_warning'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange500.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_timeRemainingSeconds}s remaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Recording indicator and timer (only when recording)
                    if (_isRecording) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            key: const Key('recording_indicator'),
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            key: const Key('recording_timer'),
                            _formatRecordingTime(_recordingSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Controls row with centered capture button using SizedBox constraints
                    SizedBox(
                      height: 72,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Photo mode button (left side) - fixed width container
                          if (!_isRecording)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: GestureDetector(
                                    key: const Key('photo_mode_button'),
                                    onTap: _cameraMode == CameraMode.video
                                        ? _switchToPhotoMode
                                        : null,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _cameraMode == CameraMode.photo
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.transparent,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: _cameraMode == CameraMode.photo
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),

                          // Main capture/record button (center)
                          if (_cameraMode == CameraMode.photo)
                            GestureDetector(
                              key: const Key('capture_button'),
                              onTap: _capturePhoto,
                              child: Container(
                                width: 72,
                                height: 72,
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
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else if (!_isRecording)
                            GestureDetector(
                              key: const Key('record_button'),
                              onTap: _startRecording,
                              child: Container(
                                width: 72,
                                height: 72,
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
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              key: const Key('stop_button'),
                              onTap: _stopRecording,
                              child: Container(
                                width: 72,
                                height: 72,
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
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Video mode button (right side) - fixed width container
                          if (!_isRecording)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 24),
                                  child: GestureDetector(
                                    key: const Key('video_mode_button'),
                                    onTap: _cameraMode == CameraMode.photo
                                        ? _switchToVideoMode
                                        : null,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _cameraMode == CameraMode.video
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.transparent,
                                      ),
                                      child: Icon(
                                        Icons.videocam,
                                        color: _cameraMode == CameraMode.video
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top bar with close button, flash, and camera switch
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Level indicator toggle button
                          IconButton(
                            key: const Key('level_indicator_toggle'),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ref
                                  .read(levelIndicatorProvider.notifier)
                                  .toggleOverlay();
                            },
                            icon: Consumer(
                              builder: (context, ref, child) {
                                final levelState =
                                    ref.watch(levelIndicatorProvider);
                                return Icon(
                                  levelState.isEnabled
                                      ? Icons.straighten
                                      : Icons.straighten_outlined,
                                  color: Colors.white,
                                  size: 22,
                                );
                              },
                            ),
                          ),
                          // Timestamp overlay toggle button
                          IconButton(
                            key: const Key('timestamp_overlay_toggle'),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ref
                                  .read(timestampOverlayProvider.notifier)
                                  .toggleOverlay();
                            },
                            icon: Consumer(
                              builder: (context, ref, child) {
                                final timestampState =
                                    ref.watch(timestampOverlayProvider);
                                return Icon(
                                  timestampState.isEnabled
                                      ? Icons.access_time_filled
                                      : Icons.access_time,
                                  color: Colors.white,
                                  size: 22,
                                );
                              },
                            ),
                          ),
                          // GPS overlay toggle button
                          IconButton(
                            key: const Key('gps_overlay_toggle'),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ref
                                  .read(gpsOverlayProvider.notifier)
                                  .toggleOverlay();
                            },
                            icon: Consumer(
                              builder: (context, ref, child) {
                                final gpsState = ref.watch(gpsOverlayProvider);
                                return Icon(
                                  gpsState.isEnabled
                                      ? Icons.location_on
                                      : Icons.location_off,
                                  color: Colors.white,
                                  size: 22,
                                );
                              },
                            ),
                          ),
                          Semantics(
                            label: _getFlashLabel(),
                            button: true,
                            child: IconButton(
                              key: const Key('flash_button'),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              onPressed: _toggleFlashMode,
                              icon: Icon(
                                _getFlashIcon(),
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('camera_switch_button'),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: _switchCamera,
                            icon: const Icon(
                              Icons.cameraswitch,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // GPS coordinates overlay
          const Positioned(
            left: 16,
            bottom: 120,
            child: GpsOverlayWidget(),
          ),

          // Timestamp overlay
          const Positioned(
            right: 16,
            bottom: 120,
            child: TimestampOverlayWidget(),
          ),

          // Level indicator
          const Positioned(
            left: 0,
            right: 0,
            top: 100,
            child: Center(
              child: LevelIndicatorWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays the camera preview with pinch-to-zoom and tap-to-focus support.
/// In production, the actual camera preview is managed by the CameraService.
/// This widget provides the visual container that fills the screen.
class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(cameraZoomProvider);
    final focusState = ref.watch(cameraFocusProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onScaleStart: (_) {
            ref.read(cameraZoomProvider.notifier).onScaleStart();
          },
          onScaleUpdate: (details) {
            ref.read(cameraZoomProvider.notifier).onScaleUpdate(details.scale);
          },
          onScaleEnd: (_) {
            ref.read(cameraZoomProvider.notifier).onScaleEnd();
          },
          onTapUp: (details) {
            ref
                .read(cameraFocusProvider.notifier)
                .onTapToFocus(details.localPosition, previewSize);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview placeholder
              Container(
                color: Colors.black,
                child: const SizedBox.expand(),
              ),
              // Focus indicator
              if (focusState.showIndicator && focusState.focusPoint != null)
                Positioned(
                  left: focusState.focusPoint!.dx - 30,
                  top: focusState.focusPoint!.dy - 30,
                  child:
                      const FocusIndicatorWidget(key: Key('focus_indicator')),
                ),
              // Zoom level indicator (shown when zoomed above 1.0x)
              if (zoomState.isZoomed)
                Positioned(
                  bottom: 180,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      key: const Key('zoom_indicator'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        zoomState.formattedZoomLevel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that displays the focus indicator animation.
class FocusIndicatorWidget extends StatefulWidget {
  const FocusIndicatorWidget({super.key});

  @override
  State<FocusIndicatorWidget> createState() => _FocusIndicatorWidgetState();
}

class _FocusIndicatorWidgetState extends State<FocusIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget that displays GPS coordinates overlay on the camera.
class GpsOverlayWidget extends ConsumerWidget {
  const GpsOverlayWidget({super.key});

  void _showManualLocationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => ManualLocationDialog(
        onConfirm: (latitude, longitude) {
          ref.read(gpsOverlayProvider.notifier).setManualLocation(
                LocationPosition(latitude: latitude, longitude: longitude),
              );
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsState = ref.watch(gpsOverlayProvider);

    if (!gpsState.isEnabled) {
      return const SizedBox.shrink();
    }

    // Show unavailable when we don't have a position and aren't actively loading
    // But if we have a manual location set, we do have a position
    final showLocationUnavailable =
        !gpsState.hasPosition && !gpsState.isLoading;

    return Container(
      key: const Key('gps_overlay'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color:
                    gpsState.hasPermission ? Colors.white : AppColors.slate400,
                size: 16,
              ),
              const SizedBox(width: 4),
              if (showLocationUnavailable)
                const Text(
                  'Location unavailable',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else if (gpsState.hasPosition)
                Text(
                  '${gpsState.formattedLatitude}, ${gpsState.formattedLongitude}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const Text(
                  'Acquiring location...',
                  style: TextStyle(
                    color: AppColors.slate400,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          // Add location button when location is unavailable
          if (showLocationUnavailable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                key: const Key('add_location_button'),
                onTap: () => _showManualLocationDialog(context, ref),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.orange500.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_location_alt,
                        color: AppColors.orange500,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Add location',
                        style: TextStyle(
                          color: AppColors.orange500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Manual location indicator
          if (gpsState.isManualLocation && gpsState.hasPosition)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                key: Key('manual_location_indicator'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_location,
                    color: AppColors.orange500,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Manual location',
                    style: TextStyle(
                      color: AppColors.orange500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          // Stale location indicator
          if (gpsState.isLocationStale &&
              gpsState.hasPosition &&
              !gpsState.isManualLocation)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                key: Key('stale_location_indicator'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.orange500,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Location may be stale',
                    style: TextStyle(
                      color: AppColors.orange500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Dialog for entering manual location coordinates.
class ManualLocationDialog extends StatefulWidget {
  const ManualLocationDialog({
    super.key,
    required this.onConfirm,
  });

  final void Function(double latitude, double longitude) onConfirm;

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final latText = _latitudeController.text.trim();
    final lonText = _longitudeController.text.trim();

    final latitude = double.tryParse(latText);
    final longitude = double.tryParse(lonText);

    if (latitude == null || longitude == null) {
      setState(() {
        _errorMessage = 'Please enter valid coordinates';
      });
      return;
    }

    if (latitude < -90 || latitude > 90) {
      setState(() {
        _errorMessage = 'Latitude must be between -90 and 90';
      });
      return;
    }

    if (longitude < -180 || longitude > 180) {
      setState(() {
        _errorMessage = 'Longitude must be between -180 and 180';
      });
      return;
    }

    widget.onConfirm(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const Key('manual_location_dialog'),
      backgroundColor: AppColors.darkSurfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.add_location_alt,
                  color: AppColors.orange500,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Location',
                  style: AppTypography.headline3.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Enter GPS coordinates manually',
              style: AppTypography.body2.copyWith(
                color: AppColors.slate400,
              ),
            ),
            const SizedBox(height: 20),
            // Latitude field
            TextField(
              key: const Key('manual_latitude_field'),
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Latitude',
                labelStyle: const TextStyle(color: AppColors.slate400),
                hintText: 'e.g., 45.8150',
                hintStyle:
                    TextStyle(color: AppColors.slate400.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.orange500),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Longitude field
            TextField(
              key: const Key('manual_longitude_field'),
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Longitude',
                labelStyle: const TextStyle(color: AppColors.slate400),
                hintText: 'e.g., 15.9819',
                hintStyle:
                    TextStyle(color: AppColors.slate400.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.orange500),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.rose500,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTypography.button.copyWith(
                      color: AppColors.slate400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  key: const Key('confirm_manual_location'),
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays timestamp overlay on the camera.
class TimestampOverlayWidget extends ConsumerWidget {
  const TimestampOverlayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timestampState = ref.watch(timestampOverlayProvider);

    if (!timestampState.isEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('timestamp_overlay'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            timestampState.formattedTimestamp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays a level indicator using accelerometer data.
class LevelIndicatorWidget extends ConsumerWidget {
  const LevelIndicatorWidget({
    super.key,
    this.tiltAngle,
    this.isLevel,
    this.indicatorColor,
  });

  /// Override tilt angle for testing.
  final double? tiltAngle;

  /// Override isLevel for testing.
  final bool? isLevel;

  /// Override indicator color for testing.
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelState = ref.watch(levelIndicatorProvider);

    if (!levelState.isEnabled) {
      return const SizedBox.shrink();
    }

    final currentTiltAngle = tiltAngle ?? levelState.tiltAngle;
    final currentIsLevel = isLevel ?? levelState.isLevel;
    final currentIndicatorColor = indicatorColor ??
        (currentIsLevel ? AppColors.emerald500 : Colors.white);

    return Container(
      key: const Key('level_indicator'),
      width: 200,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center line indicator
          Container(
            width: 2,
            height: 20,
            color: Colors.white.withOpacity(0.3),
          ),
          // Bubble indicator
          Transform.translate(
            offset: Offset(
              // Clamp the offset to keep bubble within bounds
              (currentTiltAngle / 45.0 * 80.0).clamp(-80.0, 80.0),
              0,
            ),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndicatorColor,
                boxShadow: currentIsLevel
                    ? [
                        BoxShadow(
                          color: AppColors.emerald500.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          // Side markers
          Positioned(
            left: 20,
            child: Container(
              width: 1,
              height: 12,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          Positioned(
            right: 20,
            child: Container(
              width: 1,
              height: 12,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
