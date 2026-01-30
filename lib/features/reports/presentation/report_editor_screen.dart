import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);

    // Get project details using the report's projectId or widget.projectId
    final projectId = _report.projectId.isNotEmpty
        ? _report.projectId
        : widget.projectId ?? '';

    _project =
        projectsAsync.valueOrNull?.where((p) => p.id == projectId).firstOrNull;

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
      body: ListView(
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
          _EntriesSection(isDark: isDark),
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
  const _EntriesSection({required this.isDark});

  final bool isDark;

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
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
              ),
              AppSpacing.verticalMd,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Add entry (placeholder)
                  },
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
    );
  }
}
