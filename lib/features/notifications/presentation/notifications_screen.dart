import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/app_notification.dart';
import '../providers/notifications_provider.dart';

/// Screen displaying the list of notifications.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTypography.headline1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.read(notificationsNotifierProvider.notifier).markAllAsRead();
            },
            child: Text(
              'Mark all read',
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(notificationsNotifierProvider.notifier)
                        .markAsRead(notification.id);
                    // TODO: Navigate to relevant screen based on notification type
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No notifications',
            style: AppTypography.headline3.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You're all caught up!",
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDark ? AppColors.darkSurface : AppColors.white)
              : (isDark ? AppColors.darkOrangeSubtle : AppColors.orange50),
          borderRadius: BorderRadius.circular(12),
          border:
              isDark ? null : Border.all(color: AppColors.slate200, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.body1.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.slate900,
                            fontWeight: notification.isRead
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkOrange
                                : AppColors.orange500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.body,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.slate700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatTime(notification.createdAt),
                    style: AppTypography.caption.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = switch (notification.type) {
      NotificationType.syncComplete => Icons.cloud_done_outlined,
      NotificationType.pdfReady => Icons.picture_as_pdf_outlined,
      NotificationType.aiProcessingComplete => Icons.auto_awesome_outlined,
      NotificationType.mention => Icons.alternate_email_outlined,
      NotificationType.projectAssignment => Icons.folder_outlined,
      NotificationType.reportShared => Icons.share_outlined,
      NotificationType.uploadFailed => Icons.cloud_off_outlined,
      NotificationType.general => Icons.notifications_outlined,
    };

    final iconColor = switch (notification.type) {
      NotificationType.uploadFailed => AppColors.rose500,
      _ => isDark ? AppColors.darkOrange : AppColors.orange500,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
