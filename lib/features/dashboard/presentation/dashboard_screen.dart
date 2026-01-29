import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cards/report_card.dart';
import '../../../widgets/cards/stat_card.dart';
import '../../sync/domain/pending_upload.dart';
import '../../sync/providers/pending_uploads_provider.dart';
import '../providers/dashboard_provider.dart';

/// The main dashboard screen showing overview statistics.
///
/// This is the default landing screen after login. It displays
/// key stats like Reports This Week, Pending Uploads, Total Projects,
/// and Recent Activity.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isCaptureMenuOpen = false;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleCaptureMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isCaptureMenuOpen = !_isCaptureMenuOpen;
      if (_isCaptureMenuOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  void _closeCaptureMenu() {
    if (_isCaptureMenuOpen) {
      setState(() {
        _isCaptureMenuOpen = false;
        _fabAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsNotifierProvider);
    final recentReportsAsync = ref.watch(recentReportsNotifierProvider);
    final pendingUploadsAsync = ref.watch(pendingUploadsNotifierProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: AppTypography.headline1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      floatingActionButton: _buildQuickCaptureFAB(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          // Main content
          statsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
            data: (stats) => SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats grid - 2x2 layout
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        title: 'Reports This Week',
                        value: stats.reportsThisWeek.toString(),
                        icon: Icons.description_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/reports');
                        },
                      ),
                      StatCard(
                        title: 'Pending Uploads',
                        value: stats.pendingUploads.toString(),
                        icon: Icons.cloud_upload_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/sync');
                        },
                      ),
                      StatCard(
                        title: 'Total Projects',
                        value: stats.totalProjects.toString(),
                        icon: Icons.folder_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/projects');
                        },
                      ),
                      StatCard(
                        title: 'Recent Activity',
                        value: stats.recentActivity.toString(),
                        icon: Icons.history_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/activity');
                        },
                      ),
                    ],
                  ),
                  // Pending Uploads section
                  _buildPendingUploadsSection(
                    context,
                    pendingUploadsAsync,
                    isDark,
                  ),
                  // Recent Reports section
                  AppSpacing.verticalXl,
                  Text(
                    'Recent Reports',
                    style: AppTypography.headline2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                    ),
                  ),
                  AppSpacing.verticalMd,
                  // Recent reports list
                  recentReportsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Text('Error: $error'),
                    data: (reports) => Column(
                      children: reports
                          .take(5)
                          .map(
                            (report) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.listItemSpacing,
                              ),
                              child: ReportCard(
                                report: report,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/report-detail',
                                    arguments: report.id,
                                  );
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Capture menu overlay
          if (_isCaptureMenuOpen) _buildCaptureMenuOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildQuickCaptureFAB(bool isDark) {
    return FloatingActionButton(
      onPressed: _toggleCaptureMenu,
      backgroundColor: isDark ? AppColors.darkOrange : AppColors.orange500,
      elevation: 4,
      child: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _fabAnimationController.value * 0.785, // 45 degrees
            child: Icon(
              _isCaptureMenuOpen ? Icons.close : Icons.add,
              size: 28,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCaptureMenuOverlay(bool isDark) {
    return Positioned.fill(
      child: GestureDetector(
        key: const Key('capture_menu_barrier'),
        onTap: _closeCaptureMenu,
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Stack(
            children: [
              // Capture options positioned above the FAB
              Positioned(
                right: 16,
                bottom: 80, // Above FAB
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCaptureOption(
                      icon: Icons.edit_note,
                      label: 'Note',
                      isDark: isDark,
                      delay: 150,
                      onTap: () {
                        _closeCaptureMenu();
                        // Navigate to note capture
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCaptureOption(
                      icon: Icons.mic,
                      label: 'Audio',
                      isDark: isDark,
                      delay: 100,
                      onTap: () {
                        _closeCaptureMenu();
                        // Navigate to audio capture
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCaptureOption(
                      icon: Icons.videocam,
                      label: 'Video',
                      isDark: isDark,
                      delay: 50,
                      onTap: () {
                        _closeCaptureMenu();
                        // Navigate to video capture
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildCaptureOption(
                      icon: Icons.camera_alt,
                      label: 'Photo',
                      isDark: isDark,
                      delay: 0,
                      onTap: () {
                        _closeCaptureMenu();
                        // Navigate to photo capture
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureOption({
    required IconData icon,
    required String label,
    required bool isDark,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: AppTypography.body2.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.darkOrange : AppColors.orange500)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUploadsSection(
    BuildContext context,
    AsyncValue<List<PendingUpload>> pendingUploadsAsync,
    bool isDark,
  ) {
    return pendingUploadsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (uploads) {
        if (uploads.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeUpload = uploads
            .where(
              (u) => u.status == UploadStatus.uploading,
            )
            .toList();
        final hasActiveUpload = activeUpload.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.verticalXl,
            GestureDetector(
              key: const Key('pending_uploads_section'),
              onTap: () {
                Navigator.pushNamed(context, '/sync');
              },
              child: Container(
                padding: AppSpacing.cardInsets,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? null
                      : Border.all(color: AppColors.slate200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: isDark
                              ? AppColors.darkOrange
                              : AppColors.orange500,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Pending Uploads',
                            style: AppTypography.headline3.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.slate900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkAmberSubtle
                                : AppColors.amber50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${uploads.length}',
                            style: AppTypography.body2.copyWith(
                              color: isDark
                                  ? AppColors.darkAmber
                                  : AppColors.amber500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasActiveUpload) ...[
                      const SizedBox(height: AppSpacing.md),
                      LinearProgressIndicator(
                        value: activeUpload.first.progress,
                        backgroundColor:
                            isDark ? AppColors.darkBorder : AppColors.slate100,
                        valueColor: AlwaysStoppedAnimation(
                          isDark ? AppColors.darkOrange : AppColors.orange500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Uploading ${activeUpload.first.fileName}...',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
