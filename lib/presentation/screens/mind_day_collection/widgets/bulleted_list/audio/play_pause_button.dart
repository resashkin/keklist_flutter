import 'package:flutter/material.dart';

final class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    required this.isPlaying,
    required this.hasError,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool hasError;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: hasError ? null : onPressed,
      iconSize: 36,
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.primary,
      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
    );
  }
}
