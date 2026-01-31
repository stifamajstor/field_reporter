import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Arguments for the video preview screen.
class VideoPreviewArguments {
  const VideoPreviewArguments({
    required this.videoPath,
    required this.durationSeconds,
  });

  final String videoPath;
  final int durationSeconds;
}

/// Screen that displays the recorded video with accept/retake options.
class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.arguments,
  });

  final VideoPreviewArguments arguments;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    // Auto-play the video on screen open
    _isPlaying = true;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video player placeholder
          Container(
            key: const Key('video_player'),
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaying ? Icons.play_circle_filled : Icons.pause_circle,
                    color: AppColors.slate400,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDuration(widget.arguments.durationSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retake button
                    _buildRetakeButton(context),
                    const SizedBox(width: 24),
                    // Accept button
                    _buildAcceptButton(context),
                  ],
                ),
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
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

  Widget _buildRetakeButton(BuildContext context) {
    return GestureDetector(
      key: const Key('retake_video_button'),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(VideoPreviewResult.retake);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Retake',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return GestureDetector(
      key: const Key('accept_video_button'),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(VideoPreviewResult.accept);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.orange500,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Accept',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result from the video preview screen.
enum VideoPreviewResult {
  accept,
  retake,
}
