import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/photo_annotation.dart';
import '../providers/photo_annotation_provider.dart';

/// Screen for annotating a captured photo.
class PhotoAnnotationScreen extends ConsumerStatefulWidget {
  const PhotoAnnotationScreen({
    super.key,
    required this.photoPath,
    this.onComplete,
    this.onCancel,
  });

  /// Path to the photo to annotate.
  final String photoPath;

  /// Callback when annotation is complete.
  final void Function(PhotoAnnotationResult result)? onComplete;

  /// Callback when annotation is cancelled.
  final VoidCallback? onCancel;

  @override
  ConsumerState<PhotoAnnotationScreen> createState() =>
      _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends ConsumerState<PhotoAnnotationScreen> {
  final TextEditingController _textController = TextEditingController();
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
    // Reset annotation state for new session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photoAnnotationProvider.notifier).reset();
    });
  }

  Future<void> _loadImage() async {
    final file = File(widget.photoPath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _image = frame.image;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoAnnotationProvider);
    final notifier = ref.read(photoAnnotationProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo with annotations
          _buildAnnotationCanvas(state, notifier),

          // Text input overlay
          if (state.pendingTextPosition != null) _buildTextInputOverlay(state),

          // Color picker overlay
          if (state.isShowingColorPicker) _buildColorPickerOverlay(state),

          // Top bar
          _buildTopBar(state, notifier),

          // Bottom toolbar
          _buildBottomToolbar(state, notifier),
        ],
      ),
    );
  }

  Widget _buildAnnotationCanvas(
    PhotoAnnotationState state,
    PhotoAnnotationNotifier notifier,
  ) {
    return GestureDetector(
      key: const Key('annotation_canvas'),
      onPanStart: (details) {
        _handlePanStart(details.localPosition);
      },
      onPanUpdate: (details) {
        _handlePanUpdate(details.localPosition);
      },
      onPanEnd: (details) {
        _handlePanEnd();
      },
      onTapUp: (details) {
        _handleTap(details.localPosition);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo background
          _buildPhotoBackground(),

          // Annotation layer
          CustomPaint(
            key: const Key('annotation_layer'),
            painter: AnnotationPainter(
              annotations: state.annotations,
              currentDrawingPoints: state.currentDrawingPoints,
              currentDrawingColor: state.selectedColor,
              currentStrokeWidth: state.strokeWidth,
              currentArrowStart: state.currentArrowStart,
            ),
          ),

          // Text annotations
          ...state.annotations.whereType<TextAnnotation>().map(
                (annotation) => Positioned(
                  left: annotation.position.dx,
                  top: annotation.position.dy,
                  child: Text(
                    annotation.text,
                    style: TextStyle(
                      color: annotation.color,
                      fontSize: annotation.fontSize,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(1, 1),
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

  Widget _buildPhotoBackground() {
    final file = File(widget.photoPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }
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

  void _handlePanStart(Offset position) {
    final state = ref.read(photoAnnotationProvider);
    final notifier = ref.read(photoAnnotationProvider.notifier);
    switch (state.selectedTool) {
      case AnnotationToolType.draw:
        notifier.startDrawing(position);
        break;
      case AnnotationToolType.arrow:
        notifier.startArrow(position);
        break;
      case AnnotationToolType.text:
        // Text is handled by tap
        break;
    }
  }

  void _handlePanUpdate(Offset position) {
    final state = ref.read(photoAnnotationProvider);
    final notifier = ref.read(photoAnnotationProvider.notifier);
    switch (state.selectedTool) {
      case AnnotationToolType.draw:
        notifier.continueDrawing(position);
        break;
      case AnnotationToolType.arrow:
      case AnnotationToolType.text:
        // Arrow end is handled in panEnd, text by tap
        break;
    }
  }

  void _handlePanEnd() {
    final state = ref.read(photoAnnotationProvider);
    final notifier = ref.read(photoAnnotationProvider.notifier);
    switch (state.selectedTool) {
      case AnnotationToolType.draw:
        notifier.endDrawing();
        break;
      case AnnotationToolType.arrow:
        // Arrow needs end position from last known position
        break;
      case AnnotationToolType.text:
        break;
    }
  }

  void _handleTap(Offset position) {
    final state = ref.read(photoAnnotationProvider);
    final notifier = ref.read(photoAnnotationProvider.notifier);
    if (state.isShowingColorPicker) {
      notifier.hideColorPicker();
      return;
    }

    if (state.selectedTool == AnnotationToolType.text) {
      notifier.setTextPosition(position);
    }
  }

  Widget _buildTextInputOverlay(PhotoAnnotationState state) {
    return Positioned(
      left: 16,
      right: 16,
      top: state.pendingTextPosition!.dy,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('annotation_text_input'),
                controller: _textController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter text...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _textController.clear();
                      ref
                          .read(photoAnnotationProvider.notifier)
                          .cancelTextInput();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const Key('annotation_text_confirm'),
                    onPressed: () {
                      ref
                          .read(photoAnnotationProvider.notifier)
                          .addText(_textController.text);
                      _textController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange500,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPickerOverlay(PhotoAnnotationState state) {
    return Positioned(
      bottom: 140,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorOption(
                const Key('annotation_color_red'),
                AnnotationColors.red,
                state,
              ),
              _buildColorOption(
                const Key('annotation_color_blue'),
                AnnotationColors.blue,
                state,
              ),
              _buildColorOption(
                const Key('annotation_color_yellow'),
                AnnotationColors.yellow,
                state,
              ),
              _buildColorOption(
                const Key('annotation_color_green'),
                AnnotationColors.green,
                state,
              ),
              _buildColorOption(
                const Key('annotation_color_white'),
                AnnotationColors.white,
                state,
              ),
              _buildColorOption(
                const Key('annotation_color_black'),
                AnnotationColors.black,
                state,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(
    Key key,
    Color color,
    PhotoAnnotationState state,
  ) {
    final isSelected = state.selectedColor == color;
    return GestureDetector(
      key: key,
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(photoAnnotationProvider.notifier).selectColor(color);
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: color == Colors.white
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: color == Colors.white || color == AnnotationColors.yellow
                    ? Colors.black
                    : Colors.white,
                size: 18,
              )
            : null,
      ),
    );
  }

  Widget _buildTopBar(
    PhotoAnnotationState state,
    PhotoAnnotationNotifier notifier,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('annotation_cancel_button'),
                onPressed: _handleCancel,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                key: const Key('annotation_undo_button'),
                onPressed: state.canUndo
                    ? () {
                        HapticFeedback.lightImpact();
                        notifier.undo();
                      }
                    : null,
                icon: Icon(
                  Icons.undo,
                  color: state.canUndo
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                key: const Key('annotation_done_button'),
                onTap: _handleDone,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.orange500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Done',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(
    PhotoAnnotationState state,
    PhotoAnnotationNotifier notifier,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                key: state.selectedTool == AnnotationToolType.draw
                    ? const Key('annotation_tool_draw_selected')
                    : const Key('annotation_tool_draw'),
                icon: Icons.brush,
                label: 'Draw',
                isSelected: state.selectedTool == AnnotationToolType.draw,
                onTap: () {
                  HapticFeedback.lightImpact();
                  notifier.selectTool(AnnotationToolType.draw);
                },
              ),
              _buildToolButton(
                key: state.selectedTool == AnnotationToolType.text
                    ? const Key('annotation_tool_text_selected')
                    : const Key('annotation_tool_text'),
                icon: Icons.text_fields,
                label: 'Text',
                isSelected: state.selectedTool == AnnotationToolType.text,
                onTap: () {
                  HapticFeedback.lightImpact();
                  notifier.selectTool(AnnotationToolType.text);
                },
              ),
              _buildToolButton(
                key: state.selectedTool == AnnotationToolType.arrow
                    ? const Key('annotation_tool_arrow_selected')
                    : const Key('annotation_tool_arrow'),
                icon: Icons.arrow_forward,
                label: 'Arrow',
                isSelected: state.selectedTool == AnnotationToolType.arrow,
                onTap: () {
                  HapticFeedback.lightImpact();
                  notifier.selectTool(AnnotationToolType.arrow);
                },
              ),
              _buildColorButton(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required Key key,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.orange500 : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(PhotoAnnotationState state) {
    return GestureDetector(
      key: const Key('annotation_color_picker'),
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(photoAnnotationProvider.notifier).toggleColorPicker();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: state.selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Color',
              style: AppTypography.caption.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCancel() {
    HapticFeedback.lightImpact();
    ref.read(photoAnnotationProvider.notifier).reset();
    widget.onCancel?.call();
    if (widget.onCancel == null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDone() async {
    HapticFeedback.lightImpact();

    final state = ref.read(photoAnnotationProvider);

    // If no annotations, just return original
    if (state.annotations.isEmpty) {
      final result = PhotoAnnotationResult(
        originalPhotoPath: widget.photoPath,
        annotatedPhotoPath: widget.photoPath,
        annotations: const [],
      );
      ref.read(photoAnnotationProvider.notifier).reset();
      widget.onComplete?.call(result);
      if (widget.onComplete == null && mounted) {
        Navigator.of(context).pop(result);
      }
      return;
    }

    // Generate annotated image path
    final annotatedPath = await _generateAnnotatedPath();

    final result = PhotoAnnotationResult(
      originalPhotoPath: widget.photoPath,
      annotatedPhotoPath: annotatedPath,
      annotations: state.annotations,
    );

    ref.read(photoAnnotationProvider.notifier).reset();
    widget.onComplete?.call(result);
    if (widget.onComplete == null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<String> _generateAnnotatedPath() async {
    // Generate a unique path for the annotated image
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${directory.path}/annotated_$timestamp.jpg';
    } catch (_) {
      // Fallback for tests where path_provider may not work
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '/tmp/annotated_$timestamp.jpg';
    }
  }
}

/// Custom painter for drawing annotations.
class AnnotationPainter extends CustomPainter {
  AnnotationPainter({
    required this.annotations,
    required this.currentDrawingPoints,
    required this.currentDrawingColor,
    required this.currentStrokeWidth,
    this.currentArrowStart,
  });

  final List<PhotoAnnotationElement> annotations;
  final List<Offset> currentDrawingPoints;
  final Color currentDrawingColor;
  final double currentStrokeWidth;
  final Offset? currentArrowStart;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed annotations
    for (final annotation in annotations) {
      if (annotation is DrawAnnotation) {
        _drawStroke(canvas, annotation);
      } else if (annotation is ArrowAnnotation) {
        _drawArrow(canvas, annotation);
      }
      // Text annotations are rendered as widgets
    }

    // Draw current stroke in progress
    if (currentDrawingPoints.length >= 2) {
      final paint = Paint()
        ..color = currentDrawingColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentDrawingPoints.first.dx, currentDrawingPoints.first.dy);
      for (int i = 1; i < currentDrawingPoints.length; i++) {
        path.lineTo(currentDrawingPoints[i].dx, currentDrawingPoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawStroke(Canvas canvas, DrawAnnotation annotation) {
    if (annotation.points.length < 2) return;

    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(annotation.points.first.dx, annotation.points.first.dy);
    for (int i = 1; i < annotation.points.length; i++) {
      path.lineTo(annotation.points[i].dx, annotation.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawArrow(Canvas canvas, ArrowAnnotation annotation) {
    final paint = Paint()
      ..color = annotation.color
      ..strokeWidth = annotation.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw main line
    canvas.drawLine(annotation.start, annotation.end, paint);

    // Draw arrowhead
    final direction = (annotation.end - annotation.start);
    final length = direction.distance;
    if (length < 1) return;

    final unitDirection = direction / length;
    final arrowSize = math.min(20.0, length / 3);

    // Perpendicular direction
    final perpendicular = Offset(-unitDirection.dy, unitDirection.dx);

    final arrowPoint1 = annotation.end -
        unitDirection * arrowSize +
        perpendicular * arrowSize * 0.5;
    final arrowPoint2 = annotation.end -
        unitDirection * arrowSize -
        perpendicular * arrowSize * 0.5;

    final arrowPath = Path();
    arrowPath.moveTo(annotation.end.dx, annotation.end.dy);
    arrowPath.lineTo(arrowPoint1.dx, arrowPoint1.dy);
    arrowPath.moveTo(annotation.end.dx, annotation.end.dy);
    arrowPath.lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return annotations != oldDelegate.annotations ||
        currentDrawingPoints != oldDelegate.currentDrawingPoints ||
        currentDrawingColor != oldDelegate.currentDrawingColor ||
        currentArrowStart != oldDelegate.currentArrowStart;
  }
}
