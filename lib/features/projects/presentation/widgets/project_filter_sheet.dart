import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/project.dart';

/// Bottom sheet for filtering projects by status.
class ProjectFilterSheet extends StatefulWidget {
  const ProjectFilterSheet({
    super.key,
    required this.selectedStatuses,
    required this.onApply,
  });

  final Set<ProjectStatus> selectedStatuses;
  final void Function(Set<ProjectStatus> statuses) onApply;

  @override
  State<ProjectFilterSheet> createState() => _ProjectFilterSheetState();
}

class _ProjectFilterSheetState extends State<ProjectFilterSheet> {
  late Set<ProjectStatus> _selectedStatuses;

  @override
  void initState() {
    super.initState();
    _selectedStatuses = Set.from(widget.selectedStatuses);
  }

  void _toggleStatus(ProjectStatus status) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedStatuses.clear();
    });
  }

  void _applyFilters() {
    HapticFeedback.lightImpact();
    widget.onApply(_selectedStatuses);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Projects',
                    style: AppTypography.headline3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                    ),
                  ),
                  if (_selectedStatuses.isNotEmpty)
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text(
                        'Clear',
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkOrange
                              : AppColors.orange500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Status section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Status',
                style: AppTypography.body2.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.slate700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Status chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatusChip(
                    label: 'Active',
                    isSelected:
                        _selectedStatuses.contains(ProjectStatus.active),
                    onTap: () => _toggleStatus(ProjectStatus.active),
                  ),
                  _StatusChip(
                    label: 'Completed',
                    isSelected:
                        _selectedStatuses.contains(ProjectStatus.completed),
                    onTap: () => _toggleStatus(ProjectStatus.completed),
                  ),
                  _StatusChip(
                    label: 'Archived',
                    isSelected:
                        _selectedStatuses.contains(ProjectStatus.archived),
                    onTap: () => _toggleStatus(ProjectStatus.archived),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.darkOrange : AppColors.orange500,
                  foregroundColor:
                      isDark ? AppColors.darkBackground : AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply',
                  style: AppTypography.button.copyWith(
                    color: isDark ? AppColors.darkBackground : AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.quick,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkOrangeSubtle : AppColors.orange50)
              : (isDark ? AppColors.darkSurfaceHigh : AppColors.slate100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkOrange : AppColors.orange500)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body2.copyWith(
            color: isSelected
                ? (isDark ? AppColors.darkOrange : AppColors.orange500)
                : (isDark ? AppColors.darkTextSecondary : AppColors.slate700),
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
