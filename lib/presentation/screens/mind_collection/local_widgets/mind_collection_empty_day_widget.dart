import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/widgets/mind_widget.dart';

final class MindCollectionEmptyDayWidget extends StatelessWidget {
  final String emoji;
  final String text;

  const MindCollectionEmptyDayWidget({
    super.key,
    required this.emoji,
    required this.text,
  });

  factory MindCollectionEmptyDayWidget.noMinds({String? text}) {
    return MindCollectionEmptyDayWidget(
      emoji: '😔',
      text: text ?? 'No minds',
    );
  }

  factory MindCollectionEmptyDayWidget.noInsights({String? text}) {
    return MindCollectionEmptyDayWidget(
      emoji: '😔',
      text: text ?? 'You did not collect any entries yet',
    );
  }

  static const ColorFilter greyscale = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 16.0),
        ColorFiltered(
          colorFilter: greyscale,
          child: MindWidget.sized(
            item: emoji,
            size: MindSize.medium,
            isHighlighted: false,
            badge: null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
