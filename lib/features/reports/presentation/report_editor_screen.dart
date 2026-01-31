import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../services/audio_recorder_service.dart';
import '../../../services/barcode_scanner_service.dart';
import '../../../services/camera_service.dart';
import '../../entries/domain/entry.dart';
import '../../entries/presentation/entry_card.dart';
import '../../entries/providers/entries_provider.dart';
import '../../projects/domain/project.dart';
import '../../projects/providers/projects_provider.dart';
import '../domain/report.dart';
import '../providers/reports_provider.dart';

/// Screen for editing/creating a report.
class ReportEditorScreen extends ConsumerStatefulWidget {
  const ReportEditorScreen({
    super.key,
    this.projectId,
    this.reportId,
    this.report,
  });

  /// The project ID this report belongs to (for new reports).
  final String? projectId;

  /// The report ID to edit (null for new reports).
  final String? reportId;

  /// The report to edit (if provided, uses this instead of creating new).
  final Report? report;

  @override
  ConsumerState<ReportEditorScreen> createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends ConsumerState<ReportEditorScreen> {
  late Report _report;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  Project? _project;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  // State for entry type selection
  bool _showEntryTypeOptions = false;

  // State for photo preview
  String? _capturedPhotoPath;
  bool _showPhotoPreview = false;

  // State for video preview
  String? _capturedVideoPath;
  String? _capturedVideoThumbnailPath;
  int? _capturedVideoDuration;
  bool _showVideoPreview = false;

  // State for voice memo recording
  bool _showVoiceMemoRecorder = false;
  bool _isRecording = false;
  String? _recordedAudioPath;
  int? _recordedAudioDuration;
  int _recordingSeconds = 0;

  // State for note entry
  bool _showNoteEditor = false;
  final TextEditingController _noteContentController = TextEditingController();

  // State for scan entry
  bool _showScanOverlay = false;
  ScanResult? _scanResult;

  @override
  void initState() {
    super.initState();
    _initReport();
    _titleController = TextEditingController(text: _report.title);
    _notesController = TextEditingController(text: _report.notes ?? '');

    _titleFocusNode.addListener(_onTitleFocusChange);
    _notesFocusNode.addListener(_onNotesFocusChange);
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _notesFocusNode.removeListener(_onNotesFocusChange);
    _titleFocusNode.dispose();
    _notesFocusNode.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus) {
      _autoSave();
    }
  }

  void _onNotesFocusChange() {
    if (!_notesFocusNode.hasFocus) {
      _autoSave();
    }
  }

  void _autoSave() {
    final newTitle = _titleController.text.trim();
    final newNotes = _notesController.text.trim();

    if (newTitle != _report.title || newNotes != (_report.notes ?? '')) {
      final updatedReport = _report.copyWith(
        title: newTitle.isNotEmpty ? newTitle : _report.title,
        notes: newNotes.isNotEmpty ? newNotes : null,
        updatedAt: DateTime.now(),
      );
      _report = updatedReport;
      ref.read(allReportsNotifierProvider.notifier).updateReport(updatedReport);
    }
  }

  void _initReport() {
    if (widget.report != null) {
      // Use provided report
      _report = widget.report!;
    } else {
      // Create a new draft report with auto-generated title
      final today = DateFormat('MMM d, yyyy').format(DateTime.now());
      _report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: widget.projectId ?? '',
        title: 'Report - $today',
        status: ReportStatus.draft,
        createdAt: DateTime.now(),
      );
    }
  }

  void _showAddEntryOptions() {
    HapticFeedback.lightImpact();
    setState(() {
      _showEntryTypeOptions = true;
    });
  }

  Future<void> _handlePhotoCapture() async {
    setState(() {
      _showEntryTypeOptions = false;
    });

    final cameraService = ref.read(cameraServiceProvider);

    // Open camera and capture photo
    await cameraService.openCamera();
    final photoPath = await cameraService.capturePhoto();

    if (photoPath != null) {
      setState(() {
        _capturedPhotoPath = photoPath;
        _showPhotoPreview = true;
      });
    }
  }

  Future<void> _confirmPhotoEntry() async {
    if (_capturedPhotoPath == null) return;

    HapticFeedback.lightImpact();

    // Get current entries to determine sort order
    final entriesNotifier = ref.read(entriesNotifierProvider.notifier);
    final currentEntries = ref.read(entriesNotifierProvider).valueOrNull ?? [];
    final reportEntries =
        currentEntries.where((e) => e.reportId == _report.id).toList();

    // Create the entry
    final entry = Entry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportId: _report.id,
      type: EntryType.photo,
      mediaPath: _capturedPhotoPath,
      sortOrder: reportEntries.length,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await entriesNotifier.addEntry(entry);

    // Update report entry count
    final updatedReport = _report.copyWith(
      entryCount: _report.entryCount + 1,
      updatedAt: DateTime.now(),
    );
    _report = updatedReport;
    ref.read(allReportsNotifierProvider.notifier).updateReport(updatedReport);

    setState(() {
      _capturedPhotoPath = null;
      _showPhotoPreview = false;
    });
  }

  void _cancelPhotoPreview() {
    HapticFeedback.lightImpact();
    setState(() {
      _capturedPhotoPath = null;
      _showPhotoPreview = false;
    });
  }

  Future<void> _handleVideoCapture() async {
    setState(() {
      _showEntryTypeOptions = false;
    });

    final cameraService = ref.read(cameraServiceProvider);

    // Open camera in video mode and start recording
    await cameraService.openCameraForVideo();
    await cameraService.startRecording();
    final result = await cameraService.stopRecording();

    if (result != null) {
      setState(() {
        _capturedVideoPath = result.path;
        _capturedVideoThumbnailPath = result.thumbnailPath;
        _capturedVideoDuration = result.durationSeconds;
        _showVideoPreview = true;
      });
    }
  }

  Future<void> _confirmVideoEntry() async {
    if (_capturedVideoPath == null) return;

    HapticFeedback.lightImpact();

    // Get current entries to determine sort order
    final entriesNotifier = ref.read(entriesNotifierProvider.notifier);
    final currentEntries = ref.read(entriesNotifierProvider).valueOrNull ?? [];
    final reportEntries =
        currentEntries.where((e) => e.reportId == _report.id).toList();

    // Create the entry
    final entry = Entry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportId: _report.id,
      type: EntryType.video,
      mediaPath: _capturedVideoPath,
      thumbnailPath: _capturedVideoThumbnailPath,
      durationSeconds: _capturedVideoDuration,
      sortOrder: reportEntries.length,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await entriesNotifier.addEntry(entry);

    // Update report entry count
    final updatedReport = _report.copyWith(
      entryCount: _report.entryCount + 1,
      updatedAt: DateTime.now(),
    );
    _report = updatedReport;
    ref.read(allReportsNotifierProvider.notifier).updateReport(updatedReport);

    setState(() {
      _capturedVideoPath = null;
      _capturedVideoThumbnailPath = null;
      _capturedVideoDuration = null;
      _showVideoPreview = false;
    });
  }

  void _cancelVideoPreview() {
    HapticFeedback.lightImpact();
    setState(() {
      _capturedVideoPath = null;
      _capturedVideoThumbnailPath = null;
      _capturedVideoDuration = null;
      _showVideoPreview = false;
    });
  }

  void _handleVoiceMemoCapture() {
    setState(() {
      _showEntryTypeOptions = false;
      _showVoiceMemoRecorder = true;
      _isRecording = false;
      _recordedAudioPath = null;
      _recordedAudioDuration = null;
      _recordingSeconds = 0;
    });
  }

  Future<void> _startVoiceRecording() async {
    HapticFeedback.lightImpact();
    final audioRecorderService = ref.read(audioRecorderServiceProvider);
    await audioRecorderService.startRecording();
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
  }

  Future<void> _stopVoiceRecording() async {
    HapticFeedback.lightImpact();
    final audioRecorderService = ref.read(audioRecorderServiceProvider);
    final result = await audioRecorderService.stopRecording();
    if (result != null) {
      setState(() {
        _isRecording = false;
        _recordedAudioPath = result.path;
        _recordedAudioDuration = result.durationSeconds;
      });
    }
  }

  Future<void> _playVoiceRecording() async {
    if (_recordedAudioPath == null) return;
    HapticFeedback.lightImpact();
    final audioRecorderService = ref.read(audioRecorderServiceProvider);
    await audioRecorderService.startPlayback(_recordedAudioPath!);
  }

  Future<void> _confirmVoiceMemoEntry() async {
    if (_recordedAudioPath == null) return;

    HapticFeedback.lightImpact();

    // Get current entries to determine sort order
    final entriesNotifier = ref.read(entriesNotifierProvider.notifier);
    final currentEntries = ref.read(entriesNotifierProvider).valueOrNull ?? [];
    final reportEntries =
        currentEntries.where((e) => e.reportId == _report.id).toList();

    // Create the entry
    final entry = Entry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportId: _report.id,
      type: EntryType.audio,
      mediaPath: _recordedAudioPath,
      durationSeconds: _recordedAudioDuration,
      sortOrder: reportEntries.length,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await entriesNotifier.addEntry(entry);

    // Update report entry count
    final updatedReport = _report.copyWith(
      entryCount: _report.entryCount + 1,
      updatedAt: DateTime.now(),
    );
    _report = updatedReport;
    ref.read(allReportsNotifierProvider.notifier).updateReport(updatedReport);

    setState(() {
      _showVoiceMemoRecorder = false;
      _recordedAudioPath = null;
      _recordedAudioDuration = null;
      _isRecording = false;
      _recordingSeconds = 0;
    });
  }

  void _cancelVoiceMemoRecording() {
    HapticFeedback.lightImpact();
    setState(() {
      _showVoiceMemoRecorder = false;
      _recordedAudioPath = null;
      _recordedAudioDuration = null;
      _isRecording = false;
      _recordingSeconds = 0;
    });
  }

  void _handleNoteCapture() {
    setState(() {
      _showEntryTypeOptions = false;
      _showNoteEditor = true;
      _noteContentController.clear();
    });
  }

  Future<void> _confirmNoteEntry() async {
    final noteText = _noteContentController.text.trim();
    if (noteText.isEmpty) return;

    HapticFeedback.lightImpact();

    // Get current entries to determine sort order
    final entriesNotifier = ref.read(entriesNotifierProvider.notifier);
    final currentEntries = ref.read(entriesNotifierProvider).valueOrNull ?? [];
    final reportEntries =
        currentEntries.where((e) => e.reportId == _report.id).toList();

    // Create the entry
    final entry = Entry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportId: _report.id,
      type: EntryType.note,
      content: noteText,
      sortOrder: reportEntries.length,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await entriesNotifier.addEntry(entry);

    // Update report entry count
    final updatedReport = _report.copyWith(
      entryCount: _report.entryCount + 1,
      updatedAt: DateTime.now(),
    );
    _report = updatedReport;
    ref.read(allReportsNotifierProvider.notifier).updateReport(updatedReport);

    setState(() {
      _showNoteEditor = false;
      _noteContentController.clear();
    });
  }

  void _cancelNoteEditor() {
    HapticFeedback.lightImpact();
    setState(() {
      _showNoteEditor = false;
      _noteContentController.clear();
    });
  }

  void _handleScanCapture() {
    setState(() {
      _showEntryTypeOptions = false;
      _showScanOverlay = true;
      _scanResult = null;
    });

    // Start scanning
    _startScanning();
  }

  Future<void> _startScanning() async {
    final scannerService = ref.read(barcodeScannerServiceProvider);
    final result = await scannerService.scan();
    if (result != null && mounted) {
      setState(() {
        _scanResult = result;
      });
    }
  }

  Future<void> _confirmScanEntry() async {
    if (_scanResult == null) return;

    HapticFeedback.lightImpact();

    // Get current entries to determine sort order
    final entriesNotifier = ref.read(entriesNotifierProvider.notifier);
    final currentEntries = ref.read(entriesNotifierProvider).valueOrNull ?? [];
    final reportEntries =
        currentEntries.where((e) => e.reportId == _report.id).toList();

    // Create the entry
    final entry = Entry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reportId: _report.id,
      type: EntryType.scan,
      content: _scanResult!.data,
      sortOrder: reportEntries.length,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await entriesNotifier.addEntry(entry);

    // Update report entry count
    final updatedReport = _report.copyWith(
      entryCount: _report.entryCount + 1,
      updatedAt: DateTime.now(),
    );
    _report = updatedReport;
    ref.read(allReportsNotifierProvider.notifier).updateReport(updatedReport);

    setState(() {
      _showScanOverlay = false;
      _scanResult = null;
    });
  }

  void _cancelScanOverlay() {
    HapticFeedback.lightImpact();
    setState(() {
      _showScanOverlay = false;
      _scanResult = null;
    });
  }

  Future<void> _handleDeleteEntry(Entry entry) async {
    HapticFeedback.mediumImpact();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(
        isDark: context.isDarkMode,
      ),
    );

    if (confirmed == true && mounted) {
      // Delete the entry
      await ref.read(entriesNotifierProvider.notifier).deleteEntry(entry.id);

      // Update report entry count
      final updatedReport = _report.copyWith(
        entryCount: _report.entryCount - 1,
        updatedAt: DateTime.now(),
      );
      _report = updatedReport;
      ref.read(allReportsNotifierProvider.notifier).updateReport(updatedReport);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final entriesAsync = ref.watch(entriesNotifierProvider);

    // Get project details using the report's projectId or widget.projectId
    final projectId = _report.projectId.isNotEmpty
        ? _report.projectId
        : widget.projectId ?? '';

    _project =
        projectsAsync.valueOrNull?.where((p) => p.id == projectId).firstOrNull;

    // Get entries for this report
    final entries = entriesAsync.valueOrNull
            ?.where((e) => e.reportId == _report.id)
            .toList() ??
        [];
    entries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Editor'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // Save report (placeholder)
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: AppTypography.button.copyWith(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Project info section
              if (_project != null) ...[
                _ProjectInfoCard(project: _project!, isDark: isDark),
                AppSpacing.verticalMd,
              ],

              // Status indicator
              _StatusBadge(status: _report.status, isDark: isDark),
              AppSpacing.verticalMd,

              // Report title field
              _ReportTitleField(
                isDark: isDark,
                controller: _titleController,
                focusNode: _titleFocusNode,
              ),
              AppSpacing.verticalLg,

              // Report notes field
              _ReportNotesField(
                isDark: isDark,
                controller: _notesController,
                focusNode: _notesFocusNode,
              ),
              AppSpacing.verticalLg,

              // Entries section
              _EntriesSection(
                isDark: isDark,
                entries: entries,
                onAddEntry: _showAddEntryOptions,
                onDeleteEntry: _handleDeleteEntry,
              ),
            ],
          ),

          // Entry type options overlay
          if (_showEntryTypeOptions)
            _EntryTypeOptionsOverlay(
              isDark: isDark,
              onClose: () => setState(() => _showEntryTypeOptions = false),
              onPhotoSelected: _handlePhotoCapture,
              onVideoSelected: _handleVideoCapture,
              onVoiceMemoSelected: _handleVoiceMemoCapture,
              onNoteSelected: _handleNoteCapture,
              onScanSelected: _handleScanCapture,
            ),

          // Photo preview overlay
          if (_showPhotoPreview && _capturedPhotoPath != null)
            _PhotoPreviewOverlay(
              isDark: isDark,
              photoPath: _capturedPhotoPath!,
              onConfirm: _confirmPhotoEntry,
              onCancel: _cancelPhotoPreview,
            ),

          // Video preview overlay
          if (_showVideoPreview && _capturedVideoPath != null)
            _VideoPreviewOverlay(
              isDark: isDark,
              videoPath: _capturedVideoPath!,
              durationSeconds: _capturedVideoDuration ?? 0,
              onConfirm: _confirmVideoEntry,
              onCancel: _cancelVideoPreview,
            ),

          // Voice memo recorder overlay
          if (_showVoiceMemoRecorder)
            _VoiceMemoRecorderOverlay(
              isDark: isDark,
              isRecording: _isRecording,
              recordedAudioPath: _recordedAudioPath,
              recordedDuration: _recordedAudioDuration ?? 0,
              recordingSeconds: _recordingSeconds,
              onStartRecording: _startVoiceRecording,
              onStopRecording: _stopVoiceRecording,
              onPlayRecording: _playVoiceRecording,
              onConfirm: _confirmVoiceMemoEntry,
              onCancel: _cancelVoiceMemoRecording,
            ),

          // Note editor overlay
          if (_showNoteEditor)
            _NoteEditorOverlay(
              isDark: isDark,
              controller: _noteContentController,
              onConfirm: _confirmNoteEntry,
              onCancel: _cancelNoteEditor,
            ),

          // Scan overlay
          if (_showScanOverlay)
            _ScanOverlay(
              isDark: isDark,
              scanResult: _scanResult,
              onConfirm: _confirmScanEntry,
              onCancel: _cancelScanOverlay,
            ),
        ],
      ),
    );
  }
}

class _ProjectInfoCard extends StatelessWidget {
  const _ProjectInfoCard({
    required this.project,
    required this.isDark,
  });

  final Project project;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: AppSpacing.borderRadiusLg,
        border: isDark ? null : Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
          AppSpacing.horizontalSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project',
                  style: AppTypography.caption.copyWith(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                ),
                Text(
                  project.name,
                  style: AppTypography.body1.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.isDark,
  });

  final ReportStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor, label) = switch (status) {
      ReportStatus.draft => (
          isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
          isDark ? AppColors.darkTextSecondary : AppColors.slate700,
          'Draft',
        ),
      ReportStatus.processing => (
          isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
          isDark ? AppColors.darkAmber : AppColors.amber500,
          'Processing',
        ),
      ReportStatus.complete => (
          isDark ? AppColors.darkEmeraldSubtle : AppColors.emerald50,
          isDark ? AppColors.darkEmerald : AppColors.emerald500,
          'Complete',
        ),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Text(
            label,
            style: AppTypography.overline.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}

class _ReportTitleField extends StatelessWidget {
  const _ReportTitleField({
    required this.isDark,
    required this.controller,
    required this.focusNode,
  });

  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Title',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
        ),
        AppSpacing.verticalXs,
        TextField(
          key: const Key('report_title_field'),
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Enter report title',
            hintStyle: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.slate100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
      ],
    );
  }
}

class _ReportNotesField extends StatelessWidget {
  const _ReportNotesField({
    required this.isDark,
    required this.controller,
    required this.focusNode,
  });

  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
        ),
        AppSpacing.verticalXs,
        TextField(
          key: const Key('report_notes_field'),
          controller: controller,
          focusNode: focusNode,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add notes or description...',
            hintStyle: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.slate100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
      ],
    );
  }
}

class _EntriesSection extends StatelessWidget {
  const _EntriesSection({
    required this.isDark,
    required this.entries,
    required this.onAddEntry,
    required this.onDeleteEntry,
  });

  final bool isDark;
  final List<Entry> entries;
  final VoidCallback onAddEntry;
  final void Function(Entry) onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entries',
          style: AppTypography.headline3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        AppSpacing.verticalSm,

        // Show entries if we have them
        if (entries.isNotEmpty) ...[
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SwipeableEntryCard(
                key: Key('entry_card_${entry.id}'),
                entry: entry,
                isDark: isDark,
                onDelete: () => onDeleteEntry(entry),
              ),
            ),
          ),
          AppSpacing.verticalSm,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkOrange : AppColors.orange500,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          // Empty state with Add Entry button
          Container(
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: AppSpacing.borderRadiusLg,
              border: isDark ? null : Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 48,
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
                AppSpacing.verticalSm,
                Text(
                  'No entries yet',
                  style: AppTypography.body2.copyWith(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                ),
                AppSpacing.verticalMd,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkOrange : AppColors.orange500,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SwipeableEntryCard extends StatefulWidget {
  const _SwipeableEntryCard({
    super.key,
    required this.entry,
    required this.isDark,
    required this.onDelete,
  });

  final Entry entry;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  State<_SwipeableEntryCard> createState() => _SwipeableEntryCardState();
}

class _SwipeableEntryCardState extends State<_SwipeableEntryCard> {
  double _dragExtent = 0;
  static const double _deleteThreshold = 80;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent =
              (_dragExtent + details.delta.dx).clamp(-_deleteThreshold, 0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragExtent <= -_deleteThreshold * 0.5) {
          // Keep the delete button visible
          setState(() {
            _dragExtent = -_deleteThreshold;
          });
        } else {
          // Snap back
          setState(() {
            _dragExtent = 0;
          });
        }
      },
      child: Stack(
        children: [
          // Delete button background
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkRose : AppColors.rose500,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: IconButton(
                key: Key('delete_button_${widget.entry.id}'),
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          // Entry card
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: EntryCard(entry: widget.entry),
          ),
        ],
      ),
    );
  }
}

class _EntryTypeOptionsOverlay extends StatelessWidget {
  const _EntryTypeOptionsOverlay({
    required this.isDark,
    required this.onClose,
    required this.onPhotoSelected,
    required this.onVideoSelected,
    required this.onVoiceMemoSelected,
    required this.onNoteSelected,
    required this.onScanSelected,
  });

  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onPhotoSelected;
  final VoidCallback onVideoSelected;
  final VoidCallback onVoiceMemoSelected;
  final VoidCallback onNoteSelected;
  final VoidCallback onScanSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: AppSpacing.screenPadding,
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Entry',
                  style: AppTypography.headline3.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalMd,
                _EntryTypeOption(
                  icon: Icons.photo_camera,
                  label: 'Photo',
                  isDark: isDark,
                  onTap: onPhotoSelected,
                ),
                _EntryTypeOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  isDark: isDark,
                  onTap: onVideoSelected,
                ),
                _EntryTypeOption(
                  icon: Icons.mic,
                  label: 'Voice Memo',
                  isDark: isDark,
                  onTap: onVoiceMemoSelected,
                ),
                _EntryTypeOption(
                  icon: Icons.note,
                  label: 'Note',
                  isDark: isDark,
                  onTap: onNoteSelected,
                ),
                _EntryTypeOption(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan',
                  isDark: isDark,
                  onTap: onScanSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryTypeOption extends StatelessWidget {
  const _EntryTypeOption({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? AppColors.darkOrange : AppColors.orange500,
            ),
            AppSpacing.horizontalMd,
            Text(
              label,
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreviewOverlay extends StatelessWidget {
  const _PhotoPreviewOverlay({
    required this.isDark,
    required this.photoPath,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool isDark;
  final String photoPath;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Retake',
                      style: AppTypography.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Photo Preview',
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 60), // Balance the layout
                ],
              ),
            ),

            // Photo preview
            Expanded(
              child: Container(
                margin: AppSpacing.screenPadding,
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: const Center(
                  child: Icon(
                    Icons.photo,
                    size: 100,
                    color: AppColors.slate400,
                  ),
                ),
              ),
            ),

            // Bottom bar with confirm
            Padding(
              padding: AppSpacing.screenPadding,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange500,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Use Photo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreviewOverlay extends StatelessWidget {
  const _VideoPreviewOverlay({
    required this.isDark,
    required this.videoPath,
    required this.durationSeconds,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool isDark;
  final String videoPath;
  final int durationSeconds;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Retake',
                      style: AppTypography.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Video Preview',
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 60), // Balance the layout
                ],
              ),
            ),

            // Video preview
            Expanded(
              child: Container(
                margin: AppSpacing.screenPadding,
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.videocam,
                        size: 100,
                        color: AppColors.slate400,
                      ),
                    ),
                    // Play button overlay
                    Center(
                      child: Container(
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
                          _formatDuration(durationSeconds),
                          style: AppTypography.mono.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar with confirm
            Padding(
              padding: AppSpacing.screenPadding,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange500,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Use Video'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceMemoRecorderOverlay extends StatelessWidget {
  const _VoiceMemoRecorderOverlay({
    required this.isDark,
    required this.isRecording,
    required this.recordedAudioPath,
    required this.recordedDuration,
    required this.recordingSeconds,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPlayRecording,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool isDark;
  final bool isRecording;
  final String? recordedAudioPath;
  final int recordedDuration;
  final int recordingSeconds;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPlayRecording;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasRecording = recordedAudioPath != null;

    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: AppTypography.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Voice Memo',
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 60), // Balance the layout
                ],
              ),
            ),

            // Recording UI
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mic icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isRecording
                            ? AppColors.rose500.withOpacity(0.2)
                            : (hasRecording
                                ? AppColors.emerald500.withOpacity(0.2)
                                : AppColors.slate700.withOpacity(0.3)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 64,
                        color: isRecording
                            ? AppColors.rose500
                            : (hasRecording
                                ? AppColors.emerald500
                                : AppColors.white),
                      ),
                    ),
                    AppSpacing.verticalLg,

                    // Status text
                    if (isRecording)
                      Text(
                        'Recording...',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.rose500,
                        ),
                      )
                    else if (hasRecording)
                      Text(
                        'Recording Complete',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.emerald500,
                        ),
                      )
                    else
                      Text(
                        'Tap to Record',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.slate400,
                        ),
                      ),

                    AppSpacing.verticalSm,

                    // Timer
                    Text(
                      _formatDuration(
                          hasRecording ? recordedDuration : recordingSeconds),
                      style: AppTypography.monoLarge.copyWith(
                        color: AppColors.white,
                        fontSize: 32,
                      ),
                    ),

                    AppSpacing.verticalXl,

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!hasRecording) ...[
                          // Record/Stop button
                          if (isRecording)
                            _RecordingControlButton(
                              key: const Key('stop_button'),
                              icon: Icons.stop,
                              color: AppColors.rose500,
                              onTap: onStopRecording,
                            )
                          else
                            _RecordingControlButton(
                              key: const Key('record_button'),
                              icon: Icons.mic,
                              color: AppColors.orange500,
                              onTap: onStartRecording,
                            ),
                        ] else ...[
                          // Play button
                          _RecordingControlButton(
                            key: const Key('play_button'),
                            icon: Icons.play_arrow,
                            color: AppColors.emerald500,
                            onTap: onPlayRecording,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar with save
            if (hasRecording)
              Padding(
                padding: AppSpacing.screenPadding,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('voice_memo_save_button'),
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange500,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecordingControlButton extends StatelessWidget {
  const _RecordingControlButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 36,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _NoteEditorOverlay extends StatelessWidget {
  const _NoteEditorOverlay({
    required this.isDark,
    required this.controller,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool isDark;
  final TextEditingController controller;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: AppTypography.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Add Note',
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 60), // Balance the layout
                ],
              ),
            ),

            // Note text field
            Expanded(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: TextField(
                  key: const Key('note_text_field'),
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your note here...',
                    hintStyle: AppTypography.body1.copyWith(
                      color: AppColors.slate400,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDark ? AppColors.darkOrange : AppColors.orange500,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                  style: AppTypography.body1.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                  ),
                ),
              ),
            ),

            // Bottom bar with save
            Padding(
              padding: AppSpacing.screenPadding,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('note_save_button'),
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange500,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({
    required this.isDark,
    required this.scanResult,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool isDark;
  final ScanResult? scanResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('scan_overlay'),
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with cancel
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'Cancel',
                      style: AppTypography.button.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Text(
                    'Scan',
                    style: AppTypography.headline3.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 60), // Balance the layout
                ],
              ),
            ),

            // Scan content area
            Expanded(
              child: Center(
                child: scanResult == null
                    ? _buildScanningState()
                    : _buildResultState(),
              ),
            ),

            // Bottom bar with save (only show when result available)
            if (scanResult != null)
              Padding(
                padding: AppSpacing.screenPadding,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('scan_save_button'),
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange500,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Scanner frame indicator
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.orange500,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: AppColors.orange500,
            ),
          ),
        ),
        AppSpacing.verticalLg,
        Text(
          'Point at QR code or barcode',
          style: AppTypography.body1.copyWith(
            color: AppColors.white,
          ),
        ),
        AppSpacing.verticalSm,
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.orange500),
          ),
        ),
      ],
    );
  }

  Widget _buildResultState() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.emerald500.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: AppColors.emerald500,
            ),
          ),
          AppSpacing.verticalLg,

          // Format badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              scanResult!.formatDisplayName,
              style: AppTypography.caption.copyWith(
                color:
                    isDark ? AppColors.darkTextSecondary : AppColors.slate700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AppSpacing.verticalMd,

          // Scanned data
          Container(
            width: double.infinity,
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanned Data',
                  style: AppTypography.caption.copyWith(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                ),
                AppSpacing.verticalXs,
                Text(
                  scanResult!.data,
                  style: AppTypography.monoLarge.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
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

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('delete_confirmation_dialog'),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete Entry',
        style: AppTypography.headline3.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
        ),
      ),
      content: Text(
        'Are you sure you want to delete this entry?',
        style: AppTypography.body1.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_delete_button'),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop(false);
          },
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
            ),
          ),
        ),
        TextButton(
          key: const Key('confirm_delete_button'),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
          },
          child: Text(
            'Delete',
            style: AppTypography.button.copyWith(
              color: isDark ? AppColors.darkRose : AppColors.rose500,
            ),
          ),
        ),
      ],
    );
  }
}
