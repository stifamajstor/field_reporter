import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Placeholder screen for Reports tab.
class ReportsPlaceholderScreen extends StatelessWidget {
  const ReportsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reports',
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
          'Reports Screen',
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.slate500,
          ),
        ),
      ),
    );
  }
}
