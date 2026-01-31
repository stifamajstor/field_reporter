import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import '../features/entries/domain/entry.dart';

/// A thumbnail widget that loads images progressively with placeholder
/// and smooth fade transition.
///
/// Shows a placeholder immediately while the thumbnail loads, then
/// fades in the actual image when ready. Optimized for smooth scrolling
/// in lists with many entries.
class ProgressiveThumbnail extends StatefulWidget {
  const ProgressiveThumbnail({
    super.key,
    required this.entry,
    this.size = 64,
    this.borderRadius = 8,
    this.simulateSlowLoad = false,
  });

  /// The entry to display thumbnail for.
  final Entry entry;

  /// Size of the thumbnail (width and height).
  final double size;

  /// Border radius of the thumbnail.
  final double borderRadius;

  /// For testing: simulate slow image loading.
  final bool simulateSlowLoad;

  @override
  State<ProgressiveThumbnail> createState() => _ProgressiveThumbnailState();
}

class _ProgressiveThumbnailState extends State<ProgressiveThumbnail>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _imageLoaded = false;
  bool _showImage = false;
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimations.fadeIn,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppAnimations.easeOut,
    );
    _loadImage();
  }

  @override
  void didUpdateWidget(ProgressiveThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.thumbnailPath != widget.entry.thumbnailPath ||
        oldWidget.entry.mediaPath != widget.entry.mediaPath) {
      _imageLoaded = false;
      _showImage = false;
      _fadeController.reset();
      _loadImage();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final thumbnailPath = _getThumbnailPath();
    if (thumbnailPath == null) {
      return;
    }

    // For testing slow loads
    if (widget.simulateSlowLoad) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final file = File(thumbnailPath);
    if (!file.existsSync()) {
      return;
    }

    _imageProvider = FileImage(file);

    // Pre-cache the image
    if (mounted) {
      try {
        await precacheImage(_imageProvider!, context);
        if (mounted) {
          setState(() {
            _imageLoaded = true;
            _showImage = true;
          });
          _fadeController.forward();
        }
      } catch (_) {
        // Image failed to load, keep showing placeholder
      }
    }
  }

  String? _getThumbnailPath() {
    if (widget.entry.thumbnailPath != null) {
      return widget.entry.thumbnailPath;
    }
    if (widget.entry.type == EntryType.photo &&
        widget.entry.mediaPath != null) {
      return widget.entry.mediaPath;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder (always visible behind)
            AnimatedOpacity(
              opacity: _showImage ? 0.0 : 1.0,
              duration: AppAnimations.fadeIn,
              curve: AppAnimations.easeOut,
              child: _Placeholder(
                key: const Key('thumbnail_placeholder'),
                entryType: widget.entry.type,
                isDark: isDark,
              ),
            ),
            // Actual image (fades in over placeholder)
            if (_imageLoaded && _imageProvider != null)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Image(
                  key: const Key('thumbnail_image'),
                  image: _imageProvider!,
                  fit: BoxFit.cover,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) {
                      return child;
                    }
                    return child;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _Placeholder(
                      entryType: widget.entry.type,
                      isDark: isDark,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder widget shown while thumbnail is loading.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    super.key,
    required this.entryType,
    required this.isDark,
  });

  final EntryType entryType;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
      child: Center(
        child: Icon(
          _iconForType(entryType),
          color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          size: 28,
        ),
      ),
    );
  }

  IconData _iconForType(EntryType type) => switch (type) {
        EntryType.photo => Icons.photo,
        EntryType.video => Icons.videocam,
        EntryType.audio => Icons.mic,
        EntryType.note => Icons.note,
        EntryType.scan => Icons.qr_code_scanner,
      };
}
