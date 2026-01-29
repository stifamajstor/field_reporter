import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/cards/report_card.dart';
import '../../../widgets/cards/animated_stat_card.dart';
import '../../../widgets/layout/empty_state.dart';
import '../../../widgets/indicators/offline_indicator.dart';
import '../../../widgets/indicators/stale_data_indicator.dart';
import '../../../widgets/indicators/sync_status_indicator.dart';
import '../../../services/connectivity_service.dart';
import '../../auth/domain/user.dart';
import '../../auth/providers/tenant_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../sync/domain/pending_upload.dart';
import '../../sync/providers/pending_uploads_provider.dart';
import '../../sync/providers/sync_status_provider.dart';
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
    with TickerProviderStateMixin {
  bool _isCaptureMenuOpen = false;
  late AnimationController _fabAnimationController;
  late AnimationController _fabVisibilityController;
  late ScrollController _scrollController;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabVisibilityController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 1.0, // Start fully visible
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final currentPosition = _scrollController.position.pixels;
    final delta = currentPosition - _lastScrollPosition;

    if (delta > 0 && currentPosition > 0) {
      // Scrolling down - hide FAB
      _fabVisibilityController.reverse();
    } else if (delta < 0) {
      // Scrolling up - show FAB
      _fabVisibilityController.forward();
    }

    _lastScrollPosition = currentPosition;
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _fabVisibilityController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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

  Future<void> _onRefresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(dashboardStatsNotifierProvider.notifier).refresh(),
      ref.read(recentReportsNotifierProvider.notifier).refresh(),
      ref.read(pendingUploadsNotifierProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsNotifierProvider);
    final statsNotifier = ref.watch(dashboardStatsNotifierProvider.notifier);
    final recentReportsAsync = ref.watch(recentReportsNotifierProvider);
    final pendingUploadsAsync = ref.watch(pendingUploadsNotifierProvider);
    final syncStatus = ref.watch(syncStatusNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final selectedTenant = ref.watch(selectedTenantProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    final isOnline = connectivityService.isOnline;
    final lastUpdated = statsNotifier.lastUpdated;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Dashboard',
          style: AppTypography.headline1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
        elevation: 0,
        actions: [
          if (!isOnline)
            const OfflineIndicator()
          else
            SyncStatusIndicator(
              status: syncStatus,
              onTap: () => Navigator.pushNamed(context, '/sync'),
            ),
          _buildNotificationBell(context, unreadCount, isDark),
          if (currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: _buildUserAvatar(currentUser, isDark),
            ),
        ],
      ),
      drawer:
          _buildNavigationDrawer(context, currentUser, selectedTenant, isDark),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      floatingActionButton: _buildQuickCaptureFAB(isDark),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: () => _onRefresh(ref),
            child: statsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
              data: (stats) {
                // Show empty state when no projects exist
                if (stats.totalProjects == 0) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          MediaQuery.of(context).padding.top -
                          100,
                      child: EmptyState(
                        icon: Icons.folder_open_outlined,
                        title: 'No projects yet',
                        description:
                            'Create your first project to start capturing reports.',
                        actionLabel: 'Create First Project',
                        actionIcon: Icons.add,
                        onAction: () {
                          Navigator.pushNamed(context, '/projects/create');
                        },
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User greeting and tenant context
                      _buildUserContextHeader(
                          currentUser, selectedTenant, isDark),
                      // Stale data indicator (only when offline)
                      if (!isOnline && lastUpdated != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        StaleDataIndicator(lastUpdated: lastUpdated),
                      ],
                      AppSpacing.verticalLg,
                      // Stats grid - responsive layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              _getResponsiveColumnCount(constraints.maxWidth);
                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: _getAspectRatio(crossAxisCount),
                            children: [
                              AnimatedStatCard(
                                title: 'Reports This Week',
                                value: stats.reportsThisWeek,
                                icon: Icons.description_outlined,
                                animationDelay: Duration.zero,
                                onTap: () {
                                  Navigator.pushNamed(context, '/reports');
                                },
                              ),
                              AnimatedStatCard(
                                title: 'Pending Uploads',
                                value: stats.pendingUploads,
                                icon: Icons.cloud_upload_outlined,
                                animationDelay:
                                    const Duration(milliseconds: 50),
                                onTap: () {
                                  Navigator.pushNamed(context, '/sync');
                                },
                              ),
                              AnimatedStatCard(
                                title: 'Total Projects',
                                value: stats.totalProjects,
                                icon: Icons.folder_outlined,
                                animationDelay:
                                    const Duration(milliseconds: 100),
                                onTap: () {
                                  Navigator.pushNamed(context, '/projects');
                                },
                              ),
                              AnimatedStatCard(
                                title: 'Recent Activity',
                                value: stats.recentActivity,
                                icon: Icons.history_outlined,
                                animationDelay:
                                    const Duration(milliseconds: 150),
                                onTap: () {
                                  Navigator.pushNamed(context, '/activity');
                                },
                              ),
                            ],
                          );
                        },
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
                );
              },
            ),
          ),
          // Capture menu overlay
          if (_isCaptureMenuOpen) _buildCaptureMenuOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildQuickCaptureFAB(bool isDark) {
    return AnimatedBuilder(
      animation: _fabVisibilityController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _fabVisibilityController.value)),
          child: child,
        );
      },
      child: FloatingActionButton(
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
                        Navigator.pushNamed(context, '/camera');
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

  Widget _buildUserContextHeader(
    User? user,
    dynamic tenant,
    bool isDark,
  ) {
    final greeting = _getGreeting();
    final firstName = user?.firstName ?? 'User';
    final tenantName = tenant?.name as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting with user's first name
        Text(
          '$greeting, $firstName',
          style: AppTypography.headline2.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        if (tenantName != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            tenantName,
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationBell(
      BuildContext context, int unreadCount, bool isDark) {
    final tooltipText = unreadCount > 0
        ? 'Notifications: $unreadCount unread'
        : 'Notifications';

    return Tooltip(
      message: tooltipText,
      child: IconButton(
        key: const Key('notification_bell_icon'),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  key: const Key('notification_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rose500,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: AppTypography.overline.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: () => Navigator.pushNamed(context, '/notifications'),
      ),
    );
  }

  Widget _buildUserAvatar(User user, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkOrange : AppColors.orange500,
        shape: BoxShape.circle,
      ),
      child: user.avatarUrl != null
          ? ClipOval(
              child: Image.network(
                user.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials(user),
              ),
            )
          : _buildInitials(user),
    );
  }

  Widget _buildInitials(User user) {
    return Center(
      child: Text(
        user.initials,
        style: AppTypography.body2.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Returns the number of columns based on available width.
  ///
  /// Breakpoints:
  /// - < 500px: 2 columns (phone portrait)
  /// - 500-700px: 3 columns (tablet portrait/phone landscape)
  /// - >= 700px: 4 columns (tablet landscape/desktop)
  int _getResponsiveColumnCount(double width) {
    if (width >= 700) {
      return 4;
    } else if (width >= 500) {
      return 3;
    }
    return 2;
  }

  /// Returns the aspect ratio for stat cards based on column count.
  ///
  /// More columns = wider cards need lower aspect ratio to maintain height.
  double _getAspectRatio(int columnCount) {
    switch (columnCount) {
      case 4:
        return 1.0;
      case 3:
        return 1.1;
      default:
        return 1.2;
    }
  }

  Widget _buildNavigationDrawer(
    BuildContext context,
    User? user,
    dynamic tenant,
    bool isDark,
  ) {
    final tenantName = tenant?.name as String?;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      child: Column(
        children: [
          // User profile header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSpacing.lg,
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.slate100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                if (user != null) ...[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkOrange : AppColors.orange500,
                      shape: BoxShape.circle,
                    ),
                    child: user.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildDrawerInitials(user),
                            ),
                          )
                        : _buildDrawerInitials(user),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // User full name
                  Text(
                    user.fullName,
                    style: AppTypography.headline3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // User email
                  Text(
                    user.email,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate500,
                    ),
                  ),
                ],
                // Tenant name
                if (tenantName != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    tenantName,
                    style: AppTypography.caption.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Navigation menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isDark: isDark,
                  isSelected: true,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/projects');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.description_outlined,
                  label: 'Reports',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/reports');
                  },
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.photo_library_outlined,
                  label: 'Media',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/media');
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final selectedColor = isDark ? AppColors.darkOrange : AppColors.orange500;
    final defaultColor =
        isDark ? AppColors.darkTextPrimary : AppColors.slate900;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? selectedColor : defaultColor,
      ),
      title: Text(
        label,
        style: AppTypography.body1.copyWith(
          color: isSelected ? selectedColor : defaultColor,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor:
          isDark ? AppColors.darkOrangeSubtle : AppColors.orange50,
      onTap: onTap,
    );
  }

  Widget _buildDrawerInitials(User user) {
    return Center(
      child: Text(
        user.initials,
        style: AppTypography.headline3.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
