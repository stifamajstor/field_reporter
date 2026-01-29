import 'package:flutter/material.dart';
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
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: statsAsync.when(
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
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
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
