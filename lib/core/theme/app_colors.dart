import 'package:flutter/material.dart';

/// Field Reporter color palette.
///
/// Follows the "Warm Field Professional" design system with full
/// light and dark mode support. See DESIGN_GUIDELINES.md for usage.
class AppColors {
  AppColors._();

  // ============================================
  // LIGHT MODE COLORS
  // ============================================

  // Core neutrals - inspired by professional field equipment
  static const slate900 = Color(0xFF0F172A); // Primary text, headers
  static const slate700 = Color(0xFF334155); // Secondary text
  static const slate500 = Color(0xFF64748B); // Tertiary text
  static const slate400 = Color(0xFF94A3B8); // Muted text, placeholders
  static const slate200 = Color(0xFFE2E8F0); // Borders, dividers
  static const slate100 = Color(0xFFF1F5F9); // Subtle backgrounds
  static const white = Color(0xFFFFFFFF); // Cards, primary surfaces

  // Primary accent: Warm Orange - energetic yet controlled, action-oriented
  static const orange500 = Color(0xFFF97316); // Primary actions, FAB
  static const orange600 = Color(0xFFEA580C); // Pressed/hover states
  static const orange400 = Color(0xFFFB923C); // Lighter accent
  static const orange50 = Color(0xFFFFF7ED); // Subtle highlights
  static const orange100 = Color(0xFFFFEDD5); // Active backgrounds

  // Semantic colors
  static const emerald500 = Color(0xFF10B981); // Success, synced, complete
  static const emerald50 = Color(0xFFECFDF5); // Success background
  static const amber500 = Color(0xFFF59E0B); // Warning, pending
  static const amber50 = Color(0xFFFFFBEB); // Warning background
  static const rose500 = Color(0xFFF43F5E); // Error, failed
  static const rose50 = Color(0xFFFFF1F2); // Error background

  // ============================================
  // DARK MODE COLORS
  // ============================================

  // Dark surfaces - true black OLED-friendly base
  static const darkBackground = Color(0xFF0A0A0A); // App background
  static const darkSurface = Color(0xFF141414); // Cards, elevated surfaces
  static const darkSurfaceHigh = Color(0xFF1F1F1F); // Dialogs, modals
  static const darkSurfaceHigher = Color(0xFF262626); // Tooltips, popovers
  static const darkBorder = Color(0xFF2D2D2D); // Subtle borders

  // Dark text
  static const darkTextPrimary = Color(0xFFF8FAFC); // Primary text
  static const darkTextSecondary = Color(0xFF94A3B8); // Secondary text
  static const darkTextMuted = Color(0xFF64748B); // Muted/disabled

  // Orange accent adapts for dark mode (slightly brighter for contrast)
  static const darkOrange = Color(0xFFFB923C); // Primary actions in dark
  static const darkOrangePressed = Color(0xFFF97316); // Pressed state
  static const darkOrangeSubtle = Color(0xFF2D1F0F); // Subtle orange backgrounds

  // Dark semantic colors (slightly desaturated for eye comfort)
  static const darkEmerald = Color(0xFF34D399); // Success in dark
  static const darkEmeraldSubtle = Color(0xFF0D2818); // Success background
  static const darkAmber = Color(0xFFFBBF24); // Warning in dark
  static const darkAmberSubtle = Color(0xFF2D2006); // Warning background
  static const darkRose = Color(0xFFFB7185); // Error in dark
  static const darkRoseSubtle = Color(0xFF2D0D12); // Error background

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Returns the appropriate primary text color for the given brightness.
  static Color textPrimary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextPrimary : slate900;
  }

  /// Returns the appropriate secondary text color for the given brightness.
  static Color textSecondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextSecondary : slate700;
  }

  /// Returns the appropriate muted text color for the given brightness.
  static Color textMuted(Brightness brightness) {
    return brightness == Brightness.dark ? darkTextMuted : slate400;
  }

  /// Returns the appropriate surface color for the given brightness.
  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : white;
  }

  /// Returns the appropriate background color for the given brightness.
  static Color background(Brightness brightness) {
    return brightness == Brightness.dark ? darkBackground : white;
  }

  /// Returns the appropriate border color for the given brightness.
  static Color border(Brightness brightness) {
    return brightness == Brightness.dark ? darkBorder : slate200;
  }

  /// Returns the appropriate primary accent color for the given brightness.
  static Color primary(Brightness brightness) {
    return brightness == Brightness.dark ? darkOrange : orange500;
  }

  /// Returns the appropriate pressed primary color for the given brightness.
  static Color primaryPressed(Brightness brightness) {
    return brightness == Brightness.dark ? darkOrangePressed : orange600;
  }

  /// Returns the appropriate success color for the given brightness.
  static Color success(Brightness brightness) {
    return brightness == Brightness.dark ? darkEmerald : emerald500;
  }

  /// Returns the appropriate success background for the given brightness.
  static Color successBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkEmeraldSubtle : emerald50;
  }

  /// Returns the appropriate warning color for the given brightness.
  static Color warning(Brightness brightness) {
    return brightness == Brightness.dark ? darkAmber : amber500;
  }

  /// Returns the appropriate warning background for the given brightness.
  static Color warningBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkAmberSubtle : amber50;
  }

  /// Returns the appropriate error color for the given brightness.
  static Color error(Brightness brightness) {
    return brightness == Brightness.dark ? darkRose : rose500;
  }

  /// Returns the appropriate error background for the given brightness.
  static Color errorBackground(Brightness brightness) {
    return brightness == Brightness.dark ? darkRoseSubtle : rose50;
  }
}
