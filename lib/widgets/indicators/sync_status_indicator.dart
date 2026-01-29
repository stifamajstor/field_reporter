import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/sync/domain/sync_status.dart';

/// A widget that displays the current sync status.
///
/// Shows different states:
/// - Synced: green checkmark with "Synced" text
/// - Pending: cloud icon with pending count badge
/// - Syncing: animated sync icon
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.onTap,
  });

  /// The current sync status.
  final SyncStatus status;

  /// Callback when the indicator is tapped.
  final VoidCallback? onTap;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.status is SyncStatusSyncing) {
      _animationController.repeat();
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTooltip() {
    return switch (widget.status) {
      SyncStatusSynced() => 'Sync status: All synced',
      SyncStatusPending(:final pendingCount) =>
        'Sync status: $pendingCount items pending',
      SyncStatusSyncing() => 'Sync status: Syncing...',
      SyncStatusError(:final message) => 'Sync status: Error - $message',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: _getTooltip(),
      child: InkWell(
        key: const Key('sync_status_indicator'),
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return switch (widget.status) {
      SyncStatusSynced() => _buildSyncedState(isDark),
      SyncStatusPending(:final pendingCount) =>
        _buildPendingState(isDark, pendingCount),
      SyncStatusSyncing() => _buildSyncingState(isDark),
      SyncStatusError() => _buildErrorState(isDark),
    };
  }

  Widget _buildSyncedState(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 20,
          color: isDark ? AppColors.darkEmerald : AppColors.emerald500,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Synced',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkEmerald : AppColors.emerald500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingState(bool isDark, int pendingCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 20,
          color: isDark ? AppColors.darkAmber : AppColors.amber500,
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          key: const Key('sync_pending_badge'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkAmberSubtle : AppColors.amber50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$pendingCount',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.darkAmber : AppColors.amber500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncingState(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          key: const Key('sync_animating_icon'),
          turns: _animationController,
          child: Icon(
            Icons.sync,
            size: 20,
            color: isDark ? AppColors.darkOrange : AppColors.orange500,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Syncing',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkOrange : AppColors.orange500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 20,
          color: isDark ? AppColors.darkRose : AppColors.rose500,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Error',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.darkRose : AppColors.rose500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
