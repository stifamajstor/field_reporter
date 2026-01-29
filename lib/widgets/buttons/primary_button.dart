import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';

/// Primary action button with press animation and haptic feedback.
///
/// Follows the "Tetris completion" design philosophy with precise,
/// satisfying micro-interactions.
///
/// ```dart
/// PrimaryButton(
///   label: 'Capture Photo',
///   icon: Icons.camera_alt,
///   onPressed: () => capturePhoto(),
/// )
/// ```
class PrimaryButton extends StatefulWidget {
  /// Creates a primary button.
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
  });

  /// The button label text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Called when the button is pressed.
  /// If null, the button will be disabled.
  final VoidCallback? onPressed;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether the button should expand to fill available width.
  final bool isExpanded;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.buttonPress,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.buttonPressScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isEnabled) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isEnabled) {
      _controller.reverse();
      HapticFeedback.lightImpact();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final backgroundColor = isDark ? AppColors.darkOrange : AppColors.orange500;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppAnimations.quick,
          height: AppSpacing.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: _isEnabled
                ? backgroundColor
                : backgroundColor.withOpacity(AppAnimations.disabledOpacity),
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        isDark ? AppColors.darkBackground : AppColors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize:
                        widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.white,
                          size: AppSpacing.iconSizeSm,
                        ),
                        AppSpacing.horizontalSm,
                      ],
                      Text(
                        widget.label,
                        style: AppTypography.button.copyWith(
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary outlined button variant.
class SecondaryButton extends StatefulWidget {
  /// Creates a secondary outlined button.
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
  });

  /// The button label text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether the button should expand to fill available width.
  final bool isExpanded;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.buttonPress,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.buttonPressScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isEnabled) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isEnabled) {
      _controller.reverse();
      HapticFeedback.lightImpact();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final foregroundColor = isDark ? AppColors.darkTextPrimary : AppColors.slate700;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.slate200;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppAnimations.quick,
          height: AppSpacing.buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: _isEnabled
                  ? borderColor
                  : borderColor.withOpacity(AppAnimations.disabledOpacity),
              width: 1.5,
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(foregroundColor),
                    ),
                  )
                : Row(
                    mainAxisSize:
                        widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: _isEnabled
                              ? foregroundColor
                              : foregroundColor
                                  .withOpacity(AppAnimations.disabledOpacity),
                          size: AppSpacing.iconSizeSm,
                        ),
                        AppSpacing.horizontalSm,
                      ],
                      Text(
                        widget.label,
                        style: AppTypography.button.copyWith(
                          color: _isEnabled
                              ? foregroundColor
                              : foregroundColor
                                  .withOpacity(AppAnimations.disabledOpacity),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
