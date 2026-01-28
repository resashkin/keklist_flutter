import 'package:flutter/material.dart';

final class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool hasError;
  final VoidCallback onPressed;
  final double iconSize;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.hasError,
    required this.onPressed,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: hasError ? null : onPressed,
      iconSize: iconSize,
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primary,
      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
    );
  }
}
