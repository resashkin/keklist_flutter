import 'package:flutter/material.dart';

/// A pill chip that renders one or more emojis followed by a label. Emojis are
/// laid out inline as plain text (no circular avatar), which avoids the clipping
/// that `FilterChip.avatar` caused for wide emojis. Optionally shows a chevron to
/// hint that long-press drills into children.
final class EmotionChip extends StatelessWidget {
  final List<String> emojis;
  final String label;
  final bool selected;
  final bool hasChildren;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EmotionChip({
    super.key,
    required this.emojis,
    required this.label,
    this.selected = false,
    this.hasChildren = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color background = selected ? scheme.secondaryContainer : scheme.surfaceContainerHighest;
    final Color foreground = selected ? scheme.onSecondaryContainer : scheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emojis.join(' '), style: const TextStyle(fontSize: 16.0, height: 1.2)),
            const SizedBox(width: 6.0),
            Text(label, style: TextStyle(color: foreground, fontSize: 14.0)),
            if (hasChildren) ...[
              const SizedBox(width: 4.0),
              Icon(Icons.chevron_right, size: 16.0, color: foreground.withValues(alpha: 0.6)),
            ],
          ],
        ),
      ),
    );
  }
}
