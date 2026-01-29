import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// An animated stat card that displays a statistic with fade/slide entrance
/// and count-up number animation.
///
/// Used on the Dashboard to show overview statistics like
/// 'Reports This Week', 'Pending Uploads', etc. with smooth animations.
class AnimatedStatCard extends StatefulWidget {
  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.onTap,
    this.animate = true,
    this.animateCount = true,
    this.animationDelay = Duration.zero,
    this.fadeSlideAnimationDuration = const Duration(milliseconds: 300),
    this.countAnimationDuration = const Duration(milliseconds: 500),
  });

  /// The label for this statistic.
  final String title;

  /// The numeric value to display.
  final int value;

  /// Optional icon to display.
  final IconData? icon;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to animate the card on load.
  final bool animate;

  /// Whether to animate the count up.
  final bool animateCount;

  /// Delay before starting the animation (for staggered effect).
  final Duration animationDelay;

  /// Duration of the fade/slide animation.
  final Duration fadeSlideAnimationDuration;

  /// Duration of the count-up animation.
  final Duration countAnimationDuration;

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with TickerProviderStateMixin {
  late AnimationController _fadeSlideController;
  late AnimationController _countController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<int> _countAnimation;

  bool _animationsStarted = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Fade/slide animation controller
    _fadeSlideController = AnimationController(
      duration: widget.fadeSlideAnimationDuration,
      vsync: this,
    );

    // Count animation controller
    _countController = AnimationController(
      duration: widget.countAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeSlideController,
      curve: AppAnimations.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeSlideController,
      curve: AppAnimations.easeOut,
    ));

    _countAnimation = IntTween(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: AppAnimations.easeOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationsStarted) {
      _animationsStarted = true;
      _startAnimations();
    }
  }

  Future<void> _startAnimations() async {
    // Check for reduced motion preference
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (!widget.animate || reduceMotion) {
      // Skip animation - show final state immediately
      _fadeSlideController.value = 1.0;
      _countController.value = 1.0;
      return;
    }

    // Wait for the animation delay
    if (widget.animationDelay > Duration.zero) {
      await Future.delayed(widget.animationDelay);
    }

    // Check if still mounted after delay
    if (!mounted) return;

    // Start fade/slide animation
    _fadeSlideController.forward();

    // Start count animation after a brief delay
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    if (widget.animateCount) {
      _countController.forward();
    } else {
      _countController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update count animation if value changed
    if (oldWidget.value != widget.value) {
      _countAnimation = IntTween(
        begin: 0,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _countController,
        curve: AppAnimations.easeOut,
      ));

      if (widget.animateCount) {
        _countController.forward(from: 0);
      } else {
        _countController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _fadeSlideController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // If reduced motion, skip animations entirely
    if (reduceMotion) {
      return _buildCard(isDark, widget.value.toString());
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: _countAnimation,
          builder: (context, child) {
            return _buildCard(isDark, _countAnimation.value.toString());
          },
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, String displayValue) {
    return GestureDetector(
      onTap: widget.onTap != null
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      child: Container(
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          borderRadius: AppSpacing.borderRadiusLg,
          border:
              isDark ? null : Border.all(color: AppColors.slate200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: AppSpacing.iconSize,
                color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
              ),
              AppSpacing.verticalSm,
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  displayValue,
                  style: AppTypography.headline2.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                  ),
                ),
              ),
            ),
            AppSpacing.verticalXs,
            Flexible(
              child: Text(
                widget.title,
                style: AppTypography.caption.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.slate500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
