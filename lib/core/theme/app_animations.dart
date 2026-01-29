import 'package:flutter/material.dart';

/// Field Reporter animation constants.
///
/// Defines curves and durations for consistent micro-interactions.
/// See DESIGN_GUIDELINES.md for usage guidelines.
class AppAnimations {
  AppAnimations._();

  // ============================================
  // CURVES
  // ============================================

  /// Standard ease-out curve for most animations
  static const Curve easeOut = Curves.easeOutCubic;

  /// Ease-in-out for symmetric animations
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Emphasized deceleration for important actions
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Emphasized acceleration for exits
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Standard deceleration
  static const Curve decelerate = Curves.decelerate;

  /// Linear curve for progress indicators
  static const Curve linear = Curves.linear;

  // ============================================
  // DURATIONS
  // ============================================

  /// Quick duration for immediate feedback (150ms)
  static const Duration quick = Duration(milliseconds: 150);

  /// Standard duration for most transitions (250ms)
  static const Duration standard = Duration(milliseconds: 250);

  /// Slow duration for complex animations (400ms)
  static const Duration slow = Duration(milliseconds: 400);

  /// Emphasis duration for important moments (500ms)
  static const Duration emphasis = Duration(milliseconds: 500);

  // ============================================
  // SPECIFIC DURATIONS
  // ============================================

  /// Button press animation (100ms)
  static const Duration buttonPress = Duration(milliseconds: 100);

  /// Button release animation (150ms)
  static const Duration buttonRelease = Duration(milliseconds: 150);

  /// Card enter animation (200ms)
  static const Duration cardEnter = Duration(milliseconds: 200);

  /// Card exit animation (150ms)
  static const Duration cardExit = Duration(milliseconds: 150);

  /// Page transition (300ms)
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// Fade in/out (200ms)
  static const Duration fadeIn = Duration(milliseconds: 200);

  /// Theme switch crossfade (300ms)
  static const Duration themeSwitch = Duration(milliseconds: 300);

  /// Capture flash overlay (30ms)
  static const Duration captureFlash = Duration(milliseconds: 30);

  /// Skeleton shimmer cycle (1500ms)
  static const Duration shimmerCycle = Duration(milliseconds: 1500);

  /// Stagger delay between items (50ms)
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // ============================================
  // ANIMATION VALUES
  // ============================================

  /// Button press scale (0.98)
  static const double buttonPressScale = 0.98;

  /// Count increment scale pulse (1.05)
  static const double countPulseScale = 1.05;

  /// Capture flash opacity (0.15)
  static const double captureFlashOpacity = 0.15;

  /// Disabled opacity (0.5)
  static const double disabledOpacity = 0.5;

  /// Overlay opacity for modals (0.5)
  static const double modalOverlayOpacity = 0.5;

  /// Camera overlay opacity (0.5)
  static const double cameraOverlayOpacity = 0.5;

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Creates a curved animation with standard ease-out.
  static Animation<double> curvedAnimation(
    AnimationController controller, {
    Curve curve = easeOut,
  }) {
    return CurvedAnimation(parent: controller, curve: curve);
  }

  /// Creates a scale animation for button press effect.
  static Animation<double> buttonScaleAnimation(
      AnimationController controller) {
    return Tween<double>(begin: 1.0, end: buttonPressScale).animate(
      CurvedAnimation(parent: controller, curve: easeOut),
    );
  }

  /// Creates a fade animation.
  static Animation<double> fadeAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: easeOut),
    );
  }

  /// Creates a slide-in-from-right animation.
  static Animation<Offset> slideInFromRight(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: easeOut));
  }

  /// Creates a slide-in-from-bottom animation.
  static Animation<Offset> slideInFromBottom(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: easeOut));
  }

  /// Creates a scale-up animation for pulse effects.
  static Animation<double> pulseAnimation(AnimationController controller) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: countPulseScale),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: countPulseScale, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: controller, curve: easeInOut));
  }

  /// Returns Duration.zero if reduce motion is enabled, otherwise the given duration.
  static Duration respectReduceMotion(Duration duration, bool reduceMotion) {
    return reduceMotion ? Duration.zero : duration;
  }
}
