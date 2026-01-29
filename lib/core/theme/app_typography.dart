import 'package:flutter/material.dart';

/// Field Reporter typography system.
///
/// Uses DM Sans for UI text and JetBrains Mono for technical data.
/// See DESIGN_GUIDELINES.md for usage guidelines.
class AppTypography {
  AppTypography._();

  /// Primary font family for all UI text.
  static const String fontFamily = 'DM Sans';

  /// Monospace font for coordinates, timestamps, and technical data.
  static const String monoFamily = 'JetBrains Mono';

  // ============================================
  // DISPLAY & HEADLINES
  // ============================================

  /// Display - Large screen titles (32/40)
  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25, // 40px line height
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
  );

  /// Headline 1 - Screen titles (28/36)
  static const headline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.29, // 36px line height
    fontWeight: FontWeight.w500,
    letterSpacing: -0.25,
  );

  /// Headline 2 - Section headers (24/32)
  static const headline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.33, // 32px line height
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  /// Headline 3 - Card titles (20/28)
  static const headline3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.4, // 28px line height
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // ============================================
  // BODY TEXT
  // ============================================

  /// Body Large - Emphasized body text (18/28)
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.56, // 28px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  /// Body 1 - Primary content (16/24)
  static const body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5, // 24px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  /// Body 2 - Secondary content (14/20)
  static const body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.43, // 20px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // ============================================
  // SMALL TEXT
  // ============================================

  /// Caption - Labels, hints (12/16)
  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.33, // 16px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  /// Overline - Small labels, tags (11/16)
  static const overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.45, // 16px line height
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ============================================
  // MONOSPACE
  // ============================================

  /// Monospace - Coordinates, timestamps, metadata (12/16)
  static const mono = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.33, // 16px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  /// Monospace Large - Prominent technical data (14/20)
  static const monoLarge = TextStyle(
    fontFamily: monoFamily,
    fontSize: 14,
    height: 1.43, // 20px line height
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );

  // ============================================
  // INTERACTIVE
  // ============================================

  /// Button text (15/18)
  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  /// Text button / link text (14/20)
  static const textButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.43,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Returns a text style with the given color applied.
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Returns display style with the given color.
  static TextStyle displayColored(Color color) => display.copyWith(color: color);

  /// Returns headline1 style with the given color.
  static TextStyle headline1Colored(Color color) =>
      headline1.copyWith(color: color);

  /// Returns headline2 style with the given color.
  static TextStyle headline2Colored(Color color) =>
      headline2.copyWith(color: color);

  /// Returns headline3 style with the given color.
  static TextStyle headline3Colored(Color color) =>
      headline3.copyWith(color: color);

  /// Returns body1 style with the given color.
  static TextStyle body1Colored(Color color) => body1.copyWith(color: color);

  /// Returns body2 style with the given color.
  static TextStyle body2Colored(Color color) => body2.copyWith(color: color);

  /// Returns caption style with the given color.
  static TextStyle captionColored(Color color) => caption.copyWith(color: color);

  /// Returns mono style with the given color.
  static TextStyle monoColored(Color color) => mono.copyWith(color: color);
}
