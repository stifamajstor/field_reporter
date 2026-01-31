import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A widget that displays an audio waveform visualization.
///
/// Used for both recording (live amplitude visualization) and
/// playback (static waveform with progress indicator).
class AudioWaveformWidget extends StatelessWidget {
  const AudioWaveformWidget({
    super.key,
    required this.amplitudes,
    this.isRecording = false,
    this.progress = 0.0,
    this.activeColor,
    this.inactiveColor,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.minBarHeight = 4.0,
  });

  /// List of amplitude values (0.0 to 1.0).
  final List<double> amplitudes;

  /// Whether the waveform is in recording mode (animated).
  final bool isRecording;

  /// Playback progress (0.0 to 1.0).
  final double progress;

  /// Color for active (played/recording) bars.
  final Color? activeColor;

  /// Color for inactive (unplayed) bars.
  final Color? inactiveColor;

  /// Width of each bar.
  final double barWidth;

  /// Spacing between bars.
  final double barSpacing;

  /// Minimum height for bars (when amplitude is 0).
  final double minBarHeight;

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppColors.orange500;
    final effectiveInactiveColor =
        inactiveColor ?? AppColors.slate700.withOpacity(0.5);

    // Generate default bars if no amplitudes provided
    final displayAmplitudes = amplitudes.isEmpty
        ? List.generate(30, (_) => 0.05) // Minimal flat line
        : amplitudes;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final barCount = displayAmplitudes.length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (index) {
            final amplitude = displayAmplitudes[index].clamp(0.0, 1.0);
            final barHeight =
                minBarHeight + (amplitude * (maxHeight - minBarHeight));

            // Determine if this bar is "active" (before progress point)
            final isActive = isRecording || (index / barCount) <= progress;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: barSpacing / 2),
              child: AnimatedContainer(
                duration: isRecording
                    ? const Duration(milliseconds: 50)
                    : const Duration(milliseconds: 150),
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color:
                      isActive ? effectiveActiveColor : effectiveInactiveColor,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
