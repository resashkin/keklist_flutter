import 'package:flutter/material.dart';
import 'package:keklist/presentation/core/widgets/bool_widget.dart';
import 'package:keklist/presentation/core/widgets/rounded_circle.dart';

enum MindSize {
  superSmall,
  small,
  medium,
  large,
}

final class MindWidget extends StatelessWidget {
  final String item;
  final String? badge;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double fontSize;

  /// Emojis of the emotions tagged on the mind, rendered as a small row at the
  /// bottom of the card. Empty for emoji-only widgets (pickers, suggestions).
  final List<String> emotionEmojis;

  const MindWidget({
    super.key,
    required this.item,
    this.badge,
    this.isHighlighted = true,
    this.onTap,
    this.onLongPress,
    this.fontSize = 50,
    this.emotionEmojis = const [],
  });

  factory MindWidget.justEmoji({
    required String emoji,
    double? size,
  }) {
    return MindWidget(
      item: emoji,
      isHighlighted: true,
      onTap: null,
      onLongPress: null,
      fontSize: size ?? 50,
    );
  }

  factory MindWidget.sized({
    required String item,
    required MindSize size,
    required String? badge,
    bool isHighlighted = true,
    VoidCallback? onTap,
    VoidCallback? onLongTap,
    List<String> emotionEmojis = const [],
  }) {
    final double fontSize = switch (size) {
      MindSize.superSmall => 12,
      MindSize.small => 32,
      MindSize.medium => 40,
      MindSize.large => 50,
    };
    return MindWidget(
      item: item,
      badge: badge,
      isHighlighted: isHighlighted,
      onTap: onTap,
      onLongPress: onLongTap,
      fontSize: fontSize,
      emotionEmojis: emotionEmojis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Center(
            child: GrayedOut(
              grayedOut: !isHighlighted,
              child: Text(item,
                  style: TextStyle(
                    // fontFamily: 'NotoColorEmoji',
                    fontSize: fontSize,
                  )),
            ),
          ),
          BoolWidget(
            condition: badge != null,
            trueChild: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: RoundedCircle(
                  height: 16.0,
                  width: 16.0,
                  backgroundColor: Colors.lightGreen,
                  borderColor: Colors.white,
                  borderWidth: 2.0,
                  child: Container(),
                ),
              ),
            ),
            falseChild: Container(),
          ),
          if (emotionEmojis.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    emotionEmojis.join(),
                    style: TextStyle(fontSize: fontSize * 0.26),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GrayedOut extends StatelessWidget {
  final Widget child;
  final bool grayedOut;

  const GrayedOut({
    super.key,
    required this.child,
    required this.grayedOut,
  });

  @override
  Widget build(BuildContext context) => grayedOut ? Opacity(opacity: 0.25, child: child) : child;
}
