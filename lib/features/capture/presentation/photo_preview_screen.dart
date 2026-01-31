import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Arguments for the photo preview screen.
class PhotoPreviewArguments {
  const PhotoPreviewArguments({required this.photoPath});

  /// Path to the captured photo file.
  final String photoPath;
}

/// Screen that displays the captured photo with accept/retake options.
class PhotoPreviewScreen extends StatelessWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.arguments,
  });

  final PhotoPreviewArguments arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo preview
          _buildPhotoPreview(),

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

  Widget _buildPhotoPreview() {
    final file = File(arguments.photoPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }
    // Fallback for tests where file doesn't exist
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.image,
          color: AppColors.slate400,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildRetakeButton(BuildContext context) {
    return GestureDetector(
      key: const Key('retake_photo_button'),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(PhotoPreviewResult.retake);
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
      key: const Key('accept_photo_button'),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop(PhotoPreviewResult.accept);
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

/// Result from the photo preview screen.
enum PhotoPreviewResult {
  accept,
  retake,
}
