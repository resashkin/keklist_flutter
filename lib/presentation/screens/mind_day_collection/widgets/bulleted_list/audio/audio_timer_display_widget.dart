import 'package:flutter/material.dart';

final class AudioTimerDisplayWidget extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const AudioTimerDisplayWidget({
    super.key,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatDuration(position),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
        Text(
          ' / ',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          duration == Duration.zero ? '--:--' : _formatDuration(duration),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
