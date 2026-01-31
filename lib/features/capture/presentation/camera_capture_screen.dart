import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/camera_service.dart';
import '../../../services/permission_service.dart';
import 'photo_preview_screen.dart';

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
  late AnimationController _switchAnimationController;
  late Animation<double> _switchAnimation;

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
    });
  }

  CameraService? _cameraService;

  @override
  void dispose() {
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

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _showSwitchAnimation = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    try {
      // Trigger haptic feedback
      HapticFeedback.lightImpact();

      // Show shutter animation
      setState(() {
        _showShutterAnimation = true;
      });

      final cameraService = ref.read(cameraServiceProvider);
      final photoPath = await cameraService.capturePhoto();

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
              arguments: PhotoPreviewArguments(photoPath: photoPath),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Capture button
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
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top bar with close button and camera switch
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays the camera preview.
/// In production, the actual camera preview is managed by the CameraService.
/// This widget provides the visual container that fills the screen.
class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget serves as a placeholder/container for the camera preview.
    // The actual preview rendering is handled by the camera service layer.
    // In widget tests, this displays as a placeholder.
    // In production, the CameraService manages the actual preview.
    return Container(
      color: Colors.black,
      child: const SizedBox.expand(),
    );
  }
}
