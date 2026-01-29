import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cards/report_card.dart';
import '../../../widgets/cards/stat_card.dart';
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
}
