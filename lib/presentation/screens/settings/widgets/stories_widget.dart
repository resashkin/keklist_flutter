import 'package:flutter/material.dart';

final class Story {
  const Story({
    required this.id,
    required this.title,
    required this.emoji,
  });

  final String id;
  final String title;
  final String emoji;
}

// TODO: implement gradiented border that calculated by title hash or something

final class StoriesWidget extends StatelessWidget {
  const StoriesWidget({
    super.key,
    required this.stories,
  });

  final List<Story> stories;

  static Gradient _borderGradient(String title) {
    final normalized = title.isEmpty ? '-' : title;
    final hash = _stableHash(normalized);
    double hueFrom(int value) => (value % 360).toDouble();
    Color colorFromHue(double hue, double saturation, double value) =>
        HSVColor.fromAHSV(1, hue, saturation.clamp(0.0, 1.0), value.clamp(0.0, 1.0)).toColor();

    final hue1 = hueFrom(hash);
    final hue2 = hueFrom(hash >> 7);
    final hue3 = hueFrom(hash >> 13);

    final color1 = colorFromHue(hue1, 0.72, 0.96);
    final color2 = colorFromHue((hue1 + hue2) % 360, 0.68, 0.9);
    final color3 = colorFromHue(hue3, 0.78, 0.88);

    return SweepGradient(
      center: Alignment.center,
      colors: [color1, color2, color3, color1],
      stops: const [0.0, 0.45, 0.8, 1.0],
    );
  }

  static int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = 0x1fffffff & (hash * 33 + unit);
    }
    return hash == 0 ? 1 : hash;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(180),
      fontWeight: FontWeight.w500,
      fontSize: 10.0,
    );
    final emojiStyle =
        theme.textTheme.titleMedium?.copyWith(fontSize: 26.0) ?? const TextStyle(fontSize: 26.0);
    final itemCount = stories.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(itemCount, (index) {
            final story = stories[index];
            final gradient = _borderGradient(story.title);

            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58.0,
                    height: 58.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: gradient,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface,
                      ),
                      child: Center(
                        child: Text(
                          story.emoji,
                          style: emojiStyle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.title,
                    style: captionStyle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
