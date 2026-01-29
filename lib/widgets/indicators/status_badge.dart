import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Status type for semantic coloring.
enum StatusType {
  /// Success state - synced, complete, verified
  success,

  /// Warning state - pending, needs attention
  warning,

  /// Error state - failed, requires action
  error,

  /// Neutral state - draft, inactive
  neutral,

  /// Active/processing state
  active,
}

/// A small badge indicating status with semantic colors.
///
/// ```dart
/// StatusBadge(
///   label: 'Synced',
///   type: StatusType.success,
/// )
/// ```
class StatusBadge extends StatelessWidget {
  /// Creates a status badge.
  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.showDot = false,
  });

  /// The badge label text.
  final String label;

  /// The semantic status type.
  final StatusType type;

  /// Whether to show a status dot before the label.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final (backgroundColor, textColor) = _getColors(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.overline.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getColors(bool isDark) {
    return switch (type) {
      StatusType.success => (
          isDark ? AppColors.darkEmeraldSubtle : AppColors.emerald50,
          isDark ? AppColors.darkEmerald : AppColors.emerald500,
        ),
      StatusType.warning => (
          isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
          isDark ? AppColors.darkAmber : AppColors.amber500,
        ),
      StatusType.error => (
          isDark ? AppColors.darkRoseSubtle : AppColors.rose50,
          isDark ? AppColors.darkRose : AppColors.rose500,
        ),
      StatusType.active => (
          isDark ? AppColors.darkOrangeSubtle : AppColors.orange50,
          isDark ? AppColors.darkOrange : AppColors.orange500,
        ),
      StatusType.neutral => (
          isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
          isDark ? AppColors.darkTextSecondary : AppColors.slate700,
        ),
    };
  }
}

/// A small status indicator dot.
///
/// ```dart
/// StatusDot(type: StatusType.success)
/// ```
class StatusDot extends StatelessWidget {
  /// Creates a status dot.
  const StatusDot({
    super.key,
    required this.type,
    this.size = 8,
    this.animated = false,
  });

  /// The semantic status type.
  final StatusType type;

  /// The dot size in pixels.
  final double size;

  /// Whether to animate (pulse) the dot.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final color = _getColor(isDark);

    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

    if (!animated) return dot;

    return _PulsingDot(color: color, size: size);
  }

  Color _getColor(bool isDark) {
    return switch (type) {
      StatusType.success =>
        isDark ? AppColors.darkEmerald : AppColors.emerald500,
      StatusType.warning => isDark ? AppColors.darkAmber : AppColors.amber500,
      StatusType.error => isDark ? AppColors.darkRose : AppColors.rose500,
      StatusType.active => isDark ? AppColors.darkOrange : AppColors.orange500,
      StatusType.neutral =>
        isDark ? AppColors.darkTextMuted : AppColors.slate400,
    };
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Sync status indicator showing current sync state.
///
/// ```dart
/// SyncStatusIndicator(
///   status: SyncStatus.synced,
///   lastSyncTime: DateTime.now(),
/// )
/// ```
class SyncStatusIndicator extends StatelessWidget {
  /// Creates a sync status indicator.
  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.lastSyncTime,
    this.pendingCount,
  });

  /// The current sync status.
  final SyncStatus status;

  /// The time of the last successful sync.
  final DateTime? lastSyncTime;

  /// Number of pending items to sync.
  final int? pendingCount;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textColor = isDark ? AppColors.darkTextSecondary : AppColors.slate500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(isDark),
        AppSpacing.horizontalSm,
        Text(
          _buildLabel(),
          style: AppTypography.caption.copyWith(color: textColor),
        ),
      ],
    );
  }

  Widget _buildIcon(bool isDark) {
    return switch (status) {
      SyncStatus.synced => Icon(
          Icons.check_circle,
          size: 16,
          color: isDark ? AppColors.darkEmerald : AppColors.emerald500,
        ),
      SyncStatus.syncing => SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              isDark ? AppColors.darkOrange : AppColors.orange500,
            ),
          ),
        ),
      SyncStatus.pending => Icon(
          Icons.sync,
          size: 16,
          color: isDark ? AppColors.darkAmber : AppColors.amber500,
        ),
      SyncStatus.error => Icon(
          Icons.error_outline,
          size: 16,
          color: isDark ? AppColors.darkRose : AppColors.rose500,
        ),
      SyncStatus.offline => Icon(
          Icons.cloud_off,
          size: 16,
          color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
        ),
    };
  }

  String _buildLabel() {
    return switch (status) {
      SyncStatus.synced => lastSyncTime != null
          ? 'Synced at ${_formatTime(lastSyncTime!)}'
          : 'Synced',
      SyncStatus.syncing => 'Syncing...',
      SyncStatus.pending =>
        pendingCount != null ? '$pendingCount items pending' : 'Pending',
      SyncStatus.error => 'Sync failed',
      SyncStatus.offline => 'Offline',
    };
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Sync status states.
enum SyncStatus {
  /// All data is synced.
  synced,

  /// Currently syncing.
  syncing,

  /// Has pending items to sync.
  pending,

  /// Sync failed.
  error,

  /// Device is offline.
  offline,
}
