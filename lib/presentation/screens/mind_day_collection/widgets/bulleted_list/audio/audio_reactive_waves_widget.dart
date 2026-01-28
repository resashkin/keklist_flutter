import 'package:flutter/material.dart';

final class AudioReactiveWavesWidget extends StatelessWidget {
  final double amplitude; // 0.0 to 1.0
  final String emoji;

  const AudioReactiveWavesWidget({super.key, required this.amplitude, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            AnimatedWaveCircle(
              amplitude: amplitude,
              delay: Duration(milliseconds: i * 150),
              scale: 1.0 + (i * 0.1),
            ),
          // Mind emoji in center
          Text(emoji, style: const TextStyle(fontSize: 120)),
        ],
      ),
    );
  }
}

final class AnimatedWaveCircle extends StatefulWidget {
  final double amplitude;
  final Duration delay;
  final double scale;

  const AnimatedWaveCircle({super.key, required this.amplitude, required this.delay, required this.scale});

  @override
  State<AnimatedWaveCircle> createState() => _AnimatedWaveCircleState();
}

final class _AnimatedWaveCircleState extends State<AnimatedWaveCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat();

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double baseRadius = 70.0 * widget.scale;
        final double amplitudeBoost = widget.amplitude * 10.0;
        final double radius = baseRadius + amplitudeBoost;

        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(32), width: 1.5),
          ),
        );
      },
    );
  }
}
