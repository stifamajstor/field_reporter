import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../projects/domain/project.dart';
import '../../projects/providers/projects_provider.dart';
import '../domain/report.dart';

/// Screen for editing/creating a report.
class ReportEditorScreen extends ConsumerStatefulWidget {
  const ReportEditorScreen({
    super.key,
    this.projectId,
    this.reportId,
  });

  /// The project ID this report belongs to (for new reports).
  final String? projectId;

  /// The report ID to edit (null for new reports).
  final String? reportId;

  @override
  ConsumerState<ReportEditorScreen> createState() => _ReportEditorScreenState();
}

class _ReportEditorScreenState extends ConsumerState<ReportEditorScreen> {
  late Report _report;
  Project? _project;

  @override
  void initState() {
    super.initState();
    _initReport();
  }

  void _initReport() {
    // Create a new draft report
    _report = Report(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: widget.projectId ?? '',
      title: 'New Report',
      status: ReportStatus.draft,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);

    // Get project details
    _project = projectsAsync.valueOrNull
        ?.where((p) => p.id == widget.projectId)
        .firstOrNull;

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
          _ReportTitleField(isDark: isDark),
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
  const _ReportTitleField({required this.isDark});

  final bool isDark;

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
