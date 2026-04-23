import 'package:flutter/material.dart';

/// 10-bar discrete waveform driven by a 0..1 audio level stream from the
/// remote WebRTC stream. Discrete bars look better at low frame rates than
/// a continuous oscilloscope and are cheaper to repaint.
class AudioWaveform extends StatelessWidget {
  const AudioWaveform({super.key, required this.level, this.bars = 10});

  /// 0.0 (silent) .. 1.0 (peak).
  final double level;
  final int bars;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final lit = (level.clamp(0.0, 1.0) * bars).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(bars, (i) {
        final on = i < lit;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8 + i * 2.0,
          decoration: BoxDecoration(
            color: on ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
