import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../buttons/primary_button.dart';

/// Empty state placeholder for screens with no data.
///
/// Displays a simple icon, title, description, and optional action button.
/// Follows the "Ready When You Are" pattern from the design system.
///
/// ```dart
/// EmptyState(
///   icon: Icons.description_outlined,
///   title: 'No reports yet',
///   description: 'Start by capturing your first photo, video, or note.',
///   actionLabel: 'Create Report',
///   onAction: () => createReport(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Creates an empty state widget.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  /// The icon to display.
  final IconData icon;

  /// The title text.
  final String title;

  /// Optional description text.
  final String? description;

  /// Optional action button label.
  final String? actionLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onAction;

  /// Optional icon for the action button.
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
              borderRadius: AppSpacing.borderRadiusLg,
            ),
            child: Icon(
              icon,
              size: 40,
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
            ),
          ),
          AppSpacing.verticalLg,

          // Title
          Text(
            title,
            style: AppTypography.headline3.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
            ),
            textAlign: TextAlign.center,
          ),

          // Description
          if (description != null) ...[
            AppSpacing.verticalSm,
            Text(
              description!,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // Action button
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.verticalXl,
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                isExpanded: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact empty state for use in lists or smaller areas.
///
/// ```dart
/// CompactEmptyState(
///   message: 'No entries in this report',
///   actionLabel: 'Add Entry',
///   onAction: () => addEntry(),
/// )
/// ```
class CompactEmptyState extends StatelessWidget {
  /// Creates a compact empty state.
  const CompactEmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// The message to display.
  final String message;

  /// Optional action label.
  final String? actionLabel;

  /// Called when action is tapped.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: AppSpacing.paddingMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            AppSpacing.verticalSm,
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state placeholder matching empty state layout.
///
/// Shows a loading indicator in place of content.
class LoadingState extends StatelessWidget {
  /// Creates a loading state.
  const LoadingState({
    super.key,
    this.message,
  });

  /// Optional loading message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppColors.darkOrange : AppColors.orange500,
              ),
            ),
          ),
          if (message != null) ...[
            AppSpacing.verticalMd,
            Text(
              message!,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state placeholder with retry option.
///
/// ```dart
/// ErrorState(
///   message: 'Failed to load reports',
///   onRetry: () => loadReports(),
/// )
/// ```
class ErrorState extends StatelessWidget {
  /// Creates an error state.
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// The error message to display.
  final String message;

  /// Called when retry is pressed.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkRoseSubtle : AppColors.rose50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 32,
              color: isDark ? AppColors.darkRose : AppColors.rose500,
            ),
          ),
          AppSpacing.verticalMd,
          Text(
            message,
            style: AppTypography.body1.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            AppSpacing.verticalMd,
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
