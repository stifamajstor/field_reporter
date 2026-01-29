import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Placeholder screen for Capture tab.
class CapturePlaceholderScreen extends StatelessWidget {
  const CapturePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Capture',
          style: AppTypography.headline1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
        elevation: 0,
      ),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
      body: Center(
        child: Text(
          'Capture Screen',
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}
