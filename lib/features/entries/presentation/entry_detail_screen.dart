import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../domain/entry.dart';
import '../providers/entries_provider.dart';

/// Screen for displaying entry details.
class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({
    super.key,
    required this.entry,
  });

  /// The entry to display.
  final Entry entry;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  late Entry _currentEntry;
  bool _isEditingAnnotation = false;
  bool _isTranscribing = false;
  bool _isEditingTranscription = false;
  late TextEditingController _annotationController;
  late TextEditingController _transcriptionController;
  final FocusNode _annotationFocusNode = FocusNode();
  final FocusNode _transcriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _annotationController =
        TextEditingController(text: _currentEntry.annotation ?? '');
    _transcriptionController =
        TextEditingController(text: _currentEntry.content ?? '');
  }

  @override
  void dispose() {
    _annotationController.dispose();
    _annotationFocusNode.dispose();
    _transcriptionController.dispose();
    _transcriptionFocusNode.dispose();
    super.dispose();
  }

  void _startEditingAnnotation() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditingAnnotation = true;
      _annotationController.text = _currentEntry.annotation ?? '';
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _annotationFocusNode.requestFocus();
    });
  }

  Future<void> _saveAnnotation() async {
    HapticFeedback.lightImpact();
    final newAnnotation = _annotationController.text.trim();
    final updatedEntry = _currentEntry.copyWith(
      annotation: newAnnotation.isNotEmpty ? newAnnotation : null,
    );

    await ref.read(entriesNotifierProvider.notifier).updateEntry(updatedEntry);

    setState(() {
      _currentEntry = updatedEntry;
      _isEditingAnnotation = false;
    });
  }

  void _cancelEditingAnnotation() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditingAnnotation = false;
      _annotationController.text = _currentEntry.annotation ?? '';
    });
  }

  Future<void> _requestTranscription() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isTranscribing = true;
    });

    try {
      final transcribedEntry = await ref
          .read(entriesNotifierProvider.notifier)
          .transcribeEntry(_currentEntry.id);

      setState(() {
        _currentEntry = transcribedEntry;
        _transcriptionController.text = transcribedEntry.content ?? '';
        _isTranscribing = false;
      });
    } catch (e) {
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  void _startEditingTranscription() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditingTranscription = true;
      _transcriptionController.text = _currentEntry.content ?? '';
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _transcriptionFocusNode.requestFocus();
    });
  }

  Future<void> _saveTranscription() async {
    HapticFeedback.lightImpact();
    final newContent = _transcriptionController.text.trim();
    final updatedEntry = _currentEntry.copyWith(
      content: newContent.isNotEmpty ? newContent : null,
    );

    await ref.read(entriesNotifierProvider.notifier).updateEntry(updatedEntry);

    setState(() {
      _currentEntry = updatedEntry;
      _isEditingTranscription = false;
    });
  }

  void _cancelEditingTranscription() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditingTranscription = false;
      _transcriptionController.text = _currentEntry.content ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(_labelForType(_currentEntry.type)),
        actions: [
          IconButton(
            key: const Key('edit_entry_button'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Implement edit functionality
            },
          ),
          IconButton(
            key: const Key('delete_entry_button'),
            icon: const Icon(Icons.delete_outlined),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media display section
            _MediaDisplay(entry: _currentEntry, isDark: isDark),

            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry type and timestamp header
                  _EntryHeader(entry: _currentEntry, isDark: isDark),
                  AppSpacing.verticalLg,

                  // Content section (for notes and scans)
                  if (_currentEntry.type == EntryType.note ||
                      _currentEntry.type == EntryType.scan) ...[
                    _ContentSection(entry: _currentEntry, isDark: isDark),
                    AppSpacing.verticalLg,
                  ],

                  // Transcription section (for audio entries)
                  if (_currentEntry.type == EntryType.audio) ...[
                    _TranscriptionSection(
                      entry: _currentEntry,
                      isDark: isDark,
                      isTranscribing: _isTranscribing,
                      isEditing: _isEditingTranscription,
                      controller: _transcriptionController,
                      focusNode: _transcriptionFocusNode,
                      onRequestTranscription: _requestTranscription,
                      onStartEditing: _startEditingTranscription,
                      onSave: _saveTranscription,
                      onCancel: _cancelEditingTranscription,
                    ),
                    AppSpacing.verticalLg,
                  ],

                  // Annotation section
                  _AnnotationSection(
                    entry: _currentEntry,
                    isDark: isDark,
                    isEditing: _isEditingAnnotation,
                    controller: _annotationController,
                    focusNode: _annotationFocusNode,
                    onStartEditing: _startEditingAnnotation,
                    onSave: _saveAnnotation,
                    onCancel: _cancelEditingAnnotation,
                  ),
                  AppSpacing.verticalLg,

                  // AI Description section
                  if (_currentEntry.aiDescription != null) ...[
                    _AiDescriptionSection(entry: _currentEntry, isDark: isDark),
                    AppSpacing.verticalLg,
                  ],

                  // Metadata section
                  _MetadataSection(entry: _currentEntry, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await ref
                  .read(entriesNotifierProvider.notifier)
                  .deleteEntry(_currentEntry.id);
              if (context.mounted) {
                Navigator.pop(context); // Close detail screen
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.rose500),
            ),
          ),
        ],
      ),
    );
  }

  String _labelForType(EntryType type) => switch (type) {
        EntryType.photo => 'Photo',
        EntryType.video => 'Video',
        EntryType.audio => 'Voice Memo',
        EntryType.note => 'Note',
        EntryType.scan => 'Scan',
      };
}

class _MediaDisplay extends StatelessWidget {
  const _MediaDisplay({
    required this.entry,
    required this.isDark,
  });

  final Entry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('entry_media_display'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      color: isDark ? AppColors.darkSurface : AppColors.slate100,
      child: _buildMediaContent(),
    );
  }

  Widget _buildMediaContent() {
    switch (entry.type) {
      case EntryType.photo:
        return _buildPhotoDisplay();
      case EntryType.video:
        return _buildVideoDisplay();
      case EntryType.audio:
        return _buildAudioDisplay();
      case EntryType.note:
        return _buildNoteDisplay();
      case EntryType.scan:
        return _buildScanDisplay();
    }
  }

  Widget _buildPhotoDisplay() {
    // Try to load actual image if path exists
    if (entry.mediaPath != null) {
      final file = File(entry.mediaPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          width: double.infinity,
        );
      }
    }

    // Placeholder for testing/when file doesn't exist
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate200,
        child: Center(
          child: Icon(
            Icons.photo,
            size: 64,
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDisplay() {
    final durationText = _formatDuration(entry.durationSeconds ?? 0);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail or placeholder
          Container(
            color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate200,
            child: entry.thumbnailPath != null
                ? Image.file(
                    File(entry.thumbnailPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _videoPlaceholder(),
                  )
                : _videoPlaceholder(),
          ),
          // Play button overlay
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 48,
              color: AppColors.slate900,
            ),
          ),
          // Duration badge
          Positioned(
            bottom: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                durationText,
                style: AppTypography.mono.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Center(
      child: Icon(
        Icons.videocam,
        size: 64,
        color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
      ),
    );
  }

  Widget _buildAudioDisplay() {
    final durationText = _formatDuration(entry.durationSeconds ?? 0);

    return Container(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSpacing.verticalLg,
          // Mic icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkOrangeSubtle : AppColors.orange50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic,
              size: 48,
              color: isDark ? AppColors.darkOrange : AppColors.orange500,
            ),
          ),
          AppSpacing.verticalMd,
          // Duration
          Text(
            durationText,
            style: AppTypography.monoLarge.copyWith(
              fontSize: 24,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
          AppSpacing.verticalMd,
          // Play button
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: Implement audio playback
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.darkOrange : AppColors.orange500,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          AppSpacing.verticalLg,
        ],
      ),
    );
  }

  Widget _buildNoteDisplay() {
    return Container(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSpacing.verticalLg,
          Icon(
            Icons.note,
            size: 64,
            color: isDark ? AppColors.darkOrange : AppColors.orange500,
          ),
          AppSpacing.verticalLg,
        ],
      ),
    );
  }

  Widget _buildScanDisplay() {
    return Container(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSpacing.verticalLg,
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: isDark ? AppColors.darkOrange : AppColors.orange500,
          ),
          AppSpacing.verticalLg,
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _EntryHeader extends StatelessWidget {
  const _EntryHeader({
    required this.entry,
    required this.isDark,
  });

  final Entry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Row(
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkOrangeSubtle : AppColors.orange50,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconForType(entry.type),
                size: 16,
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
              AppSpacing.horizontalXs,
              Text(
                _labelForType(entry.type),
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.horizontalMd,
        // Timestamp
        Text(
          '${dateFormat.format(entry.capturedAt)} at ${timeFormat.format(entry.capturedAt)}',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
        ),
      ],
    );
  }

  IconData _iconForType(EntryType type) => switch (type) {
        EntryType.photo => Icons.photo,
        EntryType.video => Icons.videocam,
        EntryType.audio => Icons.mic,
        EntryType.note => Icons.note,
        EntryType.scan => Icons.qr_code_scanner,
      };

  String _labelForType(EntryType type) => switch (type) {
        EntryType.photo => 'Photo',
        EntryType.video => 'Video',
        EntryType.audio => 'Voice Memo',
        EntryType.note => 'Note',
        EntryType.scan => 'Scan',
      };
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.entry,
    required this.isDark,
  });

  final Entry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (entry.content == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: isDark ? null : Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.type == EntryType.scan ? 'Scanned Data' : 'Note',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
            ),
          ),
          AppSpacing.verticalXs,
          Text(
            entry.content!,
            style: entry.type == EntryType.scan
                ? AppTypography.monoLarge.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                  )
                : AppTypography.body1.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnnotationSection extends StatelessWidget {
  const _AnnotationSection({
    required this.entry,
    required this.isDark,
    required this.isEditing,
    required this.controller,
    required this.focusNode,
    required this.onStartEditing,
    required this.onSave,
    required this.onCancel,
  });

  final Entry entry;
  final bool isDark;
  final bool isEditing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onStartEditing;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final hasAnnotation =
        entry.annotation != null && entry.annotation!.isNotEmpty;

    if (isEditing) {
      return _buildEditingState();
    }

    if (hasAnnotation) {
      return _buildAnnotationDisplay();
    }

    return _buildAddAnnotationButton();
  }

  Widget _buildAnnotationDisplay() {
    return GestureDetector(
      key: const Key('annotation_field'),
      onTap: onStartEditing,
      child: Container(
        key: const Key('annotation_section'),
        width: double.infinity,
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: isDark ? null : Border.all(color: AppColors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  size: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
                AppSpacing.horizontalXs,
                Text(
                  'Annotation',
                  style: AppTypography.caption.copyWith(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
              ],
            ),
            AppSpacing.verticalSm,
            Text(
              entry.annotation!,
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAnnotationButton() {
    return GestureDetector(
      key: const Key('add_annotation_button'),
      onTap: onStartEditing,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.slate200,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 20,
              color: isDark ? AppColors.darkOrange : AppColors.orange500,
            ),
            AppSpacing.horizontalSm,
            Text(
              'Add Annotation',
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingState() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkOrange : AppColors.orange500,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                size: 16,
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
              AppSpacing.horizontalXs,
              Text(
                'Annotation',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          TextField(
            key: const Key('annotation_text_field'),
            controller: controller,
            focusNode: focusNode,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter annotation or notes...',
              hintStyle: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.sm),
            ),
            style: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
          AppSpacing.verticalMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('annotation_cancel_button'),
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: AppTypography.button.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate700,
                  ),
                ),
              ),
              AppSpacing.horizontalSm,
              ElevatedButton(
                key: const Key('annotation_save_button'),
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.darkOrange : AppColors.orange500,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TranscriptionSection extends StatelessWidget {
  const _TranscriptionSection({
    required this.entry,
    required this.isDark,
    required this.isTranscribing,
    required this.isEditing,
    required this.controller,
    required this.focusNode,
    required this.onRequestTranscription,
    required this.onStartEditing,
    required this.onSave,
    required this.onCancel,
  });

  final Entry entry;
  final bool isDark;
  final bool isTranscribing;
  final bool isEditing;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onRequestTranscription;
  final VoidCallback onStartEditing;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final hasTranscription = entry.content != null && entry.content!.isNotEmpty;

    if (isTranscribing) {
      return _buildProcessingState();
    }

    if (isEditing) {
      return _buildEditingState();
    }

    if (hasTranscription) {
      return _buildTranscriptionDisplay();
    }

    return _buildTranscribeButton();
  }

  Widget _buildTranscribeButton() {
    return GestureDetector(
      key: const Key('transcribe_button'),
      onTap: onRequestTranscription,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.slate200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.transcribe,
              size: 20,
              color: isDark ? AppColors.darkOrange : AppColors.orange500,
            ),
            AppSpacing.horizontalSm,
            Text(
              'Transcribe',
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Container(
      key: const Key('transcription_processing_indicator'),
      width: double.infinity,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkOrange : AppColors.orange500,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
            ),
          ),
          AppSpacing.horizontalMd,
          Text(
            'Transcribing audio...',
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionDisplay() {
    return GestureDetector(
      key: const Key('transcription_section'),
      onTap: onStartEditing,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border: isDark ? null : Border.all(color: AppColors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.transcribe,
                  size: 16,
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                ),
                AppSpacing.horizontalXs,
                Text(
                  'Transcription',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkOrange : AppColors.orange500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
              ],
            ),
            AppSpacing.verticalSm,
            Text(
              entry.content!,
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingState() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkOrange : AppColors.orange500,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.transcribe,
                size: 16,
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
              AppSpacing.horizontalXs,
              Text(
                'Transcription',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          TextField(
            key: const Key('transcription_text_field'),
            controller: controller,
            focusNode: focusNode,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Edit transcription...',
              hintStyle: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
              filled: true,
              fillColor:
                  isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.sm),
            ),
            style: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
          AppSpacing.verticalMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('transcription_cancel_button'),
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: AppTypography.button.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate700,
                  ),
                ),
              ),
              AppSpacing.horizontalSm,
              ElevatedButton(
                key: const Key('transcription_save_button'),
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.darkOrange : AppColors.orange500,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiDescriptionSection extends StatelessWidget {
  const _AiDescriptionSection({
    required this.entry,
    required this.isDark,
  });

  final Entry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ai_description_section'),
      width: double.infinity,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: isDark ? null : Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
              AppSpacing.horizontalXs,
              Text(
                'AI Description',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          AppSpacing.verticalSm,
          Text(
            entry.aiDescription!,
            style: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({
    required this.entry,
    required this.isDark,
  });

  final Entry entry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final hasLocation = entry.latitude != null && entry.longitude != null;
    final hasAddress = entry.address != null;
    final hasCompass = entry.compassHeading != null;

    // Don't show section if no metadata
    if (!hasLocation && !hasAddress && !hasCompass) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('metadata_section'),
      width: double.infinity,
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: isDark ? null : Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metadata',
            style: AppTypography.headline3.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
          AppSpacing.verticalMd,

          // Timestamp
          _MetadataRow(
            icon: Icons.access_time,
            label: 'Time',
            value: timeFormat.format(entry.capturedAt),
            isDark: isDark,
          ),

          // GPS Coordinates
          if (hasLocation) ...[
            AppSpacing.verticalSm,
            _MetadataRow(
              icon: Icons.gps_fixed,
              label: 'GPS',
              value: '${entry.latitude!.toStringAsFixed(4)}°, '
                  '${entry.longitude!.toStringAsFixed(4)}°',
              isDark: isDark,
              useMono: true,
            ),
          ],

          // Address
          if (hasAddress) ...[
            AppSpacing.verticalSm,
            _MetadataRow(
              icon: Icons.location_on,
              label: 'Location',
              value: entry.address!,
              isDark: isDark,
            ),
          ],

          // Compass heading
          if (hasCompass) ...[
            AppSpacing.verticalSm,
            _MetadataRow(
              icon: Icons.explore,
              label: 'Heading',
              value: '${entry.compassHeading!.toStringAsFixed(0)}°',
              isDark: isDark,
              useMono: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.useMono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool useMono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
        ),
        AppSpacing.horizontalSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
              ),
              Text(
                value,
                style: useMono
                    ? AppTypography.mono.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      )
                    : AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
