import 'package:flutter/material.dart';

/// Field Reporter spacing system based on 8px grid.
///
/// All spacing values are multiples of 8px for visual consistency.
/// See DESIGN_GUIDELINES.md for usage guidelines.
class AppSpacing {
  AppSpacing._();

  // ============================================
  // BASE UNIT
  // ============================================

  /// Base spacing unit (8px)
  static const double unit = 8.0;

  // ============================================
  // SPACING SCALE
  // ============================================

  /// Extra extra small spacing (2px) - 0.25 units
  static const double xxs = 2.0;

  /// Extra small spacing (4px) - 0.5 units
  static const double xs = 4.0;

  /// Small spacing (8px) - 1 unit
  static const double sm = 8.0;

  /// Medium spacing (16px) - 2 units
  static const double md = 16.0;

  /// Large spacing (24px) - 3 units
  static const double lg = 24.0;

  /// Extra large spacing (32px) - 4 units
  static const double xl = 32.0;

  /// Extra extra large spacing (48px) - 6 units
  static const double xxl = 48.0;

  /// Extra extra extra large spacing (64px) - 8 units
  static const double xxxl = 64.0;

  // ============================================
  // SCREEN LAYOUT
  // ============================================

  /// Horizontal screen margin (20px)
  static const double screenHorizontal = 20.0;

  /// Vertical screen margin (24px)
  static const double screenVertical = 24.0;

  /// Maximum content width for tablets (600px)
  static const double maxContentWidth = 600.0;

  // ============================================
  // COMPONENT SPACING
  // ============================================

  /// Card internal padding (16px)
  static const double cardPadding = 16.0;

  /// List item vertical spacing (12px)
  static const double listItemSpacing = 12.0;

  /// Section vertical spacing (32px)
  static const double sectionSpacing = 32.0;

  /// Icon-to-text gap (8px)
  static const double iconTextGap = 8.0;

  /// Input field internal padding (16px)
  static const double inputPadding = 16.0;

  // ============================================
  // BORDER RADIUS
  // ============================================

  /// Small radius for chips, badges (6px)
  static const double radiusSm = 6.0;

  /// Medium radius for inputs, small cards (8px)
  static const double radiusMd = 8.0;

  /// Large radius for cards, buttons (12px)
  static const double radiusLg = 12.0;

  /// Extra large radius for modals, sheets (16px)
  static const double radiusXl = 16.0;

  /// Full/circular radius
  static const double radiusFull = 999.0;

  // ============================================
  // EDGE INSETS
  // ============================================

  /// Standard screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  /// Horizontal-only screen padding (for lists)
  static const EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );

  /// Card internal padding
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);

  /// Small padding (8px all sides)
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);

  /// Medium padding (16px all sides)
  static const EdgeInsets paddingMd = EdgeInsets.all(md);

  /// Large padding (24px all sides)
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  /// Button internal padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Input field padding
  static const EdgeInsets inputInsets = EdgeInsets.symmetric(
    horizontal: inputPadding,
    vertical: inputPadding,
  );

  // ============================================
  // SIZED BOXES (for spacing in Column/Row)
  // ============================================

  /// Vertical gap - extra small (4px)
  static const SizedBox verticalXs = SizedBox(height: xs);

  /// Vertical gap - small (8px)
  static const SizedBox verticalSm = SizedBox(height: sm);

  /// Vertical gap - medium (16px)
  static const SizedBox verticalMd = SizedBox(height: md);

  /// Vertical gap - large (24px)
  static const SizedBox verticalLg = SizedBox(height: lg);

  /// Vertical gap - extra large (32px)
  static const SizedBox verticalXl = SizedBox(height: xl);

  /// Horizontal gap - extra small (4px)
  static const SizedBox horizontalXs = SizedBox(width: xs);

  /// Horizontal gap - small (8px)
  static const SizedBox horizontalSm = SizedBox(width: sm);

  /// Horizontal gap - medium (16px)
  static const SizedBox horizontalMd = SizedBox(width: md);

  /// Horizontal gap - large (24px)
  static const SizedBox horizontalLg = SizedBox(width: lg);

  /// Horizontal gap - extra large (32px)
  static const SizedBox horizontalXl = SizedBox(width: xl);

  // ============================================
  // BORDER RADIUS HELPERS
  // ============================================

  /// Small border radius
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);

  /// Medium border radius
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);

  /// Large border radius (standard for cards/buttons)
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);

  /// Extra large border radius
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // ============================================
  // SIZING
  // ============================================

  /// Minimum touch target size (48px)
  static const double touchTargetMin = 48.0;

  /// Standard icon size (24px)
  static const double iconSize = 24.0;

  /// Small icon size (20px)
  static const double iconSizeSm = 20.0;

  /// Large icon size (28px)
  static const double iconSizeLg = 28.0;

  /// Standard button height (52px)
  static const double buttonHeight = 52.0;

  /// Compact button height (44px)
  static const double buttonHeightCompact = 44.0;

  /// Bottom navigation height (64px + safe area)
  static const double bottomNavHeight = 64.0;

  /// App bar height (56px)
  static const double appBarHeight = 56.0;

  /// Thumbnail size - small (60px)
  static const double thumbnailSm = 60.0;

  /// Thumbnail size - medium (80px)
  static const double thumbnailMd = 80.0;

  /// Thumbnail size - large (120px)
  static const double thumbnailLg = 120.0;
}
