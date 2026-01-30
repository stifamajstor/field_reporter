import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/project.dart';

/// A map view displaying project locations with markers.
class ProjectMapView extends StatefulWidget {
  const ProjectMapView({
    super.key,
    required this.projects,
    required this.onProjectTap,
  });

  /// The list of projects to display on the map.
  final List<Project> projects;

  /// Callback when a project is tapped (navigates to detail).
  final void Function(Project project) onProjectTap;

  @override
  State<ProjectMapView> createState() => _ProjectMapViewState();
}

class _ProjectMapViewState extends State<ProjectMapView> {
  String? _selectedProjectId;

  List<Project> get _projectsWithLocation => widget.projects
      .where((p) => p.latitude != null && p.longitude != null)
      .toList();

  void _onMarkerTap(Project project) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedProjectId = project.id;
    });
  }

  void _onPopupTap(Project project) {
    HapticFeedback.lightImpact();
    widget.onProjectTap(project);
  }

  void _dismissPopup() {
    setState(() {
      _selectedProjectId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    if (_projectsWithLocation.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
            ),
            AppSpacing.verticalMd,
            Text(
              'No project locations',
              style: AppTypography.headline3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
            AppSpacing.verticalSm,
            Text(
              'Add locations to your projects to see them on the map.',
              style: AppTypography.body2.copyWith(
                color:
                    isDark ? AppColors.darkTextSecondary : AppColors.slate700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _dismissPopup,
      child: Stack(
        children: [
          // Map background placeholder
          Container(
            color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
            child: Center(
              child: Icon(
                Icons.map_outlined,
                size: 100,
                color: isDark
                    ? AppColors.darkTextMuted.withOpacity(0.3)
                    : AppColors.slate200,
              ),
            ),
          ),

          // Project markers
          ..._projectsWithLocation.map((project) {
            return _buildMarker(project, isDark);
          }),

          // Selected project popup
          if (_selectedProjectId != null) _buildPopup(isDark),
        ],
      ),
    );
  }

  Widget _buildMarker(Project project, bool isDark) {
    // Calculate position based on project index
    // For a simple implementation, spread markers across the screen
    final index = _projectsWithLocation.indexOf(project);

    // Distribute markers in a grid-like pattern
    final row = index ~/ 2;
    final col = index % 2;
    final topPercent = 0.2 + (row * 0.25);
    final leftPercent = 0.2 + (col * 0.4);

    return Positioned(
      top: MediaQuery.of(context).size.height * topPercent,
      left: MediaQuery.of(context).size.width * leftPercent,
      child: GestureDetector(
        key: Key('project_marker_${project.id}'),
        onTap: () => _onMarkerTap(project),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _selectedProjectId == project.id
                ? (isDark ? AppColors.darkOrange : AppColors.orange500)
                : (isDark ? AppColors.darkSurface : AppColors.white),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.location_on,
            size: 32,
            color: _selectedProjectId == project.id
                ? AppColors.white
                : (isDark ? AppColors.darkOrange : AppColors.orange500),
          ),
        ),
      ),
    );
  }

  Widget _buildPopup(bool isDark) {
    final project = _projectsWithLocation.firstWhere(
      (p) => p.id == _selectedProjectId,
      orElse: () => _projectsWithLocation.first,
    );

    return Positioned(
      bottom: AppSpacing.xl,
      left: AppSpacing.screenHorizontal,
      right: AppSpacing.screenHorizontal,
      child: GestureDetector(
        key: Key('project_popup_${project.id}'),
        onTap: () => _onPopupTap(project),
        child: Container(
          padding: AppSpacing.cardInsets,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkOrangeSubtle : AppColors.orange50,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  Icons.location_on,
                  color: isDark ? AppColors.darkOrange : AppColors.orange500,
                ),
              ),
              AppSpacing.horizontalMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.name,
                      style: AppTypography.headline3.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.slate900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project.address != null) ...[
                      AppSpacing.verticalXs,
                      Text(
                        project.address!,
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
