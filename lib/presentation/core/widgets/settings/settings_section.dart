import 'package:material_ui/material_ui.dart';

const double _kSettingsMaxWidth = 700.0;

/// A settings screen body: a width-constrained, centered scrolling list.
///
/// Replaces `settings_ui`'s `SettingsList` — pass section headers and
/// [SettingsSectionCard]s as [children].
final class SettingsListView extends StatelessWidget {
  const SettingsListView({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kSettingsMaxWidth),
        child: ListView(
          padding: EdgeInsets.only(top: 8.0, bottom: MediaQuery.paddingOf(context).bottom + 16.0),
          children: children,
        ),
      ),
    );
  }
}

/// Grey caption above a section. Renders [title] verbatim (call-sites decide casing).
final class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32.0, 20.0, 32.0, 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}

/// Rounded inset card grouping a section's tiles, with hairline dividers between them.
final class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: ListTileTheme(
            data: const ListTileThemeData(contentPadding: EdgeInsets.only(left: 16.0, right: 8.0)),
            child: Column(children: _withDividers(context, children)),
          ),
        ),
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context, List<Widget> tiles) {
    final Color dividerColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final List<Widget> result = [];
    for (int i = 0; i < tiles.length; i++) {
      result.add(tiles[i]);
      if (i != tiles.length - 1) {
        result.add(Divider(height: 1.0, thickness: 0.5, indent: 16.0, color: dividerColor));
      }
    }
    return result;
  }
}

/// Trailing affordance for a navigation tile: optional grey value text + a chevron.
Widget settingsNavTrailing(BuildContext context, {String? value}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (value != null) ...[
        Text(value, style: TextStyle(color: Theme.of(context).hintColor)),
        const SizedBox(width: 6.0),
      ],
      Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
    ],
  );
}

/// A selectable option for [SettingsMenuTile].
final class SettingsMenuOption<T> {
  const SettingsMenuOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A settings tile that opens an iOS-style pull-down menu (UIMenu analog) to pick a value.
///
/// Shows the current selection's label + a pull-down glyph; tapping opens a
/// [MenuAnchor] listing [options] with a checkmark on the active one.
final class SettingsMenuTile<T> extends StatelessWidget {
  const SettingsMenuTile({
    super.key,
    this.leading,
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final Widget? leading;
  final String title;
  final T value;
  final List<SettingsMenuOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final Color hintColor = Theme.of(context).hintColor;
    final SettingsMenuOption<T> current = options.firstWhere((option) => option.value == value);
    return MenuAnchor(
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return ListTile(
          leading: leading,
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(current.label, style: TextStyle(color: hintColor)),
              const SizedBox(width: 6.0),
              Icon(Icons.unfold_more, size: 20.0, color: hintColor),
            ],
          ),
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
        );
      },
      menuChildren: options.map((option) {
        final bool isSelected = option.value == value;
        return MenuItemButton(
          leadingIcon: Icon(Icons.check, size: 20.0, color: isSelected ? null : Colors.transparent),
          onPressed: () => onSelected(option.value),
          child: Text(option.label),
        );
      }).toList(),
    );
  }
}
