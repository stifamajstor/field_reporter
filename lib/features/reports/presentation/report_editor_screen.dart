import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../services/audio_recorder_service.dart';
import '../../../services/barcode_scanner_service.dart';
import '../../../services/camera_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/pdf_generation_service.dart';
import '../../../services/share_service.dart';
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

  // State for AI summary
  bool _isGeneratingSummary = false;
  bool _isEditingSummary = false;
  final TextEditingController _summaryController = TextEditingController();

  // State for PDF generation
  bool _isGeneratingPdf = false;
  String? _generatedPdfPath;
  String? _pdfSuccessMessage;
  String? _pdfErrorMessage;

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

  // State for camera error handling
  bool _showCameraError = false;
  CameraException? _cameraException;
  VoidCallback? _retryCallback;

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
    _summaryController.dispose();
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

  Future<void> _generateSummary() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      final updatedReport = await ref
          .read(allReportsNotifierProvider.notifier)
          .generateSummary(_report.id);
      setState(() {
        _report = updatedReport;
        _isGeneratingSummary = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingSummary = false;
      });
    }
  }

  void _startEditingSummary() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditingSummary = true;
      _summaryController.text = _report.aiSummary ?? '';
    });
  }

  Future<void> _saveSummaryEdit() async {
    HapticFeedback.lightImpact();
    final newSummary = _summaryController.text.trim();
    final updatedReport = _report.copyWith(
      aiSummary: newSummary.isNotEmpty ? newSummary : null,
      updatedAt: DateTime.now(),
    );
    _report = updatedReport;
    await ref
        .read(allReportsNotifierProvider.notifier)
        .updateReport(updatedReport);
    setState(() {
      _isEditingSummary = false;
    });
  }

  Future<void> _queueSummaryForLater() async {
    HapticFeedback.lightImpact();
    await ref
        .read(allReportsNotifierProvider.notifier)
        .queueSummaryForLater(_report.id);
    setState(() {
      _report = _report.copyWith(aiSummaryQueued: true);
    });
  }

  Future<void> _generatePdf() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isGeneratingPdf = true;
      _pdfSuccessMessage = null;
      _pdfErrorMessage = null;
      _generatedPdfPath = null;
    });

    try {
      // Get entries for this report
      final entriesAsync = ref.read(entriesNotifierProvider).valueOrNull ?? [];
      final entries = entriesAsync
          .where((e) => e.reportId == _report.id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final pdfService = ref.read(pdfGenerationServiceProvider);
      final result = await pdfService.generatePdf(
        report: _report,
        entries: entries,
        includeQrCodes: true,
      );

      if (result.success && result.filePath != null) {
        setState(() {
          _isGeneratingPdf = false;
          _generatedPdfPath = result.filePath;
          _pdfSuccessMessage = 'PDF generated successfully';
          _pdfErrorMessage = null;
        });
      } else {
        setState(() {
          _isGeneratingPdf = false;
          _pdfErrorMessage = result.error ?? 'Failed to generate PDF';
          _pdfSuccessMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isGeneratingPdf = false;
        _pdfErrorMessage = 'Error generating PDF: ${e.toString()}';
        _pdfSuccessMessage = null;
      });
    }
  }

  void _dismissPdfError() {
    HapticFeedback.lightImpact();
    setState(() {
      _pdfErrorMessage = null;
    });
  }

  void _previewPdf() {
    HapticFeedback.lightImpact();
    // TODO: Implement PDF preview
  }

  Future<void> _sharePdf() async {
    if (_generatedPdfPath == null) return;

    HapticFeedback.lightImpact();

    final shareService = ref.read(shareServiceProvider);
    await shareService.shareFile(
      filePath: _generatedPdfPath!,
      mimeType: 'application/pdf',
      subject: _report.title,
    );
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

    try {
      // Open camera and capture photo
      await cameraService.openCamera();
      final photoPath = await cameraService.capturePhoto();

      if (photoPath != null) {
        setState(() {
          _capturedPhotoPath = photoPath;
          _showPhotoPreview = true;
        });
      }
    } on CameraException catch (e) {
      setState(() {
        _cameraException = e;
        _showCameraError = true;
        _retryCallback = _handlePhotoCapture;
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

  void _dismissCameraError() {
    HapticFeedback.lightImpact();
    setState(() {
      _showCameraError = false;
      _cameraException = null;
      _retryCallback = null;
    });
  }

  void _retryCameraOperation() {
    HapticFeedback.mediumImpact();
    final callback = _retryCallback;
    setState(() {
      _showCameraError = false;
      _cameraException = null;
      _retryCallback = null;
    });
    callback?.call();
  }

  Future<void> _handleVideoCapture() async {
    setState(() {
      _showEntryTypeOptions = false;
    });

    final cameraService = ref.read(cameraServiceProvider);

    try {
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
    } on CameraException catch (e) {
      setState(() {
        _cameraException = e;
        _showCameraError = true;
        _retryCallback = _handleVideoCapture;
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

  Future<void> _handleReorderEntries(int oldIndex, int newIndex) async {
    await ref
        .read(entriesNotifierProvider.notifier)
        .reorderEntries(_report.id, oldIndex, newIndex);
  }

  Future<void> _handleMarkComplete() async {
    HapticFeedback.lightImpact();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _MarkCompleteConfirmationDialog(
        isDark: context.isDarkMode,
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.lightImpact();
      // Update report status to complete
      final updatedReport = _report.copyWith(
        status: ReportStatus.complete,
        updatedAt: DateTime.now(),
      );
      _report = updatedReport;
      await ref
          .read(allReportsNotifierProvider.notifier)
          .updateReport(updatedReport);
      setState(() {});
    }
  }

  Future<void> _showDeleteReportDialog(
      BuildContext context, bool isDark) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteReportConfirmationDialog(
        isDark: isDark,
        entryCount: _report.entryCount,
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      await ref
          .read(allReportsNotifierProvider.notifier)
          .deleteReport(_report.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Returns true if the report is editable (not complete)
  bool get _isEditable => _report.status != ReportStatus.complete;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final entriesAsync = ref.watch(entriesNotifierProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    final isOffline = !connectivityService.isOnline;

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
          PopupMenuButton<String>(
            key: const Key('more_options_button'),
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteReportDialog(context, isDark);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: isDark ? AppColors.darkRose : AppColors.rose500,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Report',
                      style: AppTypography.body1.copyWith(
                        color: isDark ? AppColors.darkRose : AppColors.rose500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (isOffline)
            Container(
              key: const Key('offline_indicator'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: isDark ? AppColors.darkAmber : AppColors.amber500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Offline mode',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? AppColors.darkAmber : AppColors.amber500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
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
                    _StatusBadge(
                      status: _report.status,
                      isDark: isDark,
                      isGeneratingPdf: _isGeneratingPdf,
                    ),
                    AppSpacing.verticalMd,

                    // Report title field
                    _ReportTitleField(
                      isDark: isDark,
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      enabled: _isEditable,
                    ),
                    AppSpacing.verticalLg,

                    // Report notes field
                    _ReportNotesField(
                      isDark: isDark,
                      controller: _notesController,
                      focusNode: _notesFocusNode,
                      enabled: _isEditable,
                    ),
                    AppSpacing.verticalLg,

                    // AI Summary section
                    _AiSummarySection(
                      isDark: isDark,
                      report: _report,
                      isGenerating: _isGeneratingSummary,
                      isEditing: _isEditingSummary,
                      isOffline: isOffline,
                      summaryController: _summaryController,
                      onGenerateSummary: _generateSummary,
                      onStartEditing: _startEditingSummary,
                      onSaveEdit: _saveSummaryEdit,
                      onQueueForLater: _queueSummaryForLater,
                    ),
                    AppSpacing.verticalLg,

                    // PDF Generation section
                    _PdfGenerationSection(
                      isDark: isDark,
                      report: _report,
                      isGenerating: _isGeneratingPdf,
                      generatedPdfPath: _generatedPdfPath,
                      successMessage: _pdfSuccessMessage,
                      errorMessage: _pdfErrorMessage,
                      onGeneratePdf: _generatePdf,
                      onPreviewPdf: _previewPdf,
                      onSharePdf: _sharePdf,
                      onRetry: _generatePdf,
                      onDismissError: _dismissPdfError,
                    ),
                    AppSpacing.verticalLg,

                    // Mark Complete section (only for draft reports)
                    if (_report.status == ReportStatus.draft)
                      _MarkCompleteSection(
                        isDark: isDark,
                        onMarkComplete: _handleMarkComplete,
                      ),
                    if (_report.status == ReportStatus.draft)
                      AppSpacing.verticalLg,

                    // Entries section
                    _EntriesSection(
                      isDark: isDark,
                      entries: entries,
                      onAddEntry: _isEditable ? _showAddEntryOptions : null,
                      onDeleteEntry: _isEditable ? _handleDeleteEntry : null,
                      onReorder: _isEditable
                          ? (oldIndex, newIndex) =>
                              _handleReorderEntries(oldIndex, newIndex)
                          : null,
                    ),
                  ],
                ),

                // Entry type options overlay
                if (_showEntryTypeOptions)
                  _EntryTypeOptionsOverlay(
                    isDark: isDark,
                    onClose: () =>
                        setState(() => _showEntryTypeOptions = false),
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

                // Camera error overlay
                if (_showCameraError && _cameraException != null)
                  _CameraErrorOverlay(
                    isDark: isDark,
                    exception: _cameraException!,
                    onRetry: _retryCameraOperation,
                    onCancel: _dismissCameraError,
                  ),
              ],
            ),
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
    this.isGeneratingPdf = false,
  });

  final ReportStatus status;
  final bool isDark;
  final bool isGeneratingPdf;

  @override
  Widget build(BuildContext context) {
    // Show Processing badge when generating PDF
    final effectiveStatus = isGeneratingPdf ? ReportStatus.processing : status;

    final (backgroundColor, textColor, label) = switch (effectiveStatus) {
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
          key: const Key('report_status_badge'),
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
    this.enabled = true,
  });

  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

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
          enabled: enabled,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          style: AppTypography.body1.copyWith(
            color: enabled
                ? (isDark ? AppColors.darkTextPrimary : AppColors.slate900)
                : (isDark ? AppColors.darkTextMuted : AppColors.slate500),
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
    this.enabled = true,
  });

  final bool isDark;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

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
          enabled: enabled,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
          style: AppTypography.body1.copyWith(
            color: enabled
                ? (isDark ? AppColors.darkTextPrimary : AppColors.slate900)
                : (isDark ? AppColors.darkTextMuted : AppColors.slate500),
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
    this.onAddEntry,
    this.onDeleteEntry,
    this.onReorder,
  });

  final bool isDark;
  final List<Entry> entries;
  final VoidCallback? onAddEntry;
  final void Function(Entry)? onDeleteEntry;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  Widget build(BuildContext context) {
    final hasPendingSyncEntries = entries.any((e) => e.syncPending);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Entries',
                style: AppTypography.headline3.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                ),
              ),
            ),
            if (hasPendingSyncEntries)
              Container(
                key: const Key('pending_sync_indicator'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 14,
                      color: isDark ? AppColors.darkAmber : AppColors.amber500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pending sync',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? AppColors.darkAmber : AppColors.amber500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        AppSpacing.verticalSm,

        // Show entries if we have them - Timeline format
        if (entries.isNotEmpty) ...[
          Container(
            key: const Key('entries_timeline'),
            child: ReorderableListView.builder(
              key: const Key('entry_list'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              onReorder: onReorder != null
                  ? (oldIndex, newIndex) {
                      HapticFeedback.mediumImpact();
                      // ReorderableListView passes newIndex as if the item was already removed
                      // So we need to adjust it
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      onReorder!(oldIndex, newIndex);
                    }
                  : (_, __) {},
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final scale = Tween<double>(begin: 1.0, end: 1.05)
                        .animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ));
                    return Transform.scale(
                      scale: scale.value,
                      child: Material(
                        elevation: 4,
                        borderRadius: AppSpacing.borderRadiusLg,
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isLast = index == entries.length - 1;
                return Padding(
                  key: Key('reorderable_entry_$index'),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _TimelineEntryCard(
                    key: Key('entry_card_${entry.id}'),
                    entry: entry,
                    isDark: isDark,
                    showConnector: !isLast,
                    onDelete: onDeleteEntry != null
                        ? () => onDeleteEntry!(entry)
                        : null,
                  ),
                );
              },
            ),
          ),
          if (onAddEntry != null) ...[
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
          ],
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
                if (onAddEntry != null) ...[
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
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Timeline entry card with connector and timestamp
class _TimelineEntryCard extends StatefulWidget {
  const _TimelineEntryCard({
    super.key,
    required this.entry,
    required this.isDark,
    required this.showConnector,
    this.onDelete,
  });

  final Entry entry;
  final bool isDark;
  final bool showConnector;
  final VoidCallback? onDelete;

  @override
  State<_TimelineEntryCard> createState() => _TimelineEntryCardState();
}

class _TimelineEntryCardState extends State<_TimelineEntryCard> {
  double _dragExtent = 0;
  static const double _deleteThreshold = 80;

  IconData _getIconForType(EntryType type) {
    return switch (type) {
      EntryType.photo => Icons.camera_alt_outlined,
      EntryType.video => Icons.videocam_outlined,
      EntryType.audio => Icons.mic_outlined,
      EntryType.note => Icons.edit_note_outlined,
      EntryType.scan => Icons.qr_code_scanner_outlined,
    };
  }

  String _getIconKeyForType(EntryType type) {
    return switch (type) {
      EntryType.photo => 'timeline_icon_photo',
      EntryType.video => 'timeline_icon_video',
      EntryType.audio => 'timeline_icon_audio',
      EntryType.note => 'timeline_icon_note',
      EntryType.scan => 'timeline_icon_scan',
    };
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final timestamp = timeFormat.format(widget.entry.capturedAt);

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragExtent =
              (_dragExtent + details.delta.dx).clamp(-_deleteThreshold, 0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragExtent <= -_deleteThreshold * 0.5) {
          setState(() {
            _dragExtent = -_deleteThreshold;
          });
        } else {
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
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkRose : AppColors.rose500,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: GestureDetector(
                  key: Key('delete_button_${widget.entry.id}'),
                  onTap: widget.onDelete,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        color: AppColors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Delete',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Timeline entry content
          Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline column (icon, connector)
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      // Type icon in circle
                      Container(
                        key: Key(_getIconKeyForType(widget.entry.type)),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? AppColors.darkOrangeSubtle
                              : AppColors.orange50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark
                                ? AppColors.darkOrange
                                : AppColors.orange500,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getIconForType(widget.entry.type),
                          size: 18,
                          color: widget.isDark
                              ? AppColors.darkOrange
                              : AppColors.orange500,
                        ),
                      ),
                      // Connector line
                      if (widget.showConnector)
                        Container(
                          key: const Key('timeline_connector'),
                          width: 2,
                          height: 60,
                          color: widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.slate200,
                        ),
                    ],
                  ),
                ),
                // Entry card content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timestamp
                      Padding(
                        key: Key('timeline_timestamp_${widget.entry.id}'),
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          timestamp,
                          style: AppTypography.mono.copyWith(
                            color: widget.isDark
                                ? AppColors.darkTextMuted
                                : AppColors.slate400,
                          ),
                        ),
                      ),
                      // Entry card
                      EntryCard(
                        entry: widget.entry,
                      ),
                    ],
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
                  key: const Key('add_photo_button'),
                  icon: Icons.photo_camera,
                  label: 'Photo',
                  isDark: isDark,
                  onTap: onPhotoSelected,
                ),
                _EntryTypeOption(
                  key: const Key('add_video_button'),
                  icon: Icons.videocam,
                  label: 'Video',
                  isDark: isDark,
                  onTap: onVideoSelected,
                ),
                _EntryTypeOption(
                  key: const Key('add_voice_memo_button'),
                  icon: Icons.mic,
                  label: 'Voice Memo',
                  isDark: isDark,
                  onTap: onVoiceMemoSelected,
                ),
                _EntryTypeOption(
                  key: const Key('add_note_button'),
                  icon: Icons.note,
                  label: 'Note',
                  isDark: isDark,
                  onTap: onNoteSelected,
                ),
                _EntryTypeOption(
                  key: const Key('add_scan_button'),
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
    super.key,
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

class _AiSummarySection extends StatelessWidget {
  const _AiSummarySection({
    required this.isDark,
    required this.report,
    required this.isGenerating,
    required this.isEditing,
    required this.isOffline,
    required this.summaryController,
    required this.onGenerateSummary,
    required this.onStartEditing,
    required this.onSaveEdit,
    required this.onQueueForLater,
  });

  final bool isDark;
  final Report report;
  final bool isGenerating;
  final bool isEditing;
  final bool isOffline;
  final TextEditingController summaryController;
  final VoidCallback onGenerateSummary;
  final VoidCallback onStartEditing;
  final VoidCallback onSaveEdit;
  final VoidCallback onQueueForLater;

  @override
  Widget build(BuildContext context) {
    final hasSummary = report.aiSummary != null && report.aiSummary!.isNotEmpty;
    final isQueued = report.aiSummaryQueued;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AI Summary',
              style: AppTypography.headline3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
            if (isGenerating)
              SizedBox(
                key: const Key('summary_processing_indicator'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isDark ? AppColors.darkOrange : AppColors.orange500,
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.verticalSm,
        if (hasSummary) ...[
          if (isEditing)
            _SummaryEditField(
              isDark: isDark,
              controller: summaryController,
              onSave: onSaveEdit,
            )
          else
            GestureDetector(
              key: const Key('ai_summary_section'),
              onTap: onStartEditing,
              child: Container(
                width: double.infinity,
                padding: AppSpacing.cardInsets,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceHigh
                      : AppColors.emerald50.withOpacity(0.5),
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkEmerald
                        : AppColors.emerald500.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: isDark
                              ? AppColors.darkEmerald
                              : AppColors.emerald500,
                        ),
                        AppSpacing.horizontalXs,
                        Text(
                          'AI Generated',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkEmerald
                                : AppColors.emerald500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.slate400,
                        ),
                      ],
                    ),
                    AppSpacing.verticalSm,
                    Text(
                      report.aiSummary!,
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ] else if (isQueued) ...[
          // Summary is queued for later processing
          Container(
            key: const Key('ai_queued_message'),
            width: double.infinity,
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark
                    ? AppColors.darkAmber.withOpacity(0.3)
                    : AppColors.amber500.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 20,
                  color: isDark ? AppColors.darkAmber : AppColors.amber500,
                ),
                AppSpacing.horizontalSm,
                Expanded(
                  child: Text(
                    'AI summary will be generated when online',
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (isOffline) ...[
          // Offline - show unavailable message and queue option
          Container(
            key: const Key('ai_offline_message'),
            width: double.infinity,
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.slate200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 20,
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: Text(
                        'AI features require an internet connection',
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalMd,
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('queue_for_later_button'),
                    onPressed: onQueueForLater,
                    icon: Icon(
                      Icons.schedule,
                      color: isDark ? AppColors.darkAmber : AppColors.amber500,
                    ),
                    label: Text(
                      'Queue for Later',
                      style: AppTypography.button.copyWith(
                        color:
                            isDark ? AppColors.darkAmber : AppColors.amber500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      side: BorderSide(
                        color:
                            isDark ? AppColors.darkAmber : AppColors.amber500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Online - no summary yet - show generate button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('generate_summary_button'),
              onPressed: isGenerating ? null : onGenerateSummary,
              icon: Icon(
                Icons.auto_awesome,
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
              label: Text(
                'Generate Summary',
                style: AppTypography.button.copyWith(
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                side: BorderSide(
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryEditField extends StatelessWidget {
  const _SummaryEditField({
    required this.isDark,
    required this.controller,
    required this.onSave,
  });

  final bool isDark;
  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('ai_summary_text_field'),
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Edit AI summary...',
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
        AppSpacing.verticalSm,
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            key: const Key('ai_summary_save_button'),
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.darkOrange : AppColors.orange500,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ),
      ],
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

class _PdfGenerationSection extends StatelessWidget {
  const _PdfGenerationSection({
    required this.isDark,
    required this.report,
    required this.isGenerating,
    required this.generatedPdfPath,
    required this.successMessage,
    required this.onGeneratePdf,
    required this.onPreviewPdf,
    required this.onSharePdf,
    this.errorMessage,
    this.onRetry,
    this.onDismissError,
  });

  final bool isDark;
  final Report report;
  final bool isGenerating;
  final String? generatedPdfPath;
  final String? successMessage;
  final String? errorMessage;
  final VoidCallback onGeneratePdf;
  final VoidCallback onPreviewPdf;
  final VoidCallback onSharePdf;
  final VoidCallback? onRetry;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    // Only show for complete reports (or show disabled for draft)
    final isComplete = report.status == ReportStatus.complete;
    final hasPdf = generatedPdfPath != null;
    final hasError = errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PDF Export',
              style: AppTypography.headline3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
            if (isGenerating)
              SizedBox(
                key: const Key('pdf_processing_indicator'),
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isDark ? AppColors.darkOrange : AppColors.orange500,
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.verticalSm,

        // Error message with retry
        if (hasError) ...[
          Container(
            key: const Key('pdf_error_message'),
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkRoseSubtle : AppColors.rose50,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(
                color: isDark ? AppColors.darkRose : AppColors.rose500,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: isDark ? AppColors.darkRose : AppColors.rose500,
                    ),
                    AppSpacing.horizontalSm,
                    Text(
                      'PDF generation failed',
                      style: AppTypography.body2.copyWith(
                        color: isDark ? AppColors.darkRose : AppColors.rose500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSm,
                Text(
                  errorMessage!,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.slate700,
                  ),
                ),
                AppSpacing.verticalMd,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onDismissError,
                      child: Text(
                        'Dismiss',
                        style: AppTypography.button.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    ElevatedButton(
                      key: const Key('pdf_retry_button'),
                      onPressed: onRetry,
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
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.verticalMd,
        ],

        // Success message
        if (successMessage != null && hasPdf && !hasError) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkEmeraldSubtle : AppColors.emerald50,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(
                color: isDark
                    ? AppColors.darkEmerald
                    : AppColors.emerald500.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: isDark ? AppColors.darkEmerald : AppColors.emerald500,
                ),
                AppSpacing.horizontalSm,
                Expanded(
                  child: Text(
                    successMessage!,
                    style: AppTypography.body2.copyWith(
                      color:
                          isDark ? AppColors.darkEmerald : AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.verticalMd,
        ],

        // PDF preview/share buttons (after successful generation)
        if (hasPdf) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('pdf_preview_button'),
                  onPressed: onPreviewPdf,
                  icon: Icon(
                    Icons.visibility,
                    color: isDark ? AppColors.darkOrange : AppColors.orange500,
                  ),
                  label: Text(
                    'Preview',
                    style: AppTypography.button.copyWith(
                      color:
                          isDark ? AppColors.darkOrange : AppColors.orange500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkOrange : AppColors.orange500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('pdf_share_button'),
                  onPressed: onSharePdf,
                  icon: const Icon(Icons.share, color: AppColors.white),
                  label: Text(
                    'Share',
                    style:
                        AppTypography.button.copyWith(color: AppColors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkOrange : AppColors.orange500,
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
          AppSpacing.verticalMd,
        ],

        // Generate PDF button (hide when showing error with retry)
        if (!hasError)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('generate_pdf_button'),
              onPressed: isComplete && !isGenerating ? onGeneratePdf : null,
              icon: Icon(
                Icons.picture_as_pdf,
                color: isComplete ? AppColors.white : AppColors.slate400,
              ),
              label: Text(
                hasPdf ? 'Regenerate PDF' : 'Generate PDF',
                style: AppTypography.button.copyWith(
                  color: isComplete ? AppColors.white : AppColors.slate400,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isComplete
                    ? (isDark ? AppColors.darkOrange : AppColors.orange500)
                    : (isDark ? AppColors.darkSurfaceHigh : AppColors.slate100),
                disabledBackgroundColor:
                    isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // Help text for draft reports
        if (!isComplete && !hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Mark report as complete to generate PDF',
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
            ),
          ),
      ],
    );
  }
}

class _MarkCompleteSection extends StatelessWidget {
  const _MarkCompleteSection({
    required this.isDark,
    required this.onMarkComplete,
  });

  final bool isDark;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Report Status',
            style: AppTypography.headline3.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            'Mark this report as complete when you have finished adding all entries and are ready to finalize it.',
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
            ),
          ),
          AppSpacing.verticalMd,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onMarkComplete,
              icon: Icon(
                Icons.check_circle_outline,
                color: isDark ? AppColors.darkEmerald : AppColors.emerald500,
              ),
              label: Text(
                'Mark Complete',
                style: AppTypography.button.copyWith(
                  color: isDark ? AppColors.darkEmerald : AppColors.emerald500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkEmeraldSubtle : AppColors.emerald50,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkCompleteConfirmationDialog extends StatelessWidget {
  const _MarkCompleteConfirmationDialog({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Mark Report Complete?',
        style: AppTypography.headline3.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
        ),
      ),
      content: Text(
        'Once marked complete, you will not be able to add or modify entries. '
        'You can still generate PDFs and share the report.',
        style: AppTypography.body2.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.darkEmerald : AppColors.emerald500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Mark Complete',
            style: AppTypography.button.copyWith(
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeleteReportConfirmationDialog extends StatelessWidget {
  const _DeleteReportConfirmationDialog({
    required this.isDark,
    required this.entryCount,
  });

  final bool isDark;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final warningMessage = entryCount > 0
        ? 'This report contains $entryCount ${entryCount == 1 ? 'entry' : 'entries'}. '
            'This action will permanently delete the report and all its entries.'
        : 'This action will permanently delete this report.';

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurfaceHigh : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete Report?',
        style: AppTypography.headline3.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
        ),
      ),
      content: Text(
        warningMessage,
        style: AppTypography.body2.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkRose : AppColors.rose500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Delete',
            style: AppTypography.button.copyWith(
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Overlay displayed when camera capture fails.
class _CameraErrorOverlay extends StatelessWidget {
  const _CameraErrorOverlay({
    required this.isDark,
    required this.exception,
    required this.onRetry,
    required this.onCancel,
  });

  final bool isDark;
  final CameraException exception;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isPermissionError = exception.isPermissionError;
    final title = isPermissionError ? 'Permission Required' : 'Camera Error';
    final message = exception.message;
    final retryLabel = isPermissionError ? 'Check Permissions' : 'Retry';

    return Container(
      key: const Key('camera_error_overlay'),
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Container(
              padding: AppSpacing.cardInsets,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkRose : AppColors.rose500)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPermissionError
                          ? Icons.lock_outline
                          : Icons.camera_alt_outlined,
                      size: 32,
                      color: isDark ? AppColors.darkRose : AppColors.rose500,
                    ),
                  ),
                  AppSpacing.verticalLg,

                  // Title
                  Text(
                    title,
                    style: AppTypography.headline3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalSm,

                  // Message
                  Text(
                    message,
                    style: AppTypography.body1.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalXl,

                  // Action buttons
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.slate700,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.slate200,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      AppSpacing.horizontalMd,

                      // Retry button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkOrange
                                : AppColors.orange500,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(retryLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
