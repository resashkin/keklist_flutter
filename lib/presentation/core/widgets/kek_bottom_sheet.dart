import 'package:material_ui/material_ui.dart';

/// The app's standard bottom-sheet visual style.
///
/// This is the single source of truth for how modal bottom sheets look, derived
/// from the export/import password sheet (`PasswordInputBottomSheet`) which is the
/// etalon. Any bottom sheet should use these helpers so background, corner radius,
/// drag handle and title styling stay consistent.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent, // container paints its own surface
///   builder: (_) => Container(
///     decoration: KekBottomSheetStyle.decoration(context),
///     child: Column(children: [KekBottomSheetStyle.handle(context), ...]),
///   ),
/// );
/// ```
abstract final class KekBottomSheetStyle {
  /// Top corner radius of the sheet container.
  static const double cornerRadius = 16.0;

  /// Sheet background color.
  static Color background(BuildContext context) => Theme.of(context).colorScheme.surface;

  static BorderRadius get topRadius => const BorderRadius.vertical(top: Radius.circular(cornerRadius));

  /// Box decoration for the sheet's outer container (surface + rounded top).
  static BoxDecoration decoration(BuildContext context) => BoxDecoration(
        color: background(context),
        borderRadius: topRadius,
      );

  /// Centered title style: bold [TextTheme.titleLarge].
  static TextStyle? titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

  /// The bare 32×4 grab bar (no surrounding spacing) — use inside a custom
  /// draggable wrapper.
  static Widget handleBar(BuildContext context) => Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  /// The standard centered drag handle with the etalon's spacing.
  static Widget handle(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: handleBar(context),
        ),
      );
}
