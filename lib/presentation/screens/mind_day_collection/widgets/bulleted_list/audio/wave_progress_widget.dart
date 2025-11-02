import 'package:flutter/material.dart';

final class WaveProgressWidget extends StatelessWidget {
  const WaveProgressWidget({
    super.key,
    required this.progress,
    this.onSeek,
  });

  final double progress;
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
        final List<double> heights = List<double>.generate(barCount, (int index) {
          final double normalized = (index % 4) / 4;
          return 10 + (14 * normalized);
        });
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

        /// TODO: ignore some any transitions outside this widget with tap down, make this GD to main and override elses
        /// * dont seek if playing was not started

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: onSeek == null ? null : (TapDownDetails details) => handleSeek(details.localPosition.dx),
          onHorizontalDragStart:
              onSeek == null ? null : (DragStartDetails details) => handleSeek(details.localPosition.dx),
          onHorizontalDragUpdate:
              onSeek == null ? null : (DragUpdateDetails details) => handleSeek(details.localPosition.dx),
          child: SizedBox(
            height: 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(barCount, (int index) {
                Color barColor = inactiveColor;

                if (effectiveProgress >= 1.0 || index < fullActiveBars) {
                  barColor = activeColor;
                } else if (index == fullActiveBars && partialBarFraction > 0 && fullActiveBars < barCount) {
                  barColor = Color.lerp(inactiveColor, activeColor, partialBarFraction) ?? activeColor;
                }

                return Container(
                  width: barWidth,
                  height: heights[index],
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
