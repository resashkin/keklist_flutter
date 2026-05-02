import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:keklist/domain/constants.dart';

final class PreparationScreen extends StatelessWidget {
  final ValueNotifier<String> stepNotifier;

  const PreparationScreen({super.key, required this.stepNotifier});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Themes.dark,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: stepNotifier,
                builder: (context, step, _) => Text(
                  step,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ).animate(key: ValueKey(step)).fadeIn(duration: 300.ms),
              ),
              const SizedBox(height: 20),
              _AnimatedDots(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(delay: (i * 200).ms, duration: 400.ms),
        );
      }),
    );
  }
}
