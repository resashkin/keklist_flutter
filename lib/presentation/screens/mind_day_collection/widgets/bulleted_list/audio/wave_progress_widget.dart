import 'dart:math' as math;
import 'package:flutter/material.dart';

final class WaveProgressWidget extends StatelessWidget {
  const WaveProgressWidget({super.key, required this.progress, this.waveform, this.onSeek});

  final double progress;
  final List<double>? waveform;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final Color inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.25);
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final double effectiveProgress = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int computedCount = (constraints.maxWidth / 6).floor();
        final int barCount = computedCount <= 0 ? 8 : computedCount;
        final double barWidth = 4;
        const double minHeight = 6.0;
        const double maxHeight = 12.0;
        const double barRadius = 2.0;
        const double totalHeight = maxHeight * 2;

        List<double> downSampleWaveform(List<double> source, int targetCount) {
          if (source.isEmpty) {
            return List<double>.filled(targetCount, 0.0);
          }
          if (source.length == targetCount) {
            return List<double>.of(source, growable: false);
          }
          final List<double> result = List<double>.filled(targetCount, 0.0);
          final double window = source.length / targetCount;
          for (int i = 0; i < targetCount; i++) {
            final double start = i * window;
            final double end = start + window;
            double sum = 0;
            int count = 0;
            int sampleIndex = start.floor();
            final int endIndex = math.min(source.length, end.ceil());
            while (sampleIndex < endIndex) {
              sum += source[sampleIndex];
              sampleIndex++;
              count++;
            }
            if (count == 0) {
              final int fallbackIndex = math.min(source.length - 1, start.round());
              result[i] = source[fallbackIndex];
            } else {
              result[i] = sum / count;
            }
          }
          return result;
        }

        List<double> buildHeights(int count, double min, double max) {
          if (waveform == null || waveform!.isEmpty) {
            return List<double>.generate(count, (int index) {
              final double normalized = (index % 4) / 4;
              return min + ((max - min) * normalized);
            });
          }
          final List<double> samples = downSampleWaveform(waveform!, count);
          final double heightRange = max - min;
          final double peak = samples
              .map((double value) => value.isFinite ? value.abs() : 0.0)
              .fold<double>(0.0, (double acc, double value) => math.max(acc, value));
          final double scale = peak > 0 ? peak : 1.0;
          return samples
              .map((double value) {
                final double normalized = (value.isFinite ? value.abs() : 0.0) / scale;
                final double shaped = math.pow(normalized.clamp(0.0, 1.0), 1.35).toDouble();
                return min + heightRange * shaped;
              })
              .toList(growable: false);
        }

        final List<double> heights = buildHeights(barCount, minHeight, maxHeight);
        final double activeBarsDouble = effectiveProgress * barCount;
        final int fullActiveBars = activeBarsDouble.floor();
        final double partialBarFraction = activeBarsDouble - fullActiveBars;

        void handleSeek(double dx) {
          if (onSeek == null) {
            return;
          }
          final double width = constraints.maxWidth;
          if (!width.isFinite || width <= 0) {
            return;
          }
          final double relativeProgress = (dx / width).clamp(0.0, 1.0);
          onSeek!(relativeProgress);
        }

        return GestureDetector(
          //behavior: HitTestBehavior.translucent,
          onTapDown: onSeek == null ? null : (TapDownDetails details) => handleSeek(details.localPosition.dx),
          onHorizontalDragStart: onSeek == null
              ? null
              : (DragStartDetails details) => handleSeek(details.localPosition.dx),
          onHorizontalDragUpdate: onSeek == null
              ? null
              : (DragUpdateDetails details) => handleSeek(details.localPosition.dx),
          child: SizedBox(
            height: totalHeight,
            child: Row(
              crossAxisAlignment: .center,
              mainAxisAlignment: .spaceBetween,
              children: List<Widget>.generate(barCount, (int index) {
                Color barColor = inactiveColor;
                if (effectiveProgress >= 1.0 || index < fullActiveBars) {
                  barColor = activeColor;
                } else if (index == fullActiveBars && partialBarFraction > 0 && fullActiveBars < barCount) {
                  barColor = Color.lerp(inactiveColor, activeColor, partialBarFraction) ?? activeColor;
                }
                final double barHeight = heights[index];
                return Column(
                  mainAxisAlignment: .center,
                  children: [
                    Container(
                      width: barWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: .only(topLeft: .circular(barRadius), topRight: .circular(barRadius)),
                      ),
                    ),
                    Container(
                      width: barWidth,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: .only(bottomLeft: .circular(barRadius), bottomRight: .circular(barRadius)),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
