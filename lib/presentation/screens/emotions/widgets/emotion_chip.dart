import 'package:flutter/material.dart';

/// A pill chip that renders one or more emojis followed by a label. Emojis are
/// laid out inline as plain text (no circular avatar), which avoids the clipping
/// that `FilterChip.avatar` caused for wide emojis. Shows a chevron to hint that
/// long-press drills into children, and a count badge when the chip's subtree
/// holds selected emotions.
final class EmotionChip extends StatelessWidget {
  final List<String> emojis;
  final String label;
  final bool selected;
  final bool hasChildren;

  /// Number of this chip's descendants that are currently selected. When > 0 and
  /// the chip itself isn't [selected], a count badge is shown to signal that a
  /// selection lives deeper in its subtree.
  final int selectedDescendantCount;

  /// Adopts the reflection-comment bubble's palette, for chips rendered inside a
  /// Mind card so both content types read as one surface. See ADR-0002.
  final bool useCommentPalette;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// When provided, the children chevron becomes its own tap target (used in edit
  /// mode so tapping the chevron drills in while tapping the body renames).
  final VoidCallback? onChevronTap;

  const EmotionChip({
    super.key,
    required this.emojis,
    required this.label,
    this.selected = false,
    this.hasChildren = false,
    this.selectedDescendantCount = 0,
    this.useCommentPalette = false,
    this.onTap,
    this.onLongPress,
    this.onChevronTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color background = useCommentPalette
        ? scheme.primaryContainer
        : (selected ? scheme.secondaryContainer : scheme.surfaceContainerHighest);
    final Color foreground = useCommentPalette
        ? scheme.onPrimaryContainer
        : (selected ? scheme.onSecondaryContainer : scheme.onSurface);

    // Constant border width across states so the chip never resizes when toggled.
    // The accent border is reserved for a *directly* selected chip; the count
    // badge shows whenever the subtree holds selections, even if the chip itself
    // is also selected.
    final Color borderColor = useCommentPalette
        ? scheme.primary
        : (selected ? scheme.secondary : scheme.outlineVariant);
    final bool showBadge = selectedDescendantCount > 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emojis.join(' '), style: const TextStyle(fontSize: 16.0, height: 1.2)),
            const SizedBox(width: 6.0),
            Text(label, style: TextStyle(color: foreground, fontSize: 14.0)),
            if (hasChildren) ...[
              const SizedBox(width: 4.0),
              GestureDetector(
                onTap: onChevronTap,
                child: Icon(
                  Icons.chevron_right,
                  size: 18.0,
                  color: onChevronTap != null ? scheme.primary : foreground.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (showBadge) ...[
              const SizedBox(width: 4.0),
              _CountBadge(count: selectedDescendantCount),
            ],
          ],
        ),
      ),
    );
  }
}

/// Messenger-style "add a reaction" affordance: a compact outlined pill sized to
/// sit beside [EmotionChip]s. Uses the smiley-with-plus glyph so the control
/// reads as "add a feeling" rather than a generic add button. See ADR-0004.
final class EmotionAddChip extends StatelessWidget {
  final VoidCallback? onTap;

  const EmotionAddChip({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
        ),
        child: Icon(Icons.add_reaction_outlined, size: 20.0, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 16.0),
      height: 16.0,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        '$count',
        style: TextStyle(color: scheme.onSecondary, fontSize: 11.0, fontWeight: FontWeight.w600, height: 1.0),
      ),
    );
  }
}
