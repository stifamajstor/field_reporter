import 'package:flutter/material.dart';
import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';

/// A shimmer skeleton loader that matches content dimensions.
///
/// Displays a pulsing shimmer animation to indicate loading state.
/// Per DESIGN_GUIDELINES.md, skeleton loaders should match exact
/// dimensions of content being loaded.
class SkeletonLoader extends StatefulWidget {
  /// The width of the skeleton. Must be positive.
  final double width;

  /// The height of the skeleton. Must be positive.
  final double height;

  /// Border radius for the skeleton shape.
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  })  : assert(width > 0, 'width must be positive'),
        assert(height > 0, 'height must be positive');

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.shimmerCycle,
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final baseColor = isDark ? AppColors.darkSurfaceHigh : AppColors.slate100;
    final highlightColor = isDark ? AppColors.darkBorder : AppColors.white;

    // If reduce motion is enabled, show static skeleton
    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton placeholder for stat cards.
///
/// Uses flexible layout to adapt to different card sizes.
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? null
            : Border.all(color: AppColors.slate200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon skeleton
          Flexible(
            child: SkeletonLoader(width: 24, height: 24, borderRadius: 6),
          ),
          SizedBox(height: 8),
          // Value skeleton
          Flexible(
            child: SkeletonLoader(width: 40, height: 20, borderRadius: 4),
          ),
          SizedBox(height: 4),
          // Title skeleton
          Flexible(
            child: SkeletonLoader(width: 60, height: 12, borderRadius: 4),
          ),
        ],
      ),
    );
  }
}

/// A skeleton placeholder for report cards.
class ReportCardSkeleton extends StatelessWidget {
  const ReportCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColors.slate200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail skeleton
          SkeletonLoader(width: 80, height: 80, borderRadius: 8),
          SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 150, height: 20, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonLoader(width: 100, height: 14, borderRadius: 4),
                SizedBox(height: 4),
                SkeletonLoader(width: 60, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton for the dashboard stats grid.
class DashboardStatsSkeleton extends StatelessWidget {
  const DashboardStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getResponsiveColumnCount(constraints.maxWidth);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: _getAspectRatio(crossAxisCount),
          children: const [
            StatCardSkeleton(),
            StatCardSkeleton(),
            StatCardSkeleton(),
            StatCardSkeleton(),
          ],
        );
      },
    );
  }

  int _getResponsiveColumnCount(double width) {
    if (width >= 700) {
      return 4;
    } else if (width >= 500) {
      return 3;
    }
    return 2;
  }

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
}

/// A skeleton for the recent reports section.
class RecentReportsSkeleton extends StatelessWidget {
  final int count;

  const RecentReportsSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title skeleton
        const SkeletonLoader(width: 140, height: 24, borderRadius: 4),
        const SizedBox(height: 16),
        // Report card skeletons
        ...List.generate(
          count,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ReportCardSkeleton(),
          ),
        ),
      ],
    );
  }
}
