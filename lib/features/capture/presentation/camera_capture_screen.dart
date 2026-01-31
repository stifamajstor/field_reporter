import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/camera_service.dart';
import '../../../services/permission_service.dart';
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
      });
      await _initializeCamera();
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final permissionService = ref.read(permissionServiceProvider);
    final status = await permissionService.requestCameraPermission();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      await _initializeCamera();
    } else if (status.isPermanentlyDenied) {
      await permissionService.openAppSettings();
    }
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

      // Show shutter animation
      setState(() {
        _showShutterAnimation = true;
      });

      final cameraService = ref.read(cameraServiceProvider);
      final photoPath =
          await cameraService.capturePhoto(compassHeading: compassHeading);

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

    setState(() {
      _hasMicrophonePermission = micStatus.isGranted;
      _cameraMode = CameraMode.video;
    });
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

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                            const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Photo mode button (left side)
                        if (!_isRecording)
                          GestureDetector(
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
                          )
                        else
                          const SizedBox(width: 48),

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

                        // Video mode button (right side)
                        if (!_isRecording)
                          GestureDetector(
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
                          )
                        else
                          const SizedBox(width: 48),
                      ],
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Row(
                      children: [
                        // Level indicator toggle button
                        IconButton(
                          key: const Key('level_indicator_toggle'),
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
                                size: 28,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Timestamp overlay toggle button
                        IconButton(
                          key: const Key('timestamp_overlay_toggle'),
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
                                size: 28,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // GPS overlay toggle button
                        IconButton(
                          key: const Key('gps_overlay_toggle'),
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
                                size: 28,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: _getFlashLabel(),
                          button: true,
                          child: IconButton(
                            key: const Key('flash_button'),
                            onPressed: _toggleFlashMode,
                            icon: Icon(
                              _getFlashIcon(),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: const Key('camera_switch_button'),
                          onPressed: _switchCamera,
                          icon: const Icon(
                            Icons.cameraswitch,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
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

/// Widget that displays the camera preview with pinch-to-zoom support.
/// In production, the actual camera preview is managed by the CameraService.
/// This widget provides the visual container that fills the screen.
class CameraPreviewWidget extends ConsumerWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoomState = ref.watch(cameraZoomProvider);

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview placeholder
          Container(
            color: Colors.black,
            child: const SizedBox.expand(),
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
  }
}

/// Widget that displays GPS coordinates overlay on the camera.
class GpsOverlayWidget extends ConsumerWidget {
  const GpsOverlayWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsState = ref.watch(gpsOverlayProvider);

    if (!gpsState.isEnabled) {
      return const SizedBox.shrink();
    }

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
              if (!gpsState.hasPermission)
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
        ],
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
